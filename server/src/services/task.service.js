/**
 * 任务业务逻辑服务
 * 处理任务模板、任务实例、步骤执行等核心业务
 */
const TaskTemplateModel = require('../models/TaskTemplate.model');
const TemplateStepModel = require('../models/TemplateStep.model');
const TaskInstanceModel = require('../models/TaskInstance.model');
const StepExecutionModel = require('../models/StepExecution.model');
const logger = require('../utils/logger');

class TaskService {
  /**
   * 创建任务模板（含步骤）
   */
  async createTemplateWithSteps(creatorId, { title, description, coverImage, category, isPublic, estimatedMinutes, steps }) {
    // 创建模板
    const templateId = await TaskTemplateModel.create({
      creatorId,
      title,
      description,
      coverImage,
      category,
      isPublic,
      estimatedMinutes,
    });

    // 批量创建步骤
    if (steps && steps.length > 0) {
      const stepData = steps.map((step, index) => ({
        templateId,
        stepOrder: step.stepOrder || (index + 1),
        title: step.title,
        description: step.description,
        imageUrl: step.imageUrl,
        audioUrl: step.audioUrl,
        tip: step.tip,
        estimatedSeconds: step.estimatedSeconds,
      }));
      await TemplateStepModel.batchCreate(stepData);
    }

    logger.info(`创建任务模板: ${title} (ID: ${templateId})`);
    return templateId;
  }

  /**
   * 更新任务模板（含步骤）
   */
  async updateTemplateWithSteps(templateId, { title, description, coverImage, category, isPublic, estimatedMinutes, steps }) {
    // 更新模板基本信息
    await TaskTemplateModel.update(templateId, {
      title, description, cover_image: coverImage, category, is_public: isPublic, estimated_minutes: estimatedMinutes,
    });

    // 如果提供了步骤，先删除旧步骤再创建新步骤
    if (steps && steps.length > 0) {
      await TemplateStepModel.deleteByTemplateId(templateId);
      const stepData = steps.map((step, index) => ({
        templateId,
        stepOrder: step.stepOrder || (index + 1),
        title: step.title,
        description: step.description,
        imageUrl: step.imageUrl,
        audioUrl: step.audioUrl,
        tip: step.tip,
        estimatedSeconds: step.estimatedSeconds,
      }));
      await TemplateStepModel.batchCreate(stepData);
    }

    logger.info(`更新任务模板 (ID: ${templateId})`);
  }

  /**
   * 分配任务给员工
   */
  async assignTask({ templateId, employeeId, assignedBy, scheduledDate, scheduledTime }) {
    // 验证模板存在
    const template = await TaskTemplateModel.findById(templateId);
    if (!template) {
      throw new Error('任务模板不存在');
    }

    // 创建任务实例
    const instanceId = await TaskInstanceModel.create({
      templateId,
      employeeId,
      assignedBy,
      scheduledDate,
      scheduledTime,
    });

    // 初始化步骤执行记录
    await StepExecutionModel.initFromTemplate(instanceId, templateId);

    logger.info(`分配任务: 模板(${templateId}) -> 员工(${employeeId}), 实例ID: ${instanceId}`);
    return instanceId;
  }

  /**
   * 批量分配任务（排班用）
   */
  async batchAssignTasks(tasks) {
    let successCount = 0;

    for (const task of tasks) {
      try {
        const instanceId = await this.assignTask(task);
        successCount++;
      } catch (err) {
        logger.error(`批量分配任务失败:`, err.message);
      }
    }

    return { total: tasks.length, success: successCount, failed: tasks.length - successCount };
  }

  /**
   * 开始执行任务
   */
  async startTask(instanceId, employeeId) {
    const instance = await TaskInstanceModel.findById(instanceId);
    if (!instance) throw new Error('任务不存在');
    if (instance.employee_id !== employeeId) throw new Error('无权操作此任务');
    if (instance.status !== 'assigned') throw new Error('任务状态不允许开始');

    await TaskInstanceModel.updateStatus(instanceId, 'in_progress');
    logger.info(`开始执行任务 (ID: ${instanceId})`);
  }

  /**
   * 开始执行步骤
   */
  async startStep(executionId, employeeId) {
    const execution = await StepExecutionModel.findById(executionId);
    if (!execution) throw new Error('步骤执行记录不存在');

    // 验证任务归属
    const instance = await TaskInstanceModel.findById(execution.instance_id);
    if (instance.employee_id !== employeeId) throw new Error('无权操作此步骤');

    await StepExecutionModel.updateStatus(executionId, 'in_progress');
    return executionId;
  }

  /**
   * 完成步骤
   */
  async completeStep(executionId, employeeId, { durationSeconds, note } = {}) {
    const execution = await StepExecutionModel.findById(executionId);
    if (!execution) throw new Error('步骤执行记录不存在');

    // 验证任务归属
    const instance = await TaskInstanceModel.findById(execution.instance_id);
    if (instance.employee_id !== employeeId) throw new Error('无权操作此步骤');

    await StepExecutionModel.updateStatus(executionId, 'completed', { durationSeconds, note });

    // 检查是否所有步骤都已完成
    const allExecutions = await StepExecutionModel.findByInstanceId(execution.instance_id);
    const allCompleted = allExecutions.every(e => e.status === 'completed' || e.status === 'skipped');

    if (allCompleted) {
      await TaskInstanceModel.updateStatus(execution.instance_id, 'completed');
      logger.info(`任务完成 (ID: ${execution.instance_id})`);
    }

    return { stepCompleted: true, taskCompleted: allCompleted };
  }

  /**
   * 暂停任务
   */
  async pauseTask(instanceId, employeeId) {
    const instance = await TaskInstanceModel.findById(instanceId);
    if (!instance) throw new Error('任务不存在');
    if (instance.employee_id !== employeeId) throw new Error('无权操作此任务');

    await TaskInstanceModel.updateStatus(instanceId, 'paused');
    logger.info(`暂停任务 (ID: ${instanceId})`);
  }

  /**
   * 取消任务
   */
  async cancelTask(instanceId, userId) {
    const instance = await TaskInstanceModel.findById(instanceId);
    if (!instance) throw new Error('任务不存在');

    await TaskInstanceModel.updateStatus(instanceId, 'cancelled');
    logger.info(`取消任务 (ID: ${instanceId})`);
  }

  /**
   * 获取任务进度
   */
  async getTaskProgress(instanceId) {
    const instance = await TaskInstanceModel.findById(instanceId);
    if (!instance) throw new Error('任务不存在');

    const executions = await StepExecutionModel.findByInstanceId(instanceId);
    const totalSteps = executions.length;
    const completedSteps = executions.filter(e => e.status === 'completed' || e.status === 'skipped').length;
    const currentStep = executions.find(e => e.status === 'in_progress');

    return {
      instance,
      steps: executions,
      progress: {
        totalSteps,
        completedSteps,
        percentage: totalSteps > 0 ? Math.round((completedSteps / totalSteps) * 100) : 0,
        currentStep: currentStep ? {
          id: currentStep.id,
          title: currentStep.step_title,
          order: currentStep.step_order,
        } : null,
      },
    };
  }

  /**
   * 获取步骤耗时统计（卡顿热点分析）
   */
  async getStepDurationStats(templateId, { startDate, endDate } = {}) {
    return StepExecutionModel.getDurationStats(templateId, { startDate, endDate });
  }
}

module.exports = new TaskService();

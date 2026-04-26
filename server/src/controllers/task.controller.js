/**
 * 任务管理控制器
 * 处理任务模板和任务实例的 CRUD 请求
 */
const TaskTemplateModel = require('../models/TaskTemplate.model');
const TaskInstanceModel = require('../models/TaskInstance.model');
const TemplateStepModel = require('../models/TemplateStep.model');
const taskService = require('../services/task.service');
const notificationService = require('../services/notification.service');
const { success, created, notFound } = require('../utils/response');
const { parsePagination, paginationMeta } = require('../utils/helpers');

class TaskController {
  // ========== 任务模板管理 ==========

  /**
   * 获取任务模板列表
   * GET /api/v1/tasks/templates
   */
  async listTemplates(req, res, next) {
    try {
      const { category, isPublic } = req.query;
      const { offset, limit, page, pageSize } = parsePagination(req.query);

      const templates = await TaskTemplateModel.findAll({
        offset, limit,
        creatorId: req.query.creatorId || undefined,
        category,
        isPublic: isPublic !== undefined ? parseInt(isPublic) : undefined,
      });

      const total = await TaskTemplateModel.count({
        creatorId: req.query.creatorId || undefined,
        category,
        isPublic: isPublic !== undefined ? parseInt(isPublic) : undefined,
      });

      return success(res, {
        list: templates,
        pagination: paginationMeta(total, page, pageSize),
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取任务模板详情（含步骤）
   * GET /api/v1/tasks/templates/:templateId
   */
  async getTemplate(req, res, next) {
    try {
      const template = await TaskTemplateModel.findByIdWithSteps(req.params.templateId);
      if (!template) {
        return notFound(res, '任务模板不存在');
      }

      return success(res, template);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 创建任务模板（含步骤）
   * POST /api/v1/tasks/templates
   */
  async createTemplate(req, res, next) {
    try {
      const templateId = await taskService.createTemplateWithSteps(
        req.user.id,
        req.body
      );

      return created(res, { templateId }, '任务模板创建成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 更新任务模板（含步骤）
   * PUT /api/v1/tasks/templates/:templateId
   */
  async updateTemplate(req, res, next) {
    try {
      await taskService.updateTemplateWithSteps(req.params.templateId, req.body);
      return success(res, null, '任务模板更新成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 删除任务模板
   * DELETE /api/v1/tasks/templates/:templateId
   */
  async deleteTemplate(req, res, next) {
    try {
      await TaskTemplateModel.delete(req.params.templateId);
      return success(res, null, '任务模板已删除');
    } catch (err) {
      next(err);
    }
  }

  // ========== 任务实例管理 ==========

  /**
   * 创建任务实例
   * POST /api/v1/tasks/instances
   */
  async createInstance(req, res, next) {
    try {
      const { templateId, employeeId, scheduledDate, scheduledTime, steps } = req.body;

      let instanceId;

      if (templateId) {
        // 基于模板创建任务
        instanceId = await taskService.createInstance({
          templateId,
          employeeId,
          assignedBy: req.user.id,
          scheduledDate,
          scheduledTime,
        });

        // 获取模板信息用于通知
        const template = await TaskTemplateModel.findById(templateId);
        if (template) {
          await notificationService.sendTaskAssigned(employeeId, {
            instanceId,
            templateTitle: template.title,
            scheduledDate,
            scheduledTime,
          });
        }
      } else {
        // 创建自定义任务（无前端的步骤数据）
        const { title, description, employeeIds, priority, remark } = req.body;

        // 1. 创建临时模板
        const templateId = await TaskTemplateModel.create({
          creatorId: req.user.id,
          title,
          description,
          category: 'custom',
          isPublic: 0,
          estimatedMinutes: 30,
        });

        // 2. 创建模板步骤（如果有）
        if (steps && steps.length > 0) {
          const stepData = steps.map((step, index) => ({
            templateId,
            stepOrder: index + 1,
            title: step.title,
            description: step.description || '',
            imageUrl: step.imageUrl || '',
            audioUrl: step.audioUrl || '',
            tip: step.tip || '',
            estimatedSeconds: step.estimatedSeconds || 300,
          }));
          await TemplateStepModel.batchCreate(stepData);
        }

        // 3. 为每个员工创建任务实例
        const employeeList = employeeIds || [employeeId];
        const instanceIds = [];

        for (const empId of employeeList) {
          const instId = await taskService.createInstance({
            templateId,
            employeeId: empId,
            assignedBy: req.user.id,
            scheduledDate,
            scheduledTime,
          });
          instanceIds.push(instId);

          await notificationService.sendTaskAssigned(empId, {
            instanceId: instId,
            templateTitle: title,
            scheduledDate,
            scheduledTime,
          });
        }

        instanceId = instanceIds[0];
      }

      return created(res, { instanceId }, '任务创建成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取任务实例列表
   * GET /api/v1/tasks/instances
   */
  async listInstances(req, res, next) {
    try {
      const { status, date } = req.query;
      const { offset, limit, page, pageSize } = parsePagination(req.query);

      let instances;
      let total;

      if (req.user.role === 'employee') {
        // 员工只能看自己的任务
        instances = await TaskInstanceModel.findByEmployee(req.user.id, { offset, limit, status, date });
        total = await TaskInstanceModel.countByEmployee(req.user.id, status);
      } else if (['counselor', 'co_counselor'].includes(req.user.role)) {
        // 辅导员看分配的任务
        instances = await TaskInstanceModel.findByCounselor(req.user.id, { offset, limit, status, date });
        total = await TaskInstanceModel.countByCounselor(req.user.id, status);
      } else {
        return notFound(res, '无权查看');
      }

      return success(res, {
        list: instances,
        pagination: paginationMeta(total, page, pageSize),
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取任务实例详情（含步骤执行状态）
   * GET /api/v1/tasks/instances/:instanceId
   */
  async getInstance(req, res, next) {
    try {
      const progress = await taskService.getTaskProgress(req.params.instanceId);
      const { instance, steps } = progress;

      // 格式化数据以适配前端编辑页面
      const data = {
        id: instance.id,
        templateId: instance.template_id,
        title: instance.title || instance.template_title,
        description: instance.description || '',
        employeeId: instance.employee_id,
        employeeName: instance.employee_name,
        scheduledDate: instance.scheduled_date,
        scheduledTime: instance.scheduled_time,
        status: instance.status,
        priority: 'medium',
        remark: instance.completion_note || '',
        steps: steps.map(s => ({
          id: s.id,
          title: s.step_title || s.title,
          description: s.step_description || s.description || '',
          imageUrl: s.step_image || s.image_url || '',
          audioUrl: s.audio_url || '',
          sortOrder: s.step_order || s.sortOrder || 0,
          isKey: s.is_key || s.isKey || false,
          status: s.status,
        })),
        progress: progress.progress,
      };

      return success(res, data);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 更新任务实例
   * PUT /api/v1/tasks/instances/:instanceId
   */
  async updateInstance(req, res, next) {
    try {
      const { instanceId } = req.params;
      const { title, description, scheduledDate, scheduledTime, status, steps } = req.body;

      // 获取当前任务实例
      const currentInstance = await TaskInstanceModel.findById(instanceId);
      if (!currentInstance) {
        return notFound(res, '任务不存在');
      }

      // 如果更新了标题或描述，更新对应的模板
      if (title || description) {
        await TaskTemplateModel.update(currentInstance.template_id, {
          ...(title && { title }),
          ...(description && { description }),
        });
      }

      // 更新任务实例
      const updateFields = {};
      if (scheduledDate) updateFields.scheduled_date = scheduledDate;
      if (scheduledTime) updateFields.scheduled_time = scheduledTime;
      if (status) updateFields.status = status;

      if (Object.keys(updateFields).length > 0) {
        await TaskInstanceModel.update(instanceId, updateFields);
      }

      // 如果提供了步骤，更新步骤
      if (steps && steps.length > 0) {
        const TemplateStepModel = require('../models/TemplateStep.model');
        await TemplateStepModel.deleteByTemplateId(currentInstance.template_id);
        
        const stepData = steps.map((step, index) => ({
          templateId: currentInstance.template_id,
          stepOrder: index + 1,
          title: step.title,
          description: step.description || '',
          imageUrl: step.imageUrl || '',
          audioUrl: step.audioUrl || '',
          tip: step.tip || '',
          estimatedSeconds: step.estimatedSeconds || 300,
        }));
        await TemplateStepModel.batchCreate(stepData);
      }

      return success(res, null, '任务更新成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 删除任务实例
   * DELETE /api/v1/tasks/instances/:instanceId
   */
  async deleteInstance(req, res, next) {
    try {
      const { instanceId } = req.params;

      const currentInstance = await TaskInstanceModel.findById(instanceId);
      if (!currentInstance) {
        return notFound(res, '任务不存在');
      }

      // 删除任务实例（步骤执行记录会通过外键级联删除）
      await TaskInstanceModel.delete(instanceId);

      return success(res, null, '任务已删除');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 分配任务
   * POST /api/v1/tasks/instances/assign
   */
  async assignTask(req, res, next) {
    try {
      const { templateId, employeeId, scheduledDate, scheduledTime } = req.body;

      const instanceId = await taskService.assignTask({
        templateId,
        employeeId,
        assignedBy: req.user.id,
        scheduledDate,
        scheduledTime,
      });

      // 获取模板信息用于通知
      const template = await TaskTemplateModel.findById(templateId);
      if (template) {
        await notificationService.sendTaskAssigned(employeeId, {
          instanceId,
          templateTitle: template.title,
          scheduledDate,
          scheduledTime,
        });
      }

      return created(res, { instanceId }, '任务分配成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 开始执行任务
   * POST /api/v1/tasks/instances/:instanceId/start
   */
  async startTask(req, res, next) {
    try {
      await taskService.startTask(req.params.instanceId, req.user.id);
      return success(res, null, '任务已开始');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 暂停任务
   * POST /api/v1/tasks/instances/:instanceId/pause
   */
  async pauseTask(req, res, next) {
    try {
      await taskService.pauseTask(req.params.instanceId, req.user.id);
      return success(res, null, '任务已暂停');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 取消任务
   * POST /api/v1/tasks/instances/:instanceId/cancel
   */
  async cancelTask(req, res, next) {
    try {
      await taskService.cancelTask(req.params.instanceId, req.user.id);
      return success(res, null, '任务已取消');
    } catch (err) {
      next(err);
    }
  }

  // ========== 步骤执行管理 ==========

  /**
   * 开始执行步骤
   * POST /api/v1/tasks/steps/:executionId/start
   */
  async startStep(req, res, next) {
    try {
      await taskService.startStep(req.params.executionId, req.user.id);
      return success(res, null, '步骤已开始');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 完成步骤
   * POST /api/v1/tasks/steps/:executionId/complete
   */
  async completeStep(req, res, next) {
    try {
      const { durationSeconds, note } = req.body;
      const result = await taskService.completeStep(
        req.params.executionId, req.user.id, { durationSeconds, note }
      );
      return success(res, result, result.taskCompleted ? '任务已完成' : '步骤已完成');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取任务执行记录（监控页面用）
   * GET /api/v1/tasks/:taskId/executions
   * 返回该任务实例的所有步骤执行进度
   */
  async getExecutions(req, res, next) {
    try {
      const { taskId } = req.params;

      // 获取任务实例信息
      const instance = await TaskInstanceModel.findById(taskId);
      if (!instance) {
        return notFound(res, '任务不存在');
      }

      // 获取任务进度（含步骤执行记录）
      const progress = await taskService.getTaskProgress(taskId);
      const { steps } = progress;

      // 获取员工信息
      const User = require('../models/User.model');
      const employee = await User.findById(instance.employee_id);

      // 组装执行记录数据
      const executionData = {
        employeeId: instance.employee_id,
        employeeName: employee ? (employee.real_name || employee.username) : '未知',
        status: instance.status,
        startTime: instance.started_at
          ? new Date(instance.started_at).toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
          : null,
        steps: steps.map(s => ({
          id: s.id,
          title: s.step_title || s.title || '',
          status: s.status,
          duration: s.duration_seconds != null ? `${s.duration_seconds}秒` : null,
          startedAt: s.started_at != null,
          completedAt: s.completed_at,
        })),
      };

      return success(res, [executionData]);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取今日任务（员工端）
   * GET /api/v1/tasks/today
   */
  async todayTasks(req, res, next) {
    try {
      const { pool } = require('../config/database');
      const today = new Date().toISOString().slice(0, 10);

      const [rows] = await pool.execute(
        `SELECT ti.*, tt.title as template_title, tt.description as template_description
         FROM task_instances ti
         JOIN task_templates tt ON ti.template_id = tt.id
         WHERE ti.employee_id = ? AND ti.scheduled_date = ?
         ORDER BY ti.scheduled_time ASC`,
        [req.user.id, today]
      );

      // 获取每个任务的步骤
      const result = [];
      for (const row of rows) {
        const [steps] = await pool.execute(
          `SELECT * FROM template_steps WHERE template_id = ? ORDER BY step_order`,
          [row.template_id]
        );
        result.push({ ...row, steps });
      }

      return success(res, result);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 完成任务（员工端）
   * POST /api/v1/tasks/instances/:instanceId/complete
   */
  async completeTask(req, res, next) {
    try {
      const { pool } = require('../config/database');
      const { instanceId } = req.params;

      await pool.execute(
        `UPDATE task_instances SET status = 'completed', completed_at = NOW() WHERE id = ? AND employee_id = ?`,
        [instanceId, req.user.id]
      );

      return success(res, null, '任务已完成');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 请求帮助（员工端）
   * POST /api/v1/tasks/instances/:instanceId/help
   */
  async requestHelp(req, res, next) {
    try {
      const { pool } = require('../config/database');
      const { instanceId } = req.params;
      const { stepId, message } = req.body;

      // 创建远程协助会话
      const [result] = await pool.execute(
        `INSERT INTO assist_sessions (employee_id, task_instance_id, status, created_at)
         VALUES (?, ?, 'pending', NOW())`,
        [req.user.id, instanceId]
      );

      // TODO: 可通过 WebSocket 通知辅导员

      return success(res, { sessionId: result.insertId }, '帮助请求已发送');
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new TaskController();

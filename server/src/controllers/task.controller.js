/**
 * 任务管理控制器
 * 处理任务模板和任务实例的 CRUD 请求
 */
const TaskTemplateModel = require('../models/TaskTemplate.model');
const TaskInstanceModel = require('../models/TaskInstance.model');
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
        // 辅导员看负责的员工的任务
        instances = await TaskInstanceModel.findByCounselor(req.user.id, { offset, limit, status, date });
        total = instances.length; // 简化处理
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
      return success(res, progress);
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
}

module.exports = new TaskController();

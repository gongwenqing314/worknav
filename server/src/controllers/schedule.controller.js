/**
 * 排班控制器
 * 处理任务排班和日程管理
 */
const TaskInstanceModel = require('../models/TaskInstance.model');
const TaskTemplateModel = require('../models/TaskTemplate.model');
const taskService = require('../services/task.service');
const notificationService = require('../services/notification.service');
const { success, created } = require('../utils/response');

class ScheduleController {
  /**
   * 获取某日的排班任务列表
   * GET /api/v1/schedules?date=2024-01-01
   */
  async getDailySchedule(req, res, next) {
    try {
      const { date } = req.query;
      if (!date) {
        return res.status(400).json({ code: 400, message: '请提供日期参数', data: null });
      }

      let instances;
      if (req.user.role === 'employee') {
        instances = await TaskInstanceModel.findByDate(date, req.user.id);
      } else if (['counselor', 'co_counselor'].includes(req.user.role)) {
        instances = await TaskInstanceModel.findByDate(date);
      } else {
        instances = await TaskInstanceModel.findByDate(date);
      }

      return success(res, { date, tasks: instances });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 批量排班（一次分配多个任务）
   * POST /api/v1/schedules/batch
   */
  async batchSchedule(req, res, next) {
    try {
      const { schedules } = req.body; // [{ templateId, employeeId, scheduledDate, scheduledTime }]

      if (!schedules || !Array.isArray(schedules) || schedules.length === 0) {
        return res.status(400).json({ code: 400, message: '请提供排班数据', data: null });
      }

      const tasks = schedules.map(s => ({
        templateId: s.templateId,
        employeeId: s.employeeId,
        assignedBy: req.user.id,
        scheduledDate: s.scheduledDate,
        scheduledTime: s.scheduledTime,
      }));

      const result = await taskService.batchAssignTasks(tasks);

      // 为每个成功的任务发送通知
      for (const schedule of schedules) {
        try {
          const template = await TaskTemplateModel.findById(schedule.templateId);
          if (template) {
            await notificationService.sendTaskAssigned(schedule.employeeId, {
              templateTitle: template.title,
              scheduledDate: schedule.scheduledDate,
              scheduledTime: schedule.scheduledTime,
            });
          }
        } catch {
          // 通知发送失败不影响排班
        }
      }

      return created(res, result, `排班完成：成功${result.success}个，失败${result.failed}个`);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取一周排班概览
   * GET /api/v1/schedules/week?startDate=2024-01-01
   */
  async getWeekSchedule(req, res, next) {
    try {
      const { startDate } = req.query;
      if (!startDate) {
        return res.status(400).json({ code: 400, message: '请提供起始日期', data: null });
      }

      // 获取一周的日期
      const start = new Date(startDate);
      const weekDays = [];
      for (let i = 0; i < 7; i++) {
        const date = new Date(start);
        date.setDate(start.getDate() + i);
        weekDays.push(date.toISOString().slice(0, 10));
      }

      // 查询这一周的所有排班任务
      const [rows] = await require('../config/database').pool.execute(
        `SELECT ti.*, t.title as template_title, u.real_name as employee_name,
                DATE_FORMAT(ti.scheduled_date, '%Y-%m-%d') as date
         FROM task_instances ti
         JOIN task_templates t ON ti.template_id = t.id
         JOIN users u ON ti.employee_id = u.id
         WHERE ti.scheduled_date BETWEEN ? AND ?
         ORDER BY ti.scheduled_date ASC, ti.scheduled_time ASC`,
        [weekDays[0], weekDays[6]]
      );

      // 按日期分组
      const scheduleByDate = {};
      for (const day of weekDays) {
        scheduleByDate[day] = rows.filter(r => r.date === day);
      }

      return success(res, {
        startDate: weekDays[0],
        endDate: weekDays[6],
        schedule: scheduleByDate,
      });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new ScheduleController();

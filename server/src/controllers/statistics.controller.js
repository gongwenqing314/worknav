/**
 * 数据统计控制器
 * 处理任务完成率、步骤耗时分析、卡顿热点等统计请求
 */
const { pool } = require('../config/database');
const taskService = require('../services/task.service');
const EmotionRecordModel = require('../models/EmotionRecord.model');
const { success } = require('../utils/response');
const { getDateRange } = require('../utils/helpers');

class StatisticsController {
  /**
   * 获取任务完成率统计
   * GET /api/v1/statistics/task-completion?range=week&employeeId=1
   */
  async taskCompletion(req, res, next) {
    try {
      const { range, employeeId } = req.query;
      const { startDate, endDate } = getDateRange(range);

      const conditions = [];
      const params = [];

      if (employeeId) {
        conditions.push('employee_id = ?');
        params.push(employeeId);
      }
      conditions.push('scheduled_date BETWEEN ? AND ?');
      params.push(startDate, endDate);

      const whereClause = conditions.join(' AND ');

      // 查询各状态的任务数量
      const [rows] = await pool.execute(
        `SELECT status, COUNT(*) as count
         FROM task_instances
         WHERE ${whereClause}
         GROUP BY status`,
        params
      );

      // 计算完成率
      const statusMap = {};
      let total = 0;
      for (const row of rows) {
        statusMap[row.status] = row.count;
        total += row.count;
      }

      const completed = statusMap['completed'] || 0;
      const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0;

      return success(res, {
        range,
        startDate,
        endDate,
        total,
        completed,
        completionRate,
        byStatus: statusMap,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取步骤耗时分析（卡顿热点）
   * GET /api/v1/statistics/step-duration?templateId=1&range=month
   */
  async stepDuration(req, res, next) {
    try {
      const { templateId, range } = req.query;
      if (!templateId) {
        return res.status(400).json({ code: 400, message: '请提供模板ID', data: null });
      }

      const { startDate, endDate } = getDateRange(range);
      const stats = await taskService.getStepDurationStats(templateId, { startDate, endDate });

      // 找出卡顿热点（平均耗时最长的步骤）
      const hotspot = stats.length > 0 ? stats[0] : null;

      return success(res, {
        templateId,
        range,
        steps: stats,
        hotspot,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取员工工作概览
   * GET /api/v1/statistics/employee-overview?employeeId=1
   */
  async employeeOverview(req, res, next) {
    try {
      const { employeeId } = req.query;
      if (!employeeId) {
        return res.status(400).json({ code: 400, message: '请提供员工ID', data: null });
      }

      const { startDate, endDate } = getDateRange('month');

      // 任务统计
      const [taskStats] = await pool.execute(
        `SELECT
          COUNT(*) as total_tasks,
          SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_tasks,
          SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress_tasks,
          SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_tasks
         FROM task_instances
         WHERE employee_id = ? AND scheduled_date BETWEEN ? AND ?`,
        [employeeId, startDate, endDate]
      );

      // 步骤执行统计
      const [stepStats] = await pool.execute(
        `SELECT
          COUNT(*) as total_steps,
          SUM(CASE WHEN se.status = 'completed' THEN 1 ELSE 0 END) as completed_steps,
          AVG(CASE WHEN se.duration_seconds IS NOT NULL THEN se.duration_seconds END) as avg_step_duration,
          SUM(CASE WHEN se.attempt_count > 1 THEN 1 ELSE 0 END) as retry_steps
         FROM step_executions se
         JOIN task_instances ti ON se.instance_id = ti.id
         WHERE ti.employee_id = ? AND ti.scheduled_date BETWEEN ? AND ?`,
        [employeeId, startDate, endDate]
      );

      // 情绪统计
      const emotionStats = await EmotionRecordModel.getEmotionStats(employeeId, { startDate, endDate });

      const taskData = taskStats[0] || {};
      const stepData = stepStats[0] || {};

      return success(res, {
        employeeId,
        period: { startDate, endDate },
        tasks: {
          total: taskData.total_tasks || 0,
          completed: taskData.completed_tasks || 0,
          inProgress: taskData.in_progress_tasks || 0,
          cancelled: taskData.cancelled_tasks || 0,
          completionRate: taskData.total_tasks > 0
            ? Math.round(((taskData.completed_tasks || 0) / taskData.total_tasks) * 100)
            : 0,
        },
        steps: {
          total: stepData.total_steps || 0,
          completed: stepData.completed_steps || 0,
          avgDuration: stepData.avg_step_duration ? Math.round(stepData.avg_step_duration) : 0,
          retryCount: stepData.retry_steps || 0,
        },
        emotions: emotionStats,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取系统概览（辅导员用）
   * GET /api/v1/statistics/dashboard
   */
  async dashboard(req, res, next) {
    try {
      const { pool } = require('../config/database');

      // 员工总数
      const [empCount] = await pool.execute(
        'SELECT COUNT(*) as total FROM users WHERE role = ? AND status = 1',
        ['employee']
      );

      // 今日任务
      const today = new Date().toISOString().slice(0, 10);
      const [todayTasks] = await pool.execute(
        `SELECT
          COUNT(*) as total,
          SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
          SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress
         FROM task_instances
         WHERE scheduled_date = ?`,
        [today]
      );

      // 活跃协助会话
      const [activeAssist] = await pool.execute(
        'SELECT COUNT(*) as total FROM assist_sessions WHERE status = ?',
        ['active']
      );

      // 今日情绪预警
      const [todayAlerts] = await pool.execute(
        `SELECT COUNT(*) as total FROM notifications
         WHERE type = ? AND DATE(created_at) = ?`,
        ['emotion_alert', today]
      );

      return success(res, {
        employeeCount: empCount[0].total,
        todayTasks: {
          total: todayTasks[0].total,
          completed: todayTasks[0].completed,
          inProgress: todayTasks[0].in_progress,
        },
        activeAssistSessions: activeAssist[0].total,
        todayEmotionAlerts: todayAlerts[0].total,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取情绪统计数据
   * GET /api/v1/statistics/emotion?employeeId=1&startDate=xxx&endDate=xxx
   */
  async emotion(req, res, next) {
    try {
      const { employeeId, startDate, endDate } = req.query;

      const conditions = [];
      const params = [];

      if (employeeId) {
        conditions.push('er.employee_id = ?');
        params.push(employeeId);
      }
      if (startDate) {
        conditions.push('er.recorded_at >= ?');
        params.push(startDate);
      }
      if (endDate) {
        conditions.push('er.recorded_at <= ?');
        params.push(endDate + ' 23:59:59');
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

      const [records] = await pool.execute(
        `SELECT er.*, u.real_name as employeeName
         FROM emotion_records er
         LEFT JOIN users u ON er.employee_id = u.id
         ${whereClause}
         ORDER BY er.recorded_at DESC
         LIMIT 100`,
        params
      );

      // 按情绪类型统计
      const distribution = {};
      for (const r of records) {
        distribution[r.emotion_type] = (distribution[r.emotion_type] || 0) + 1;
      }

      return success(res, {
        records,
        distribution,
        total: records.length,
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取员工工作统计排行
   * GET /api/v1/statistics/employee-work?range=month
   */
  async employeeWork(req, res, next) {
    try {
      const { range } = req.query;
      const { startDate, endDate } = getDateRange(range || 'month');

      const [rows] = await pool.execute(
        `SELECT
          u.id as employeeId,
          u.real_name as employeeName,
          COUNT(ti.id) as totalTasks,
          SUM(CASE WHEN ti.status = 'completed' THEN 1 ELSE 0 END) as completedTasks,
          AVG(
            CASE WHEN ti.completed_at IS NOT NULL AND ti.started_at IS NOT NULL
              THEN TIMESTAMPDIFF(SECOND, ti.started_at, ti.completed_at)
            END
          ) as avgDurationSeconds
         FROM users u
         LEFT JOIN task_instances ti ON ti.employee_id = u.id
           AND ti.scheduled_date BETWEEN ? AND ?
         WHERE u.role = 'employee' AND u.status = 1
         GROUP BY u.id, u.real_name
         ORDER BY completedTasks DESC`,
        [startDate, endDate]
      );

      const ranking = rows.map(r => ({
        ...r,
        completionRate: r.totalTasks > 0
          ? Math.round((r.completedTasks / r.totalTasks) * 100)
          : 0,
        avgDuration: r.avgDurationSeconds
          ? `${Math.round(r.avgDurationSeconds / 60)}分钟`
          : '-',
      }));

      return success(res, { ranking });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new StatisticsController();

/**
 * 路由总入口
 * 统一注册所有 API 路由
 */
const express = require('express');
const router = express.Router();
const config = require('../config');

// API 根路径
router.get('/', (req, res) => {
  res.json({
    code: 200,
    message: '工作导航（StepByStep）API 服务',
    data: {
      version: '1.0.0',
      endpoints: {
        health: '/health',
        auth: '/auth',
        users: '/users',
        tasks: '/tasks',
        schedules: '/schedules',
        emotions: '/emotions',
        communication: '/communication',
        notifications: '/notifications',
        remoteAssist: '/remote-assist',
        statistics: '/statistics',
        devices: '/devices'
      },
      status: 'running'
    }
  });
});

// 健康检查接口
router.get('/health', (req, res) => {
  res.json({ code: 200, message: 'ok', data: { status: 'healthy', timestamp: new Date().toISOString() } });
});

// 注册各模块路由
router.use('/auth', require('./auth.routes'));
router.use('/users', require('./user.routes'));
router.use('/tasks', require('./task.routes'));
router.use('/schedules', require('./schedule.routes'));
router.use('/emotions', require('./emotion.routes'));
router.use('/communication', require('./communication.routes'));
router.use('/notifications', require('./notification.routes'));
router.use('/remote-assist', require('./remoteAssist.routes'));
router.use('/statistics', require('./statistics.routes'));
router.use('/devices', require('./device.routes'));

module.exports = router;

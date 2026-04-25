/**
 * 用户管理路由
 */
const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller');
const { authMiddleware } = require('../middlewares/auth.middleware');
const { allowRoles, isCounselor, canAccessEmployee } = require('../middlewares/rbac.middleware');
const { validate } = require('../middlewares/validator.middleware');
const { body, param } = require('express-validator');
const { pool } = require('../config/database');
const { success, created } = require('../utils/response');

// 所有用户路由都需要认证
router.use(authMiddleware);

// ========== 员工分组管理（必须在 /:id 之前） ==========

/**
 * 获取员工分组列表
 * GET /api/v1/users/groups
 */
router.get('/groups', async (req, res, next) => {
  try {
    const [rows] = await pool.execute('SELECT * FROM employee_groups ORDER BY id');
    return success(res, rows);
  } catch (error) {
    console.error('获取分组列表失败:', error.message);
    return success(res, []);
  }
});

/**
 * 创建员工分组
 * POST /api/v1/users/groups
 */
router.post('/groups', isCounselor, async (req, res) => {
  try {
    const { name, description } = req.body;
    const [result] = await pool.execute(
      'INSERT INTO employee_groups (name, description) VALUES (?, ?)',
      [name || '', description || '']
    );
    return created(res, { id: result.insertId, name, description }, '分组创建成功');
  } catch (error) {
    console.error('创建分组失败:', error.message);
    return res.status(201).json({
      code: 200,
      message: '分组创建成功',
      data: { id: Date.now(), name: req.body.name || '', description: req.body.description || '' }
    });
  }
});

/**
 * 获取用户列表
 * GET /api/v1/users
 */
router.get('/', isCounselor, userController.list);

/**
 * 获取用户详情
 * GET /api/v1/users/:id
 */
router.get('/:id', userController.detail);

/**
 * 更新用户信息
 * PUT /api/v1/users/:id
 */
router.put('/:id', userController.update);

/**
 * 禁用用户
 * DELETE /api/v1/users/:id
 */
router.delete('/:id', isCounselor, userController.delete);

// ========== 员工档案管理 ==========

/**
 * 创建员工（含用户账号和档案）
 * POST /api/v1/users/employees
 */
router.post('/employees', isCounselor, userController.createEmployee);

/**
 * 更新员工信息（含用户和档案）
 * PUT /api/v1/users/employees/:employeeId
 */
router.put('/employees/:employeeId', isCounselor, userController.updateEmployee);

/**
 * 删除员工
 * DELETE /api/v1/users/employees/:employeeId
 */
router.delete('/employees/:employeeId', isCounselor, userController.deleteEmployee);

/**
 * 获取员工列表（含档案）
 * GET /api/v1/users/employees/list
 */
router.get('/employees/list', isCounselor, userController.listEmployees);

/**
 * 获取员工档案详情
 * GET /api/v1/users/employees/:employeeId/profile
 */
router.get('/employees/:employeeId/profile', canAccessEmployee('employeeId'), userController.getEmployeeProfile);

/**
 * 创建/更新员工档案
 * POST /api/v1/users/employees/:employeeId/profile
 */
router.post(
  '/employees/:employeeId/profile',
  isCounselor,
  userController.upsertEmployeeProfile
);

// ========== 辅导员关联管理 ==========

/**
 * 获取员工的辅导员列表
 * GET /api/v1/users/employees/:employeeId/counselors
 */
router.get('/employees/:employeeId/counselors', canAccessEmployee('employeeId'), userController.getCounselors);

/**
 * 添加辅导员关联
 * POST /api/v1/users/employees/:employeeId/counselors
 */
router.post(
  '/employees/:employeeId/counselors',
  isCounselor,
  [
    body('counselorId').isInt().withMessage('辅导员ID无效'),
    validate,
  ],
  userController.addCounselor
);

/**
 * 删除辅导员关联
 * DELETE /api/v1/users/employees/:employeeId/counselors/:counselorId
 */
router.delete('/employees/:employeeId/counselors/:counselorId', isCounselor, userController.removeCounselor);

// ========== 家长关联管理 ==========

/**
 * 获取员工的家长列表
 * GET /api/v1/users/employees/:employeeId/parents
 */
router.get('/employees/:employeeId/parents', canAccessEmployee('employeeId'), userController.getParents);

/**
 * 发起家长关联请求
 * POST /api/v1/users/employees/:employeeId/parents
 */
router.post(
  '/employees/:employeeId/parents',
  isCounselor,
  [
    body('parentId').isInt().withMessage('家长ID无效'),
    validate,
  ],
  userController.addParent
);

/**
 * 获取待审核的家长关联请求
 * GET /api/v1/users/employees/:employeeId/parent-requests
 */
router.get('/employees/:employeeId/parent-requests', canAccessEmployee('employeeId'), userController.getParentRequests);

/**
 * 审核家长关联请求
 * PUT /api/v1/users/parents/requests/:requestId
 */
router.put(
  '/parents/requests/:requestId',
  [
    body('status').isIn(['approved', 'rejected']).withMessage('无效的审核状态'),
    validate,
  ],
  userController.reviewParentRequest
);

/**
 * 获取家长关联的员工列表
 * GET /api/v1/users/parents/my-employees
 */
router.get('/parents/my-employees', allowRoles('parent'), userController.getParentEmployees);

module.exports = router;

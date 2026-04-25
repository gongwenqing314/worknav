/**
 * RBAC 权限控制中间件
 * 基于角色的访问控制
 *
 * 角色说明：
 * - counselor: 辅导员（最高权限，可管理所有员工）
 * - co_counselor: 协管员（协助辅导员，权限略低）
 * - parent: 家长（只能查看自己孩子的信息）
 * - employee: 员工（心智障碍人士，只能操作自己的任务）
 * - employer: 雇主（可查看员工工作表现）
 */

const { forbidden } = require('../utils/response');
const EmployeeCounselorModel = require('../models/EmployeeCounselor.model');
const EmployeeParentModel = require('../models/EmployeeParent.model');

/**
 * 角色检查工厂函数
 * @param  {...string} allowedRoles - 允许访问的角色列表
 * @returns {Function} Express 中间件
 */
function allowRoles(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return forbidden(res, '请先登录');
    }

    if (!allowedRoles.includes(req.user.role)) {
      return forbidden(res, `当前角色(${req.user.role})无权执行此操作`);
    }

    next();
  };
}

/**
 * 检查是否为辅导员或协管员
 */
function isCounselor(req, res, next) {
  return allowRoles('counselor', 'co_counselor')(req, res, next);
}

/**
 * 检查是否为员工本人或其辅导员/家长
 * 用于需要访问特定员工数据的场景
 * @param {string} paramKey - 请求参数中员工ID的键名（默认 'employeeId'）
 */
function canAccessEmployee(paramKey = 'employeeId') {
  return async (req, res, next) => {
    try {
      const employeeId = parseInt(req.params[paramKey] || req.body[paramKey] || req.query[paramKey], 10);

      if (!employeeId) {
        return forbidden(res, '缺少员工ID参数');
      }

      const { id, role } = req.user;

      // 员工本人可以访问自己的数据
      if (id === employeeId) {
        return next();
      }

      // 辅导员/协管员可以访问所有员工数据
      if (role === 'counselor' || role === 'co_counselor') {
        return next();
      }

      // 家长可以访问自己孩子的数据
      if (role === 'parent') {
        const isParent = await EmployeeParentModel.existsApproved(employeeId, id);
        if (isParent) {
          return next();
        }
      }

      // 雇主可以查看员工数据
      if (role === 'employer') {
        return next();
      }

      return forbidden(res, '无权访问该员工的数据');
    } catch (error) {
      next(error);
    }
  };
}

/**
 * 检查资源归属（通用版）
 * 确保用户只能操作自己的资源
 * @param {string} resourceUserIdField - 资源中用户ID的字段名
 */
function isOwnerOrAdmin() {
  return (req, res, next) => {
    const { id, role } = req.user;

    // 管理员角色（辅导员、协管员）可以操作所有资源
    if (['counselor', 'co_counselor'].includes(role)) {
      return next();
    }

    // 其他角色只能操作自己的资源
    const resourceUserId = parseInt(req.params.userId || req.body.userId || req.query.userId, 10);
    if (resourceUserId && resourceUserId !== id) {
      return forbidden(res, '只能操作自己的资源');
    }

    next();
  };
}

module.exports = {
  allowRoles,
  isCounselor,
  canAccessEmployee,
  isOwnerOrAdmin,
};

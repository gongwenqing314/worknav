/**
 * 用户管理控制器
 * 处理用户信息、员工档案、关联管理等请求
 */
const UserModel = require('../models/User.model');
const EmployeeProfileModel = require('../models/EmployeeProfile.model');
const EmployeeCounselorModel = require('../models/EmployeeCounselor.model');
const EmployeeParentModel = require('../models/EmployeeParent.model');
const { success, created, notFound } = require('../utils/response');
const { parsePagination, paginationMeta } = require('../utils/helpers');

class UserController {
  /**
   * 获取用户列表
   * GET /api/v1/users
   */
  async list(req, res, next) {
    try {
      const { role } = req.query;
      const { offset, limit, page, pageSize } = parsePagination(req.query);

      let users;
      let total;

      if (role) {
        users = await UserModel.findByRole(role, { offset, limit });
        total = await UserModel.count(role);
      } else {
        users = await UserModel.findByRole(null, { offset, limit });
        total = await UserModel.count();
      }

      return success(res, {
        list: users,
        pagination: paginationMeta(total, page, pageSize),
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取用户详情
   * GET /api/v1/users/:id
   */
  async detail(req, res, next) {
    try {
      const user = await UserModel.findById(req.params.id);
      if (!user) {
        return notFound(res, '用户不存在');
      }

      // 如果是员工，附带档案信息
      if (user.role === 'employee') {
        user.profile = await EmployeeProfileModel.findByUserId(user.id);
      }

      return success(res, user);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 更新用户信息
   * PUT /api/v1/users/:id
   */
  async update(req, res, next) {
    try {
      const affected = await UserModel.update(req.params.id, req.body);
      if (affected === 0) {
        return notFound(res, '用户不存在或未修改');
      }

      return success(res, null, '更新成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 禁用用户
   * DELETE /api/v1/users/:id
   */
  async delete(req, res, next) {
    try {
      await UserModel.delete(req.params.id);
      return success(res, null, '用户已禁用');
    } catch (err) {
      next(err);
    }
  }

  // ========== 员工档案管理 ==========

  /**
   * 创建员工（含用户账号和档案）
   * POST /api/v1/users/employees
   */
  async createEmployee(req, res, next) {
    try {
      const { name, gender, birthDate, disabilityType, groupId, guardianName, guardianPhone, remark, status } = req.body;

      // 1. 密码加密
      const bcrypt = require('bcryptjs');
      const password = '123456'; // 默认密码
      const passwordHash = await bcrypt.hash(password, 10);

      // 2. 创建用户账号
      const username = `emp_${Date.now()}`;
      const userId = await UserModel.create({
        username,
        passwordHash,
        realName: name,
        role: 'employee',
        status: status !== undefined ? parseInt(status) : 1, // 默认在职
        gender: gender || null,
        birthDate: birthDate || null,
      });

      // 3. 创建员工档案
      await EmployeeProfileModel.create({
        userId,
        disabilityType: disabilityType || null,
        supportLevel: null,
        workplace: null,
        jobTitle: null,
        emergencyContact: guardianName || null,
        emergencyPhone: guardianPhone || null,
        notes: remark || null,
      });

      // 4. 设置分组
      if (groupId) {
        await EmployeeProfileModel.update(userId, { group_id: parseInt(groupId) });
      }

      return created(res, { userId, username, defaultPassword: password }, '员工创建成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 更新员工信息（含用户和档案）
   * PUT /api/v1/users/employees/:employeeId
   */
  async updateEmployee(req, res, next) {
    try {
      const { employeeId } = req.params;
      const { name, gender, birthDate, disabilityType, groupId, guardianName, guardianPhone, remark, status } = req.body;

      // 1. 更新用户基本信息
      const userUpdates = {};
      if (name) userUpdates.realName = name;
      if (status !== undefined) userUpdates.status = status;
      if (gender) userUpdates.gender = gender;
      // 日期格式转换：ISO 8601 -> YYYY-MM-DD
      if (birthDate) {
        userUpdates.birthDate = typeof birthDate === 'string' && birthDate.includes('T')
          ? birthDate.split('T')[0]
          : birthDate;
      }

      if (Object.keys(userUpdates).length > 0) {
        await UserModel.update(employeeId, userUpdates);
      }

      // 2. 更新员工档案
      const existing = await EmployeeProfileModel.findByUserId(employeeId);
      const profileUpdates = {};
      if (disabilityType) profileUpdates.disability_type = disabilityType;
      if (groupId !== undefined) profileUpdates.group_id = groupId || null;
      if (guardianName) profileUpdates.emergency_contact = guardianName;
      if (guardianPhone) profileUpdates.emergency_phone = guardianPhone;
      if (remark !== undefined) profileUpdates.notes = remark;

      if (existing) {
        if (Object.keys(profileUpdates).length > 0) {
          await EmployeeProfileModel.update(employeeId, profileUpdates);
        }
      } else {
        await EmployeeProfileModel.create({
          userId: employeeId,
          disabilityType: disabilityType || null,
          supportLevel: null,
          workplace: null,
          jobTitle: null,
          emergencyContact: guardianName || null,
          emergencyPhone: guardianPhone || null,
          notes: remark || null,
        });
        // 设置group_id（create方法不支持，需要额外更新）
        if (groupId) {
          await EmployeeProfileModel.update(employeeId, { group_id: groupId });
        }
      }

      return success(res, null, '员工信息更新成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 删除员工
   * DELETE /api/v1/users/employees/:employeeId
   */
  async deleteEmployee(req, res, next) {
    try {
      await UserModel.delete(req.params.employeeId);
      return success(res, null, '员工已删除');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取员工列表（含档案）
   * GET /api/v1/users/employees/list
   */
  async listEmployees(req, res, next) {
    try {
      const { offset, limit, page, pageSize } = parsePagination(req.query);
      const counselorId = req.user.role === 'counselor' || req.user.role === 'co_counselor'
        ? req.user.id : null;

      const employees = await EmployeeProfileModel.findAll({ offset, limit, counselorId });
      const total = await EmployeeProfileModel.count(counselorId);

      return success(res, {
        list: employees,
        pagination: paginationMeta(total, page, pageSize),
      });
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取员工档案详情
   * GET /api/v1/users/employees/:employeeId/profile
   */
  async getEmployeeProfile(req, res, next) {
    try {
      const profile = await EmployeeProfileModel.findByUserId(req.params.employeeId);
      if (!profile) {
        return notFound(res, '员工档案不存在');
      }

      // 同时获取用户基本信息
      const { pool } = require('../config/database');
      const [userRows] = await pool.execute(
        `SELECT id as userId, username, real_name as name, gender, birth_date as birthDate, phone, avatar, status FROM users WHERE id = ?`,
        [req.params.employeeId]
      );
      const user = userRows[0] || {};

      // 获取分组名称
      let groupName = null;
      if (profile.group_id) {
        const [groupRows] = await pool.execute(
          `SELECT name FROM employee_groups WHERE id = ?`,
          [profile.group_id]
        );
        groupName = groupRows[0]?.name || null;
      }

      // 计算年龄
      let age = null;
      if (user.birthDate) {
        const birth = new Date(user.birthDate);
        const today = new Date();
        age = today.getFullYear() - birth.getFullYear();
        const m = today.getMonth() - birth.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) {
          age--;
        }
      }

      const data = {
        userId: user.userId,
        name: user.real_name || user.name,
        gender: user.gender,
        birthDate: user.birthDate,
        age,
        phone: user.phone,
        avatar: user.avatar,
        status: user.status,
        disabilityType: profile.disability_type,
        groupName,
        guardianName: profile.emergency_contact,
        guardianPhone: profile.emergency_phone,
        remark: profile.notes,
      };

      return success(res, data);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 创建/更新员工档案
   * POST /api/v1/users/employees/:employeeId/profile
   */
  async upsertEmployeeProfile(req, res, next) {
    try {
      const { employeeId } = req.params;
      const existing = await EmployeeProfileModel.findByUserId(employeeId);

      if (existing) {
        await EmployeeProfileModel.update(employeeId, req.body);
        return success(res, null, '档案更新成功');
      } else {
        const id = await EmployeeProfileModel.create({ userId: employeeId, ...req.body });
        return created(res, { id }, '档案创建成功');
      }
    } catch (err) {
      next(err);
    }
  }

  // ========== 辅导员关联管理 ==========

  /**
   * 获取员工的辅导员列表
   * GET /api/v1/users/employees/:employeeId/counselors
   */
  async getCounselors(req, res, next) {
    try {
      const counselors = await EmployeeCounselorModel.getCounselorsByEmployee(req.params.employeeId);
      return success(res, counselors);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 添加辅导员关联
   * POST /api/v1/users/employees/:employeeId/counselors
   */
  async addCounselor(req, res, next) {
    try {
      const { counselorId, isPrimary } = req.body;
      const id = await EmployeeCounselorModel.create(
        req.params.employeeId, counselorId, isPrimary || 0
      );
      return created(res, { id }, '辅导员关联已添加');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 删除辅导员关联
   * DELETE /api/v1/users/employees/:employeeId/counselors/:counselorId
   */
  async removeCounselor(req, res, next) {
    try {
      await EmployeeCounselorModel.delete(req.params.employeeId, req.params.counselorId);
      return success(res, null, '辅导员关联已删除');
    } catch (err) {
      next(err);
    }
  }

  // ========== 家长关联管理 ==========

  /**
   * 获取员工的家长列表
   * GET /api/v1/users/employees/:employeeId/parents
   */
  async getParents(req, res, next) {
    try {
      const parents = await EmployeeParentModel.getParentsByEmployee(req.params.employeeId);
      return success(res, parents);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 发起家长关联请求
   * POST /api/v1/users/employees/:employeeId/parents
   */
  async addParent(req, res, next) {
    try {
      const { parentId, relation } = req.body;
      const id = await EmployeeParentModel.create(req.params.employeeId, parentId, relation);
      return created(res, { id }, '家长关联请求已发送，等待审核');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 审核家长关联请求
   * PUT /api/v1/users/parents/requests/:requestId
   */
  async reviewParentRequest(req, res, next) {
    try {
      const { status } = req.body; // approved / rejected
      await EmployeeParentModel.review(req.params.requestId, status);
      return success(res, null, `家长关联请求已${status === 'approved' ? '通过' : '拒绝'}`);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取待审核的家长关联请求
   * GET /api/v1/users/employees/:employeeId/parent-requests
   */
  async getParentRequests(req, res, next) {
    try {
      const requests = await EmployeeParentModel.getPendingRequests(req.params.employeeId);
      return success(res, requests);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取家长关联的员工列表
   * GET /api/v1/users/parents/my-employees
   */
  async getParentEmployees(req, res, next) {
    try {
      const employees = await EmployeeParentModel.getEmployeesByParent(req.user.id);
      return success(res, employees);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new UserController();

/**
 * 沟通板路由
 */
const express = require('express');
const router = express.Router();
const communicationController = require('../controllers/communication.controller');
const { authMiddleware, optionalAuth } = require('../middlewares/auth.middleware');
const { isCounselor } = require('../middlewares/rbac.middleware');
const { validate } = require('../middlewares/validator.middleware');
const { body, param, query } = require('express-validator');

// 沟通板分类和常用语列表可以不需要认证（员工使用时可能未登录）
// 但管理操作需要认证

/**
 * 获取所有分类（公开接口）
 * GET /api/v1/communication/categories
 */
router.get('/categories', optionalAuth, communicationController.listCategories);

/**
 * 获取分类详情（含常用语）
 * GET /api/v1/communication/categories/:categoryId
 */
router.get('/categories/:categoryId', optionalAuth, communicationController.getCategory);

/**
 * 搜索常用语（公开接口）
 * GET /api/v1/communication/search
 */
router.get('/search', optionalAuth, communicationController.searchPhrases);

// 以下路由需要认证
router.use(authMiddleware);

/**
 * 创建分类（仅辅导员）
 * POST /api/v1/communication/categories
 */
router.post(
  '/categories',
  isCounselor,
  [
    body('name').trim().notEmpty().withMessage('分类名称不能为空'),
    validate,
  ],
  communicationController.createCategory
);

/**
 * 更新分类（仅辅导员）
 * PUT /api/v1/communication/categories/:categoryId
 */
router.put('/categories/:categoryId', isCounselor, communicationController.updateCategory);

/**
 * 删除分类（仅辅导员）
 * DELETE /api/v1/communication/categories/:categoryId
 */
router.delete('/categories/:categoryId', isCounselor, communicationController.deleteCategory);

/**
 * 获取分类下的常用语列表
 * GET /api/v1/communication/categories/:categoryId/phrases
 */
router.get('/categories/:categoryId/phrases', communicationController.listPhrases);

/**
 * 创建常用语（仅辅导员）
 * POST /api/v1/communication/categories/:categoryId/phrases
 */
router.post(
  '/categories/:categoryId/phrases',
  isCounselor,
  [
    body('text').trim().notEmpty().withMessage('常用语文本不能为空'),
    validate,
  ],
  communicationController.createPhrase
);

/**
 * 批量创建常用语（仅辅导员）
 * POST /api/v1/communication/categories/:categoryId/phrases/batch
 */
router.post(
  '/categories/:categoryId/phrases/batch',
  isCounselor,
  communicationController.batchCreatePhrases
);

/**
 * 更新常用语（仅辅导员）
 * PUT /api/v1/communication/phrases/:phraseId
 */
router.put('/phrases/:phraseId', isCounselor, communicationController.updatePhrase);

/**
 * 删除常用语（仅辅导员）
 * DELETE /api/v1/communication/phrases/:phraseId
 */
router.delete('/phrases/:phraseId', isCounselor, communicationController.deletePhrase);

module.exports = router;

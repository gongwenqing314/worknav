/**
 * 沟通板控制器
 * 处理沟通板分类和常用语的管理
 */
const CommCategoryModel = require('../models/CommCategory.model');
const CommPhraseModel = require('../models/CommPhrase.model');
const { success, created, notFound } = require('../utils/response');

class CommunicationController {
  // ========== 分类管理 ==========

  /**
   * 获取所有分类（含常用语数量）
   * GET /api/v1/communication/categories
   */
  async listCategories(req, res, next) {
    try {
      const categories = await CommCategoryModel.findAll();
      return success(res, categories);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 获取分类详情
   * GET /api/v1/communication/categories/:categoryId
   */
  async getCategory(req, res, next) {
    try {
      const category = await CommCategoryModel.findById(req.params.categoryId);
      if (!category) {
        return notFound(res, '分类不存在');
      }

      // 附带分类下的常用语
      category.phrases = await CommPhraseModel.findByCategory(req.params.categoryId);

      return success(res, category);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 创建分类
   * POST /api/v1/communication/categories
   */
  async createCategory(req, res, next) {
    try {
      const { name, icon, sortOrder } = req.body;
      const id = await CommCategoryModel.create({
        name,
        icon,
        sortOrder,
        createdBy: req.user.id,
      });
      return created(res, { id }, '分类创建成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 更新分类
   * PUT /api/v1/communication/categories/:categoryId
   */
  async updateCategory(req, res, next) {
    try {
      await CommCategoryModel.update(req.params.categoryId, req.body);
      return success(res, null, '分类更新成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 删除分类（软删除）
   * DELETE /api/v1/communication/categories/:categoryId
   */
  async deleteCategory(req, res, next) {
    try {
      await CommCategoryModel.softDelete(req.params.categoryId);
      return success(res, null, '分类已删除');
    } catch (err) {
      next(err);
    }
  }

  // ========== 常用语管理 ==========

  /**
   * 获取分类下的常用语列表
   * GET /api/v1/communication/categories/:categoryId/phrases
   */
  async listPhrases(req, res, next) {
    try {
      const phrases = await CommPhraseModel.findByCategory(req.params.categoryId);
      return success(res, phrases);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 创建常用语
   * POST /api/v1/communication/categories/:categoryId/phrases
   */
  async createPhrase(req, res, next) {
    try {
      const { text, imageUrl, audioUrl, sortOrder } = req.body;
      const id = await CommPhraseModel.create({
        categoryId: req.params.categoryId,
        text,
        imageUrl,
        audioUrl,
        sortOrder,
      });
      return created(res, { id }, '常用语创建成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 批量创建常用语
   * POST /api/v1/communication/categories/:categoryId/phrases/batch
   */
  async batchCreatePhrases(req, res, next) {
    try {
      const { phrases } = req.body;
      if (!phrases || !Array.isArray(phrases)) {
        return res.status(400).json({ code: 400, message: '请提供常用语数组', data: null });
      }

      const phraseData = phrases.map(p => ({
        categoryId: req.params.categoryId,
        text: p.text,
        imageUrl: p.imageUrl,
        audioUrl: p.audioUrl,
        sortOrder: p.sortOrder,
      }));

      const count = await CommPhraseModel.batchCreate(phraseData);
      return created(res, { count }, `成功创建${count}条常用语`);
    } catch (err) {
      next(err);
    }
  }

  /**
   * 更新常用语
   * PUT /api/v1/communication/phrases/:phraseId
   */
  async updatePhrase(req, res, next) {
    try {
      await CommPhraseModel.update(req.params.phraseId, req.body);
      return success(res, null, '常用语更新成功');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 删除常用语（软删除）
   * DELETE /api/v1/communication/phrases/:phraseId
   */
  async deletePhrase(req, res, next) {
    try {
      await CommPhraseModel.softDelete(req.params.phraseId);
      return success(res, null, '常用语已删除');
    } catch (err) {
      next(err);
    }
  }

  /**
   * 搜索常用语
   * GET /api/v1/communication/search?keyword=你好
   */
  async searchPhrases(req, res, next) {
    try {
      const { keyword } = req.query;
      if (!keyword) {
        return res.status(400).json({ code: 400, message: '请提供搜索关键词', data: null });
      }

      const results = await CommPhraseModel.search(keyword);
      return success(res, results);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new CommunicationController();

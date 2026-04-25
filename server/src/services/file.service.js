/**
 * 文件上传服务
 * 处理图片、音频等文件的存储和管理
 */
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('crypto').randomUUID ? { v4: () => require('crypto').randomUUID() } : require('uuid');
const config = require('../config');
const logger = require('../utils/logger');

// 确保上传目录存在
const uploadDir = path.resolve(config.upload.dir);
const subDirs = ['images', 'audio', 'annotations', 'avatars'];

for (const dir of subDirs) {
  const fullPath = path.join(uploadDir, dir);
  if (!fs.existsSync(fullPath)) {
    fs.mkdirSync(fullPath, { recursive: true });
  }
}

/**
 * 存储引擎配置
 */
const storage = multer.diskStorage({
  destination(req, file, cb) {
    // 根据文件类型选择子目录
    let subDir = 'images';
    if (file.mimetype.startsWith('audio/')) {
      subDir = 'audio';
    }

    cb(null, path.join(uploadDir, subDir));
  },
  filename(req, file, cb) {
    // 生成唯一文件名：时间戳 + 随机字符串 + 原始扩展名
    const ext = path.extname(file.originalname);
    const filename = `${Date.now()}-${Math.random().toString(36).substring(2, 8)}${ext}`;
    cb(null, filename);
  },
});

/**
 * 文件过滤器
 */
const fileFilter = (req, file, cb) => {
  const allowedTypes = [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4',
    'audio/webm', 'audio/aac',
  ];

  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`不支持的文件类型: ${file.mimetype}`), false);
  }
};

/**
 * Multer 实例
 */
const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: config.upload.maxFileSize,
    files: 5, // 单次最多上传5个文件
  },
});

/**
 * 获取文件的访问 URL
 */
function getFileUrl(filename, type = 'images') {
  return `/uploads/${type}/${filename}`;
}

/**
 * 删除文件
 */
function deleteFile(filePath) {
  try {
    const fullPath = path.resolve(filePath);
    if (fs.existsSync(fullPath)) {
      fs.unlinkSync(fullPath);
      logger.info(`文件已删除: ${filePath}`);
      return true;
    }
    return false;
  } catch (err) {
    logger.error(`删除文件失败: ${filePath}`, err.message);
    return false;
  }
}

module.exports = {
  upload,
  getFileUrl,
  deleteFile,
  uploadDir,
};

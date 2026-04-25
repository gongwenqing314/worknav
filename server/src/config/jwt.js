/**
 * JWT 配置
 * 包含 Access Token 和 Refresh Token 的签发与验证
 */
const jwt = require('jsonwebtoken');

// JWT 配置参数
const jwtConfig = {
  accessToken: {
    secret: process.env.JWT_SECRET || 'default_jwt_secret_change_me',
    expiresIn: process.env.JWT_EXPIRES_IN || '24h',
  },
  refreshToken: {
    secret: process.env.JWT_REFRESH_SECRET || 'default_refresh_secret_change_me',
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  },
};

/**
 * 签发 Access Token
 * @param {object} payload - 载荷数据
 * @returns {string} JWT token
 */
function generateAccessToken(payload) {
  return jwt.sign(payload, jwtConfig.accessToken.secret, {
    expiresIn: jwtConfig.accessToken.expiresIn,
  });
}

/**
 * 签发 Refresh Token
 * @param {object} payload - 载荷数据
 * @returns {string} Refresh token
 */
function generateRefreshToken(payload) {
  return jwt.sign(payload, jwtConfig.refreshToken.secret, {
    expiresIn: jwtConfig.refreshToken.expiresIn,
  });
}

/**
 * 验证 Access Token
 * @param {string} token - JWT token
 * @returns {object} 解码后的载荷
 */
function verifyAccessToken(token) {
  return jwt.verify(token, jwtConfig.accessToken.secret);
}

/**
 * 验证 Refresh Token
 * @param {string} token - Refresh token
 * @returns {object} 解码后的载荷
 */
function verifyRefreshToken(token) {
  return jwt.verify(token, jwtConfig.refreshToken.secret);
}

module.exports = {
  jwtConfig,
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
};

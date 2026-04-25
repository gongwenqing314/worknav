/**
 * Redis 连接配置
 * 使用 ioredis 客户端
 */
const Redis = require('ioredis');

// 创建 Redis 客户端
const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT, 10) || 6379,
  password: process.env.REDIS_PASSWORD || undefined,
  // 重试策略
  retryStrategy(times) {
    const delay = Math.min(times * 200, 5000);
    return delay;
  },
  // 最大重试次数
  maxRetriesPerRequest: 3,
  // 连接超时
  connectTimeout: 10000,
  // 离线队列（Redis 不可用时缓存命令）
  enableOfflineQueue: true,
  // 键前缀
  keyPrefix: 'worknav:',
});

// Redis 事件监听
redis.on('connect', () => {
  console.log('[Redis] 连接成功');
});

redis.on('error', (err) => {
  console.error('[Redis] 连接错误:', err.message);
});

redis.on('close', () => {
  console.warn('[Redis] 连接已关闭');
});

// 测试 Redis 连接
async function testConnection() {
  try {
    await redis.ping();
    console.log('[Redis] PING 成功');
    return true;
  } catch (error) {
    console.error('[Redis] PING 失败:', error.message);
    return false;
  }
}

module.exports = { redis, testConnection };

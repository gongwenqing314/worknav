const mysql = require('mysql2/promise');

async function seed() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'password123',
    database: 'worknav',
    charset: 'utf8mb4'
  });

  const bcrypt = require('bcryptjs');
  const passwordHash = await bcrypt.hash('password123', 10);

  console.log('Inserting test users...');

  await connection.execute(`
    INSERT INTO users (username, password_hash, real_name, phone, role, status) VALUES
    ('counselor01', ?, 'Zhang Counselor', '13800000001', 'counselor', 1),
    ('co_counselor01', ?, 'Li Assistant', '13800000002', 'co_counselor', 1),
    ('parent01', ?, 'Wang Parent', '13800000003', 'parent', 1),
    ('employee01', ?, 'Xiao Ming', '13800000101', 'employee', 1),
    ('employee02', ?, 'Xiao Hong', '13800000102', 'employee', 1)
  `, [passwordHash, passwordHash, passwordHash, passwordHash, passwordHash]);

  console.log('Test users inserted successfully!');
  console.log('Login credentials:');
  console.log('  Counselor: username=counselor01, password=password123');
  console.log('  Co-Counselor: username=co_counselor01, password=password123');
  console.log('  Parent: username=parent01, password=password123');

  await connection.end();
}

seed().catch(console.error);

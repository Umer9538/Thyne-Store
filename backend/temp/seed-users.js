// Seed users into thyne_jewels DB
const dbName = 'thyne_jewels';
const now = new Date();
const users = [
  {
    name: 'Admin User',
    email: 'admin@example.com',
    phone: '+10000000001',
    password: '$2a$12$uogY9XJOKXAjzkAdQyqw..OSFUkeM79oSY72hZDepywj0FtMgdtiC', // Admin@123
    isActive: true,
    isVerified: true,
    isAdmin: true,
    createdAt: now,
    updatedAt: now,
  },
  {
    name: 'Test User',
    email: 'test@example.com',
    phone: '+10000000002',
    password: '$2a$12$5U6OxbrjSw9qkPUQ4MPTsOz0vAoF088p/d4GJaVNPJRtkBVjTQXq6', // Password@123
    isActive: true,
    isVerified: true,
    isAdmin: false,
    createdAt: now,
    updatedAt: now,
  },
  {
    name: 'Jane Doe',
    email: 'jane@example.com',
    phone: '+10000000003',
    password: '$2a$12$5U6OxbrjSw9qkPUQ4MPTsOz0vAoF088p/d4GJaVNPJRtkBVjTQXq6', // Password@123
    isActive: true,
    isVerified: false,
    isAdmin: false,
    createdAt: now,
    updatedAt: now,
  },
];

const conn = db.getSiblingDB(dbName);

for (const u of users) {
  const exists = conn.users.findOne({ $or: [ { email: u.email }, { phone: u.phone } ] });
  if (!exists) {
    conn.users.insertOne(u);
    print(`Inserted user: ${u.email}`);
  } else {
    print(`Skipped existing user: ${u.email}`);
  }
}

print('User seeding complete.');

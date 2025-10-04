// Migration script to fix users with null addresses field
// This script converts null addresses fields to empty arrays

db.users.updateMany(
  { addresses: null },
  { $set: { addresses: [] } }
);

print("Migration completed: Fixed null addresses fields for existing users");

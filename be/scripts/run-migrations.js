import { up as addDefaultCategoriesToAllUsers } from "../migrations/20240328_add_default_categories_to_all_users.js";

const runMigrations = async () => {
  try {
    console.log("Running migrations...");
    await addDefaultCategoriesToAllUsers();
    console.log("Migrations completed successfully");
    process.exit(0);
  } catch (error) {
    console.error("Migration failed:", error);
    process.exit(1);
  }
};

runMigrations();

import { DataTypes } from "sequelize";
import sequelize from "../config/database.js";

export const up = async () => {
  try {
    // Add userId column
    await sequelize.query(`
      ALTER TABLE categories
      ADD COLUMN userId INT NOT NULL,
      ADD CONSTRAINT fk_category_user
      FOREIGN KEY (userId) REFERENCES users(id)
      ON DELETE CASCADE
    `);

    // Update existing categories to be associated with the first user
    await sequelize.query(`
      UPDATE categories
      SET userId = (SELECT id FROM users LIMIT 1)
      WHERE userId IS NULL
    `);

    // Add unique constraint for name and userId combination
    await sequelize.query(`
      ALTER TABLE categories
      ADD CONSTRAINT unique_category_name_per_user
      UNIQUE (name, userId)
    `);

    console.log('Migration completed successfully');
  } catch (error) {
    console.error('Migration failed:', error);
    throw error;
  }
};

export const down = async () => {
  try {
    // Remove unique constraint
    await sequelize.query(`
      ALTER TABLE categories
      DROP CONSTRAINT unique_category_name_per_user
    `);

    // Remove foreign key constraint
    await sequelize.query(`
      ALTER TABLE categories
      DROP CONSTRAINT fk_category_user
    `);

    // Remove userId column
    await sequelize.query(`
      ALTER TABLE categories
      DROP COLUMN userId
    `);

    console.log('Rollback completed successfully');
  } catch (error) {
    console.error('Rollback failed:', error);
    throw error;
  }
}; 
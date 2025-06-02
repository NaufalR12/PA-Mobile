import { DataTypes } from "sequelize";
import sequelize from "../config/database.js";

export const up = async () => {
  try {
    // Daftar kategori default tanpa type
    const defaultCategories = [
      "Hiburan",
      "Makanan",
      "Transportasi",
      "Investasi",
      "Gaji",
      "Hadiah",
      "Pakaian",
      "Kesehatan",
    ];

    // Dapatkan semua user yang ada
    const users = await sequelize.query("SELECT id FROM users", {
      type: sequelize.QueryTypes.SELECT,
    });

    // Untuk setiap user, tambahkan kategori default
    for (const user of users) {
      for (const name of defaultCategories) {
        try {
          await sequelize.query(
            `
            INSERT INTO categories (name, userId, created_at)
            VALUES (?, ?, NOW())
            ON DUPLICATE KEY UPDATE
            name = VALUES(name),
            userId = VALUES(userId)
          `,
            {
              replacements: [name, user.id],
            }
          );
        } catch (error) {
          console.log(
            `Skipping category ${name} for user ${user.id} as it already exists`
          );
        }
      }
    }

    console.log("Default categories migration completed successfully");
  } catch (error) {
    console.error("Default categories migration failed:", error);
    throw error;
  }
};

export const down = async () => {
  try {
    // Hapus kategori default untuk semua user
    await sequelize.query(`
      DELETE FROM categories 
      WHERE name IN (
        'Hiburan', 'Makanan', 'Transportasi', 'Investasi',
        'Gaji', 'Hadiah', 'Pakaian', 'Kesehatan'
      )
    `);

    console.log("Default categories rollback completed successfully");
  } catch (error) {
    console.error("Default categories rollback failed:", error);
    throw error;
  }
};

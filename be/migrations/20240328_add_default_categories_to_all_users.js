import { DataTypes } from "sequelize";
import sequelize from "../config/database.js";

// Daftar kategori default
const defaultCategories = [
  "Hiburan",
  "Makanan",
  "Transportasi",
  "Investasi",
  "Gaji",
  "Hadiah",
  "Pakaian",
  "Kesehatan",
  "Tagihan",
  "Belanja",
  "Bonus",
  "Lainnya",
];

export const up = async () => {
  try {
    // Dapatkan semua user yang ada
    const users = await sequelize.query("SELECT id FROM users", {
      type: sequelize.QueryTypes.SELECT,
    });

    // Untuk setiap user, tambahkan kategori default jika belum ada
    for (const user of users) {
      for (const categoryName of defaultCategories) {
        try {
          // Cek apakah kategori sudah ada untuk user ini
          const existingCategory = await sequelize.query(
            `SELECT id FROM categories WHERE name = ? AND userId = ?`,
            {
              replacements: [categoryName, user.id],
              type: sequelize.QueryTypes.SELECT,
            }
          );

          // Jika kategori belum ada, tambahkan
          if (existingCategory.length === 0) {
            await sequelize.query(
              `INSERT INTO categories (name, userId, created_at) VALUES (?, ?, NOW())`,
              {
                replacements: [categoryName, user.id],
              }
            );
            console.log(`Added category ${categoryName} for user ${user.id}`);
          } else {
            console.log(
              `Category ${categoryName} already exists for user ${user.id}`
            );
          }
        } catch (error) {
          console.error(
            `Error adding category ${categoryName} for user ${user.id}:`,
            error
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
        'Gaji', 'Hadiah', 'Pakaian', 'Kesehatan',
        'Tagihan', 'Belanja', 'Bonus', 'Lainnya'
      )
    `);

    console.log("Default categories rollback completed successfully");
  } catch (error) {
    console.error("Default categories rollback failed:", error);
    throw error;
  }
};

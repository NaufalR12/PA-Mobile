import sequelize from "../config/database.js";

export const up = async () => {
  // Buat tabel default_categories
  await sequelize.query(`
    CREATE TABLE IF NOT EXISTS default_categories (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(255) NOT NULL UNIQUE
    )
  `);

  // Isi data default
  await sequelize.query(`
    INSERT IGNORE INTO default_categories (name) VALUES
    ('Hiburan'), ('Makanan'), ('Transportasi'), ('Investasi'),
    ('Gaji'), ('Hadiah'), ('Pakaian'), ('Kesehatan'),
    ('Tagihan'), ('Belanja'), ('Bonus'), ('Lainnya')
  `);
};

export const down = async () => {
  await sequelize.query(`DROP TABLE IF EXISTS default_categories`);
};

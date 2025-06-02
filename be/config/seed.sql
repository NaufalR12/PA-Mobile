-- Hapus data yang ada (jika perlu)
DELETE FROM transactions;
DELETE FROM categories;

-- Reset auto increment
ALTER TABLE transactions AUTO_INCREMENT = 1;
ALTER TABLE categories AUTO_INCREMENT = 1;

-- Insert kategori default
INSERT INTO categories (nama_kategori, jenis, deskripsi) VALUES
-- Kategori Pemasukan
('Gaji', 'pemasukan', 'Pendapatan dari gaji bulanan'),
('Bonus', 'pemasukan', 'Pendapatan tambahan dari bonus'),
('Investasi', 'pemasukan', 'Pendapatan dari hasil investasi'),
('Hadiah', 'pemasukan', 'Pendapatan dari hadiah atau pemberian'),

-- Kategori Pengeluaran
('Makanan', 'pengeluaran', 'Pengeluaran untuk makanan dan minuman'),
('Transportasi', 'pengeluaran', 'Pengeluaran untuk transportasi'),
('Belanja', 'pengeluaran', 'Pengeluaran untuk belanja kebutuhan'),
('Tagihan', 'pengeluaran', 'Pengeluaran untuk tagihan rutin'),
('Hiburan', 'pengeluaran', 'Pengeluaran untuk hiburan'),
('Kesehatan', 'pengeluaran', 'Pengeluaran untuk kesehatan'); 
import Category from "../model/Category.js";

export const CategoryController = {
  create: async (req, res) => {
    try {
      const { name } = req.body;
      const userId = req.user.userId; // Get userId from authenticated user

      // Validasi data
      if (!name) {
        return res.status(400).json({
          status: "error",
          message: "Nama kategori harus diisi",
        });
      }

      // Cek apakah kategori sudah ada untuk user ini
      const existingCategory = await Category.findOne({
        where: { name, userId },
      });

      if (existingCategory) {
        return res.status(400).json({
          status: "error",
          message: "Kategori sudah ada",
        });
      }

      const category = await Category.create({
        name,
        userId,
      });

      res.status(201).json({
        status: "success",
        message: "Kategori berhasil ditambahkan",
        data: category,
      });
    } catch (error) {
      console.error("Error in create category:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal menambahkan kategori",
      });
    }
  },

  getAll: async (req, res) => {
    try {
      const userId = req.user.userId; // Get userId from authenticated user
      const categories = await Category.findAll({
        where: { userId },
        order: [["name", "ASC"]],
      });

      res.json({
        status: "success",
        data: categories,
      });
    } catch (error) {
      console.error("Error in get categories:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal mengambil kategori",
      });
    }
  },

  getByType: async (req, res) => {
    try {
      const { type } = req.params;
      const userId = req.user.userId; // Get userId from authenticated user

      if (!["income", "expense"].includes(type)) {
        return res.status(400).json({
          status: "error",
          message: "Tipe kategori harus income atau expense",
        });
      }

      const categories = await Category.findAll({
        where: { type, userId },
        order: [["name", "ASC"]],
      });

      res.json({
        status: "success",
        data: categories,
      });
    } catch (error) {
      console.error("Error in get categories by type:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal mengambil kategori",
      });
    }
  },

  update: async (req, res) => {
    try {
      const { id } = req.params;
      const { name } = req.body;
      const userId = req.user.userId; // Get userId from authenticated user

      const category = await Category.findOne({
        where: { id, userId },
      });

      if (!category) {
        return res.status(404).json({
          status: "error",
          message: "Kategori tidak ditemukan",
        });
      }

      // Cek apakah nama kategori sudah ada untuk user ini
      if (name && name !== category.name) {
        const existingCategory = await Category.findOne({
          where: { name, userId },
        });

        if (existingCategory) {
          return res.status(400).json({
            status: "error",
            message: "Kategori sudah ada",
          });
        }
      }

      await category.update({
        name: name || category.name,
      });

      res.json({
        status: "success",
        message: "Kategori berhasil diperbarui",
        data: category,
      });
    } catch (error) {
      console.error("Error in update category:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal memperbarui kategori",
      });
    }
  },

  delete: async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.userId; // Get userId from authenticated user

      const category = await Category.findOne({
        where: { id, userId },
      });

      if (!category) {
        return res.status(404).json({
          status: "error",
          message: "Kategori tidak ditemukan",
        });
      }

      await category.destroy();

      res.json({
        status: "success",
        message: "Kategori berhasil dihapus",
      });
    } catch (error) {
      console.error("Error in delete category:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal menghapus kategori",
      });
    }
  },
};

import bcrypt from "bcrypt";
import User from "../model/User.js";
import Transaction from "../model/Transaction.js";
import Category from "../model/Category.js";
import Plan from "../model/Plan.js";
import sequelize from "../config/database.js";

export const UserController = {
  register: async (req, res) => {
    try {
      const { name, email, gender, password } = req.body;

      // Check if email already exists
      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        return res.status(400).json({
          status: "error",
          message: "Email sudah terdaftar",
        });
      }

      // Hash password
      const salt = await bcrypt.genSalt();
      const hashedPassword = await bcrypt.hash(password, salt);

      // Create user
      const user = await User.create({
        name,
        email,
        gender,
        password: hashedPassword,
      });

      // Ambil kategori default dari tabel default_categories
      const [defaultCategories] = await sequelize.query(
        "SELECT name FROM default_categories"
      );
      for (const cat of defaultCategories) {
        await Category.create({
          name: cat.name,
          userId: user.id,
        });
      }

      res.status(201).json({
        status: "success",
        message: "Registrasi berhasil",
        data: {
          id: user.id,
          name: user.name,
          email: user.email,
          gender: user.gender,
        },
      });
    } catch (error) {
      console.error("Error in register:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal melakukan registrasi",
      });
    }
  },

  login: async (req, res) => {
    try {
      const { email, password } = req.body;
      console.log("Login attempt for email:", email);

      // Find user by email
      const user = await User.findOne({ where: { email } });
      if (!user) {
        console.log("User not found for email:", email);
        return res.status(404).json({
          status: "error",
          message: "User tidak ditemukan",
        });
      }

      // Check password
      const match = await bcrypt.compare(password, user.password);
      if (!match) {
        console.log("Invalid password for email:", email);
        return res.status(400).json({
          status: "error",
          message: "Password salah",
        });
      }

      res.status(200).json({
        status: "success",
        message: "Login berhasil",
        data: {
          id: user.id,
          name: user.name,
          email: user.email,
          gender: user.gender,
        },
      });
    } catch (error) {
      console.error("Error in login:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal melakukan login",
      });
    }
  },

  getProfile: async (req, res) => {
    try {
      const userId = req.query.userId;
      if (!userId) {
        return res.status(400).json({
          status: "error",
          message: "User ID diperlukan",
        });
      }

      const user = await User.findByPk(userId, {
        attributes: ["id", "name", "email", "gender", "foto_profil"],
      });

      if (!user) {
        return res.status(404).json({
          status: "error",
          message: "User tidak ditemukan",
        });
      }

      res.json({
        status: "success",
        data: user,
      });
    } catch (error) {
      console.error("Error in getProfile:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal mengambil profil",
      });
    }
  },

  getProfilePhoto: async (req, res) => {
    try {
      const userId = req.query.userId;
      if (!userId) {
        return res.status(400).json({
          status: "error",
          message: "User ID diperlukan",
        });
      }

      const user = await User.findByPk(userId, {
        attributes: ["foto_profil"],
      });

      if (!user || !user.foto_profil) {
        return res.status(404).json({
          status: "error",
          message: "Foto profil tidak ditemukan",
          useDefault: true,
        });
      }

      res.writeHead(200, {
        "Content-Type": "image/jpeg",
        "Content-Length": user.foto_profil.length,
      });
      res.end(user.foto_profil);
    } catch (error) {
      console.error("Error in getProfilePhoto:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal mengambil foto profil",
      });
    }
  },

  updateProfile: async (req, res) => {
    try {
      const userId = req.query.userId;
      if (!userId) {
        return res.status(400).json({
          status: "error",
          message: "User ID diperlukan",
        });
      }

      const { name, gender } = req.body;
      const updateData = {};

      if (name) updateData.name = name;
      if (gender) updateData.gender = gender;
      if (req.file) updateData.foto_profil = req.file.buffer;

      const user = await User.findByPk(userId);
      if (!user) {
        return res.status(404).json({
          status: "error",
          message: "User tidak ditemukan",
        });
      }

      await user.update(updateData);

      res.json({
        status: "success",
        message: "Profil berhasil diperbarui",
        data: {
          id: user.id,
          name: user.name,
          email: user.email,
          gender: user.gender,
        },
      });
    } catch (error) {
      console.error("Error in updateProfile:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal memperbarui profil",
      });
    }
  },

  logout: async (req, res) => {
    try {
      res.status(200).json({
        status: "success",
        message: "Logout berhasil",
      });
    } catch (error) {
      console.error("Error in logout:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal melakukan logout",
      });
    }
  },

  deleteAccount: async (req, res) => {
    try {
      const userId = req.query.userId;
      if (!userId) {
        return res.status(400).json({
          status: "error",
          message: "User ID diperlukan",
        });
      }

      // Mulai transaction untuk memastikan semua operasi berhasil atau tidak sama sekali
      const result = await sequelize.transaction(async (t) => {
        // 1. Hapus Transactions terlebih dahulu
        await Transaction.destroy({
          where: { userId },
          transaction: t,
        });
        console.log(`Transactions for user ${userId} deleted.`);

        // 2. Hapus Plans
        await Plan.destroy({
          where: { userId },
          transaction: t,
        });
        console.log(`Plans for user ${userId} deleted.`);

        // 3. Hapus Categories
        await Category.destroy({
          where: { userId },
          transaction: t,
        });
        console.log(`Categories for user ${userId} deleted.`);

        // 4. Hapus User
        const user = await User.findByPk(userId);
        if (!user) {
          throw new Error("User tidak ditemukan");
        }

        await user.destroy({ transaction: t });
        console.log(`User ${userId} deleted.`);

        return true;
      });

      if (result) {
        res.status(200).json({
          status: "success",
          message: "Akun berhasil dihapus beserta data terkait.",
        });
      }
    } catch (error) {
      console.error("Error in deleteAccount:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal menghapus akun.",
        detail: error.message,
      });
    }
  },
};

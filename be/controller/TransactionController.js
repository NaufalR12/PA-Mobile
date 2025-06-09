import Transaction from "../model/Transaction.js";
import Category from "../model/Category.js";
import {
  getPlanByCategoryAndUser,
  updateRemainingAmount,
} from "../model/PlanModel.js";
import { Op } from "sequelize";
import { PlanController } from "./PlanController.js";

export const TransactionController = {
  create: async (req, res) => {
    try {
      const { amount, description, date, type, categoryId } = req.body;
      const userId = req.query.userId;

      // Log data yang diterima dari frontend
      console.log("Data transaksi yang diterima:", {
        amount,
        description,
        date,
        type,
        categoryId,
        userId,
      });

      if (!userId) {
        return res.status(400).json({
          status: "error",
          message: "User ID diperlukan",
        });
      }

      // Validasi data
      if (!amount || !date || !type || !categoryId) {
        return res.status(400).json({
          status: "error",
          message: "Semua field wajib diisi",
        });
      }

      // Cek apakah kategori ada dan milik user yang sama
      const category = await Category.findOne({
        where: { id: categoryId, userId },
      });

      if (!category) {
        return res.status(404).json({
          status: "error",
          message: "Kategori tidak ditemukan",
        });
      }

      const transaction = await Transaction.create({
        amount,
        description,
        date,
        type,
        userId,
        categoryId,
      });

      // Update remainingAmount di plan jika transaksi adalah pengeluaran
      if (type === "expense") {
        await PlanController.recalculateForPlanByCategory(userId, categoryId);
      }

      res.status(201).json({
        status: "success",
        message: "Transaksi berhasil ditambahkan",
        data: transaction,
      });
    } catch (error) {
      console.error("Error in create transaction:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal menambahkan transaksi",
      });
    }
  },

  getByUserId: async (req, res) => {
    try {
      const userId = req.query.userId;
      if (!userId) {
        return res.status(400).json({
          status: "error",
          message: "User ID diperlukan",
        });
      }

      const transactions = await Transaction.findAll({
        where: { userId },
        include: [
          {
            model: Category,
            attributes: ["id", "name"],
          },
        ],
        order: [["date", "DESC"]],
      });

      // Tambahkan log untuk melihat data date dan created_at
      console.log(
        "Data transaksi dari database:",
        transactions.map((t) => ({
          id: t.id,
          date: t.date,
          created_at: t.created_at,
        }))
      );

      res.json({
        status: "success",
        data: transactions,
      });
    } catch (error) {
      console.error("Error in get transactions:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal mengambil transaksi",
      });
    }
  },

  getById: async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.query.userId;

      if (!userId) {
        return res.status(400).json({
          status: "error",
          message: "User ID diperlukan",
        });
      }

      const transaction = await Transaction.findOne({
        where: { id, userId },
        include: [
          {
            model: Category,
            attributes: ["id", "name"],
          },
        ],
      });

      if (!transaction) {
        return res.status(404).json({
          status: "error",
          message: "Transaksi tidak ditemukan",
        });
      }

      res.json({
        status: "success",
        data: transaction,
      });
    } catch (error) {
      console.error("Error in get transaction:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal mengambil transaksi",
      });
    }
  },

  getByDateRange: async (req, res) => {
    try {
      const { startDate, endDate } = req.query;
      const userId = req.query.userId;

      if (!userId) {
        return res.status(400).json({
          status: "error",
          message: "User ID diperlukan",
        });
      }

      if (!startDate || !endDate) {
        return res.status(400).json({
          status: "error",
          message: "Tanggal awal dan akhir diperlukan",
        });
      }

      const transactions = await Transaction.findAll({
        where: {
          userId,
          date: {
            [Op.between]: [startDate, endDate],
          },
        },
        include: [
          {
            model: Category,
            attributes: ["id", "name"],
          },
        ],
        order: [["date", "DESC"]],
      });

      res.json({
        status: "success",
        data: transactions,
      });
    } catch (error) {
      console.error("Error in get transactions by date range:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal mengambil transaksi",
      });
    }
  },

  update: async (req, res) => {
    try {
      const { id } = req.params;
      const { amount, description, date, type, categoryId } = req.body;
      const userId = req.query.userId;

      if (!userId) {
        return res.status(400).json({
          status: "error",
          message: "User ID diperlukan",
        });
      }

      const transaction = await Transaction.findOne({
        where: { id, userId },
      });

      if (!transaction) {
        return res.status(404).json({
          status: "error",
          message: "Transaksi tidak ditemukan",
        });
      }

      // Jika categoryId diubah, validasi bahwa kategori baru milik user yang sama
      if (categoryId && categoryId !== transaction.categoryId) {
        const category = await Category.findOne({
          where: { id: categoryId, userId },
        });

        if (!category) {
          return res.status(404).json({
            status: "error",
            message: "Kategori tidak ditemukan",
          });
        }
      }

      await transaction.update({
        amount: amount || transaction.amount,
        description: description || transaction.description,
        date: date || transaction.date,
        type: type || transaction.type,
        categoryId: categoryId || transaction.categoryId,
      });

      // Update remainingAmount di plan jika transaksi adalah pengeluaran
      if (transaction.type === "expense") {
        await PlanController.recalculateForPlanByCategory(
          userId,
          transaction.categoryId
        );
      }

      res.json({
        status: "success",
        message: "Transaksi berhasil diperbarui",
        data: transaction,
      });
    } catch (error) {
      console.error("Error in update transaction:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal memperbarui transaksi",
      });
    }
  },

  delete: async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.query.userId;

      if (!userId) {
        return res.status(400).json({
          status: "error",
          message: "User ID diperlukan",
        });
      }

      const transaction = await Transaction.findOne({
        where: { id, userId },
      });

      if (!transaction) {
        return res.status(404).json({
          status: "error",
          message: "Transaksi tidak ditemukan",
        });
      }

      await transaction.destroy();

      // Update remainingAmount di plan jika transaksi yang dihapus adalah pengeluaran
      if (transaction.type === "expense") {
        await PlanController.recalculateForPlanByCategory(
          userId,
          transaction.categoryId
        );
      }

      res.json({
        status: "success",
        message: "Transaksi berhasil dihapus",
      });
    } catch (error) {
      console.error("Error in delete transaction:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal menghapus transaksi",
      });
    }
  },
};

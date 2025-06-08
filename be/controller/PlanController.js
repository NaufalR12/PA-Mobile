import Plan from "../model/Plan.js";
import Category from "../model/Category.js";
import Transaction from "../model/Transaction.js";
import { Op } from "sequelize";

export const PlanController = {
  create: async (req, res) => {
    try {
      const { categoryId, amount, description } = req.body;
      const userId = req.query.userId;

      if (!userId) {
        return res.status(400).json({
          status: "error",
          message: "User ID diperlukan",
        });
      }

      // Validasi data
      if (!amount || !categoryId) {
        return res.status(400).json({
          status: "error",
          message: "Nominal dan kategori wajib diisi",
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

      // Cek apakah sudah ada plan untuk kategori ini
      const existingPlan = await Plan.findOne({
        where: { categoryId, userId },
      });

      if (existingPlan) {
        return res.status(400).json({
          status: "error",
          message: "Sudah ada rencana untuk kategori ini",
        });
      }

      const plan = await Plan.create({
        categoryId,
        userId,
        amount,
        remainingAmount: amount,
        description,
      });

      res.status(201).json({
        status: "success",
        message: "Rencana berhasil ditambahkan",
        data: plan,
      });
    } catch (error) {
      console.error("Error in create plan:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal menambahkan rencana",
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

      const plans = await Plan.findAll({
        where: { userId },
        include: [
          {
            model: Category,
            attributes: ["id", "name"],
          },
        ],
        order: [["createdAt", "DESC"]],
      });

      res.json({
        status: "success",
        data: plans,
      });
    } catch (error) {
      console.error("Error in get plans:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal mengambil rencana",
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

      const plan = await Plan.findOne({
        where: { id, userId },
        include: [
          {
            model: Category,
            attributes: ["id", "name"],
          },
        ],
      });

      if (!plan) {
        return res.status(404).json({
          status: "error",
          message: "Rencana tidak ditemukan",
        });
      }

      res.json({
        status: "success",
        data: plan,
      });
    } catch (error) {
      console.error("Error in get plan:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal mengambil rencana",
      });
    }
  },

  update: async (req, res) => {
    try {
      const { id } = req.params;
      const { amount, description } = req.body;
      const userId = req.query.userId;

      if (!userId) {
        return res.status(400).json({
          status: "error",
          message: "User ID diperlukan",
        });
      }

      const plan = await Plan.findOne({
        where: { id, userId },
      });

      if (!plan) {
        return res.status(404).json({
          status: "error",
          message: "Rencana tidak ditemukan",
        });
      }

      // Hitung selisih amount untuk menyesuaikan remainingAmount
      const amountDiff = amount - plan.amount;
      const newRemainingAmount = plan.remainingAmount + amountDiff;

      await plan.update({
        amount,
        remainingAmount: newRemainingAmount,
        description: description || plan.description,
      });

      res.json({
        status: "success",
        message: "Rencana berhasil diperbarui",
        data: plan,
      });
    } catch (error) {
      console.error("Error in update plan:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal memperbarui rencana",
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

      const plan = await Plan.findOne({
        where: { id, userId },
      });

      if (!plan) {
        return res.status(404).json({
          status: "error",
          message: "Rencana tidak ditemukan",
        });
      }

      await plan.destroy();

      res.json({
        status: "success",
        message: "Rencana berhasil dihapus",
      });
    } catch (error) {
      console.error("Error in delete plan:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal menghapus rencana",
      });
    }
  },

  // Fungsi untuk memperbarui remainingAmount saat ada transaksi baru
  async updateRemainingAmount(transaction) {
    try {
      if (transaction.type === "expense") {
        const plan = await Plan.findOne({
          where: {
            categoryId: transaction.categoryId,
            remainingAmount: { [Op.gt]: 0 },
          },
        });

        if (plan) {
          const newRemainingAmount = plan.remainingAmount - transaction.amount;
          await plan.update({
            remainingAmount: Math.max(0, newRemainingAmount),
          });
        }
      }
    } catch (error) {
      console.error("Error updating remaining amount:", error);
      throw error;
    }
  },

  // Fungsi untuk menghitung ulang remainingAmount untuk plan berdasarkan kategori dan userId
  async recalculateForPlanByCategory(userId, categoryId) {
    try {
      const plan = await Plan.findOne({
        where: { userId, categoryId },
      });

      if (!plan) {
        // console.log(`No plan found for userId: ${userId}, categoryId: ${categoryId}. Skipping recalculation.`);
        return;
      }

      const transactions = await Transaction.findAll({
        where: {
          userId,
          categoryId,
          type: "expense",
        },
        attributes: ["amount"],
      });

      const totalExpenses = transactions.reduce(
        (sum, t) => sum + parseFloat(t.amount),
        0
      );

      const newRemainingAmount = plan.amount - totalExpenses;
      await plan.update({
        remainingAmount: Math.max(0, newRemainingAmount),
      });
      console.log(
        `Recalculated remaining amount for plan ${plan.id} (category ${categoryId}): ${newRemainingAmount}`
      );
    } catch (error) {
      console.error(
        `Error recalculating remaining amount for category ${categoryId}, user ${userId}:`,
        error
      );
      // Tidak melempar error agar tidak mengganggu operasi utama (create/update/delete transaction)
    }
  },
};

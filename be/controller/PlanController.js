import Plan from "../model/Plan.js";
import Category from "../model/Category.js";
import Transaction from "../model/Transaction.js";
import { Op } from "sequelize";

export const PlanController = {
  create: async (req, res) => {
    try {
      const { categoryId, amount, description } = req.body;
      const userId = req.user.userId;

      // Validasi data
      if (!categoryId) {
        return res.status(400).json({
          status: "error",
          message: "Kategori harus dipilih",
        });
      }

      if (!amount || amount <= 0) {
        return res.status(400).json({
          status: "error",
          message: "Jumlah harus lebih dari 0",
        });
      }

      if (!description) {
        return res.status(400).json({
          status: "error",
          message: "Deskripsi harus diisi",
        });
      }

      // Cek apakah kategori ada
      const category = await Category.findByPk(categoryId);
      if (!category) {
        return res.status(404).json({
          status: "error",
          message: "Kategori tidak ditemukan",
        });
      }

      // Cek apakah kategori sudah memiliki perencanaan
      const existingPlan = await Plan.findOne({
        where: { categoryId, userId },
      });

      if (existingPlan) {
        return res.status(400).json({
          status: "error",
          message: "Kategori ini sudah memiliki perencanaan",
        });
      }

      const plan = await Plan.create({
        userId,
        categoryId,
        amount,
        description,
        remainingAmount: amount,
      });

      res.status(201).json({
        status: "success",
        message: "Rencana berhasil ditambahkan",
        data: {
          ...plan.toJSON(),
          categoryName: category.name,
        },
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
      const userId = req.user.userId;

      const plans = await Plan.findAll({
        where: { userId },
        include: [
          {
            model: Category,
            attributes: ["name"],
          },
        ],
        order: [["createdAt", "DESC"]],
      });

      const formattedPlans = plans.map((plan) => ({
        ...plan.toJSON(),
        categoryName: plan.Category ? plan.Category.name : null,
      }));

      res.json({
        status: "success",
        data: formattedPlans,
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
      const userId = req.user.userId;

      const plan = await Plan.findOne({
        where: { id, userId },
        include: [
          {
            model: Category,
            attributes: ["name"],
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
        data: {
          ...plan.toJSON(),
          categoryName: plan.Category ? plan.Category.name : null,
        },
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
      const userId = req.user.userId;
      const { categoryId, amount, description } = req.body;

      console.log("Updating plan with data:", { categoryId, amount, description });

      const plan = await Plan.findOne({
        where: { id, userId },
      });

      if (!plan) {
        return res.status(404).json({
          status: "error",
          message: "Rencana tidak ditemukan",
        });
      }

      // Cek apakah kategori ada jika diupdate
      if (categoryId) {
        const category = await Category.findByPk(categoryId);
        if (!category) {
          return res.status(404).json({
            status: "error",
            message: "Kategori tidak ditemukan",
          });
        }
      }

      try {
        // Update plan's amount and other fields first
        await plan.update({
          categoryId: categoryId || plan.categoryId,
          amount: amount || plan.amount,
          description: description || plan.description,
        });

        // Recalculate remainingAmount based on actual expenses
        await PlanController.recalculateForPlanByCategory(userId, plan.categoryId);

        // Fetch the updated plan
        const updatedPlan = await Plan.findOne({
          where: { id, userId },
          include: [{ model: Category, attributes: ["name"] }],
        });

        if (!updatedPlan) {
          throw new Error("Failed to fetch updated plan");
        }

        res.json({
          status: "success",
          message: "Rencana berhasil diperbarui",
          data: {
            ...updatedPlan.toJSON(),
            categoryName: updatedPlan.Category ? updatedPlan.Category.name : null,
          },
        });
      } catch (updateError) {
        console.error("Error during plan update:", updateError);
        throw updateError;
      }
    } catch (error) {
      console.error("Error in update plan:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal memperbarui rencana",
        detail: error.message
      });
    }
  },

  delete: async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.userId;

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

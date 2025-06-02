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
      const { amount, categoryId, date, description, type } = req.body;
      const userId = req.user.userId;

      console.log("Received transaction data for creation:", req.body);

      // Validasi data
      if (!amount || amount <= 0) {
        console.error("Validation error: Nominal must be greater than 0");
        return res.status(400).json({ msg: "Nominal harus lebih dari 0" });
      }

      if (!categoryId) {
        console.error("Validation error: Category ID is missing");
        return res.status(400).json({ msg: "Kategori harus dipilih" });
      }

      if (!date) {
        console.error("Validation error: Date is missing");
        return res.status(400).json({ msg: "Tanggal harus diisi" });
      }

      if (!type || !["income", "expense"].includes(type)) {
        console.error("Validation error: Invalid transaction type", type);
        return res
          .status(400)
          .json({ msg: "Tipe transaksi harus income atau expense" });
      }

      // Validasi format tanggal
      const dateObj = new Date(date);
      if (isNaN(dateObj.getTime())) {
        console.error("Validation error: Invalid date format", date);
        return res.status(400).json({ msg: "Format tanggal tidak valid" });
      }

      const transaction = await Transaction.create({
        userId,
        amount,
        categoryId,
        date,
        description,
        type,
      });

      // Get category name
      const category = await Category.findByPk(categoryId);

      // Jika transaksi adalah pengeluaran, hitung ulang remainingAmount untuk plan terkait
      if (type === "expense") {
        try {
          await PlanController.recalculateForPlanByCategory(userId, categoryId);
          console.log(
            `Recalculated plan for category ${categoryId} after new transaction ${transaction.id}`
          );
        } catch (recalcError) {
          console.error(
            `Error recalculating plan for category ${categoryId} after new transaction:`,
            recalcError
          );
          // Lanjutkan meskipun recalculate gagal, karena transaksi utama sudah berhasil
        }
      }

      console.log("Transaction created successfully:", transaction);
      res.status(201).json({
        status: "success",
        message: "Transaksi berhasil ditambahkan",
        data: {
          ...transaction.toJSON(),
          categoryName: category ? category.name : null,
        },
      });
    } catch (error) {
      console.error("Error in create transaction:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal menambahkan transaksi",
      });
    }
  },

  getById: async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.userId;

      const transaction = await Transaction.findOne({
        where: { id, userId },
        include: [
          {
            model: Category,
            attributes: ["name"],
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
        data: {
          ...transaction.toJSON(),
          categoryName: transaction.Category ? transaction.Category.name : null,
        },
      });
    } catch (error) {
      console.error("Error in get transaction:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal mengambil transaksi",
      });
    }
  },

  getByUserId: async (req, res) => {
    try {
      const userId = req.user.userId;

      const transactions = await Transaction.findAll({
        where: { userId },
        include: [
          {
            model: Category,
            attributes: ["name"],
          },
        ],
        order: [["date", "DESC"]],
      });

      const formattedTransactions = transactions.map((transaction) => ({
        ...transaction.toJSON(),
        categoryName: transaction.Category ? transaction.Category.name : null,
      }));

      res.json({
        status: "success",
        data: formattedTransactions,
      });
    } catch (error) {
      console.error("Error in get transactions:", error);
      res.status(500).json({
        status: "error",
        message: "Gagal mengambil transaksi",
      });
    }
  },

  getByDateRange: async (req, res) => {
    try {
      const userId = req.user.userId;
      const { startDate, endDate } = req.query;

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
            attributes: ["name"],
          },
        ],
        order: [["date", "DESC"]],
      });

      const formattedTransactions = transactions.map((transaction) => ({
        ...transaction.toJSON(),
        categoryName: transaction.Category ? transaction.Category.name : null,
      }));

      res.json({
        status: "success",
        data: formattedTransactions,
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
      const userId = req.user.userId;
      const { amount, categoryId, date, description, type } = req.body;

      const transaction = await Transaction.findOne({
        where: { id, userId },
      });

      if (!transaction) {
        return res.status(404).json({
          status: "error",
          message: "Transaksi tidak ditemukan",
        });
      }

      const oldCategoryId = transaction.categoryId;
      const oldType = transaction.type;

      await transaction.update({
        amount,
        categoryId, // categoryId baru
        date,
        description,
        type, // type baru
      });

      // Logika untuk recalculate plan(s) setelah transaksi diupdate
      const newActualCategoryId = transaction.categoryId; // Kategori setelah update
      const newActualType = transaction.type; // Tipe setelah update

      // Jika transaksi lama adalah pengeluaran, hitung ulang plan untuk kategori lama.
      // Ini akan mengembalikan efek transaksi lama pada plan kategori lama.
      if (oldType === 'expense') {
        try {
          await PlanController.recalculateForPlanByCategory(userId, oldCategoryId);
          console.log(
            `Recalculated plan for old category ${oldCategoryId} (due to transaction update ${transaction.id})`
          );
        } catch (recalcError) {
          console.error(
            `Error recalculating plan for old category ${oldCategoryId} (transaction update):`,
            recalcError
          );
        }
      }

      // Jika transaksi baru adalah pengeluaran, hitung ulang plan untuk kategori baru.
      // Ini akan menerapkan efek transaksi baru pada plan kategori baru.
      // Jika oldCategoryId sama dengan newActualCategoryId, ini akan menghitung ulang plan yang sama,
      // yang efektif memperbarui sisa berdasarkan perubahan amount atau jika tipe berubah dari income ke expense.
      if (newActualType === 'expense') {
        // Hanya panggil untuk kategori baru jika berbeda dari kategori lama yang sudah dihitung ulang (jika oldType expense),
        // atau jika tipe lama bukan expense (jadi kategori lama tidak dihitung ulang).
        if (oldCategoryId !== newActualCategoryId || oldType !== 'expense') {
          try {
            await PlanController.recalculateForPlanByCategory(userId, newActualCategoryId);
            console.log(
              `Recalculated plan for new/current category ${newActualCategoryId} (due to transaction update ${transaction.id})`
            );
          } catch (recalcError) {
            console.error(
              `Error recalculating plan for new/current category ${newActualCategoryId} (transaction update):`,
              recalcError
            );
          }
        }
      }

      // Get category name for response (gunakan categoryId dari transaksi yang sudah diupdate)
      const category = await Category.findByPk(newActualCategoryId);

      res.json({
        status: "success",
        message: "Transaksi berhasil diperbarui",
        data: {
          ...transaction.toJSON(),
          categoryName: category ? category.name : null,
        },
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
      const userId = req.user.userId;

      const transaction = await Transaction.findOne({
        where: { id, userId },
      });

      if (!transaction) {
        return res.status(404).json({
          status: "error",
          message: "Transaksi tidak ditemukan",
        });
      }

      const categoryIdToRecalculate = transaction.categoryId;
      const typeOfDeletedTransaction = transaction.type;

      await transaction.destroy();

      // Jika transaksi yang dihapus adalah pengeluaran, recalculate plan terkait
      if (typeOfDeletedTransaction === "expense") {
        try {
          await PlanController.recalculateForPlanByCategory(userId, categoryIdToRecalculate);
          console.log(
            `Recalculated plan for category ${categoryIdToRecalculate} after transaction delete ${id}`
          );
        } catch (recalcError) {
          console.error(
            `Error recalculating plan for category ${categoryIdToRecalculate} after transaction delete:`,
            recalcError
          );
        }
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TransactionProvider>(context, listen: false)
          .loadTransactions();
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  void _showTransactionDialog(
    BuildContext context,
    TransactionProvider transactionProvider,
    CategoryProvider categoryProvider, {
    Transaction? transaction,
  }) {
    final amountController = TextEditingController(
      text: transaction?.amount.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: transaction?.description ?? '',
    );
    String selectedType = transaction?.type ?? 'expense';
    int? selectedCategoryId = transaction?.categoryId;
    DateTime selectedDate = transaction?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(transaction == null ? 'Tambah Transaksi' : 'Edit Transaksi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Jumlah harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipe',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'income',
                    child: Text('Pemasukan'),
                  ),
                  DropdownMenuItem(
                    value: 'expense',
                    child: Text('Pengeluaran'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                    selectedCategoryId = null;
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                ),
                items: categoryProvider.categories
                    .map((category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategoryId = value;
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Kategori harus dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Tanggal'),
                subtitle: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedCategoryId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kategori harus dipilih'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final amountText = amountController.text.replaceAll(',', '.');
              final amount = double.tryParse(amountText);
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jumlah harus berupa angka'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newTransaction = Transaction(
                id: transaction?.id ?? 0,
                amount: amount,
                type: selectedType,
                categoryId: selectedCategoryId!,
                description: descriptionController.text,
                date: selectedDate,
              );

              bool success;
              if (transaction == null) {
                success =
                    await transactionProvider.createTransaction(newTransaction);
              } else {
                success =
                    await transactionProvider.updateTransaction(newTransaction);
              }

              if (success && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(transaction == null ? 'Tambah' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      await provider.deleteTransaction(transaction.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
      ),
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, transactionProvider, categoryProvider, _) {
          if (transactionProvider.isLoading || categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transactionProvider.error != null) {
            return Center(
              child: Text(
                'Error: ${transactionProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (transactionProvider.transactions.isEmpty) {
            return const Center(
              child: Text('Belum ada transaksi'),
            );
          }

          return ListView.builder(
            itemCount: transactionProvider.transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactionProvider.transactions[index];
              return ListTile(
                leading: Icon(
                  transaction.type == 'income'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color:
                      transaction.type == 'income' ? Colors.green : Colors.red,
                ),
                title: Text(
                    categoryProvider.getCategoryName(transaction.categoryId)),
                subtitle: Text(transaction.description),
                trailing: Text(
                  'Rp ${transaction.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: transaction.type == 'income'
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _showTransactionDialog(
                  context,
                  transactionProvider,
                  categoryProvider,
                  transaction: transaction,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionDialog(
          context,
          Provider.of<TransactionProvider>(context, listen: false),
          Provider.of<CategoryProvider>(context, listen: false),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      Future.microtask(() {
        Provider.of<TransactionProvider>(context, listen: false)
            .loadTransactions();
        Provider.of<CategoryProvider>(context, listen: false).loadCategories();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _filterTransactions(
      List<Transaction> transactions, CategoryProvider categoryProvider) {
    if (_searchQuery.isEmpty) {
      return transactions;
    }

    return transactions.where((transaction) {
      final categoryName = categoryProvider
          .getCategoryName(transaction.categoryId)
          .toLowerCase();
      final description = transaction.description.toLowerCase();
      final amount = transaction.amount.toString();
      final searchLower = _searchQuery.toLowerCase();

      return categoryName.contains(searchLower) ||
          description.contains(searchLower) ||
          amount.contains(searchLower);
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari transaksi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: Consumer2<TransactionProvider, CategoryProvider>(
              builder: (context, transactionProvider, categoryProvider, _) {
                if (transactionProvider.isLoading ||
                    categoryProvider.isLoading) {
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

                final filteredTransactions = _filterTransactions(
                  transactionProvider.transactions,
                  categoryProvider,
                );

                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'Belum ada transaksi'
                          : 'Tidak ada transaksi yang ditemukan',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    return Dismissible(
                      key: Key(transaction.id.toString()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Hapus Transaksi'),
                                content: const Text(
                                    'Apakah Anda yakin ingin menghapus transaksi ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (direction) async {
                        try {
                          await transactionProvider
                              .deleteTransaction(transaction.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transaksi berhasil dihapus'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menghapus transaksi: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: ListTile(
                        leading: Icon(
                          transaction.type == 'income'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: transaction.type == 'income'
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(categoryProvider
                            .getCategoryName(transaction.categoryId)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(transaction.description),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMMM yyyy', 'id_ID')
                                  .format(transaction.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          'Rp ${NumberFormat('#,###').format(transaction.amount)}',
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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

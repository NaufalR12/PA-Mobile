import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/currency_provider.dart';
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
  String _selectedFilter = 'all'; // 'all', 'income', 'expense'
  String _selectedDateFilter = 'all'; // 'all', 'day', 'month', 'year'
  DateTime? _selectedDate;

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
    var filteredTransactions = transactions;

    // Filter berdasarkan tipe transaksi
    if (_selectedFilter != 'all') {
      filteredTransactions = filteredTransactions
          .where((transaction) => transaction.type == _selectedFilter)
          .toList();
    }

    // Filter berdasarkan tanggal
    if (_selectedDate != null && _selectedDateFilter != 'all') {
      filteredTransactions = filteredTransactions.where((transaction) {
        final transactionDate = transaction.date;
        switch (_selectedDateFilter) {
          case 'day':
            return transactionDate.year == _selectedDate!.year &&
                transactionDate.month == _selectedDate!.month &&
                transactionDate.day == _selectedDate!.day;
          case 'month':
            return transactionDate.year == _selectedDate!.year &&
                transactionDate.month == _selectedDate!.month;
          case 'year':
            return transactionDate.year == _selectedDate!.year;
          default:
            return true;
        }
      }).toList();
    }

    // Filter berdasarkan pencarian
    if (_searchQuery.isNotEmpty) {
      filteredTransactions = filteredTransactions.where((transaction) {
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

    return filteredTransactions;
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

  void _showFilterDialog() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final currentDay = now.day;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Transaksi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tipe Transaksi'),
                RadioListTile<String>(
                  title: const Text('Semua'),
                  value: 'all',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Pemasukan'),
                  value: 'income',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Pengeluaran'),
                  value: 'expense',
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
                const Divider(),
                const Text('Filter Tanggal'),
                RadioListTile<String>(
                  title: const Text('Semua'),
                  value: 'all',
                  groupValue: _selectedDateFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedDateFilter = value!;
                      _selectedDate = null;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Hari'),
                  value: 'day',
                  groupValue: _selectedDateFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedDateFilter = value!;
                      _selectedDate = DateTime.now();
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Bulan'),
                  value: 'month',
                  groupValue: _selectedDateFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedDateFilter = value!;
                      _selectedDate = DateTime.now();
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Tahun'),
                  value: 'year',
                  groupValue: _selectedDateFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedDateFilter = value!;
                      _selectedDate = DateTime.now();
                    });
                  },
                ),
                if (_selectedDateFilter != 'all')
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedDateFilter == 'day')
                          ListTile(
                            title: const Text('Pilih Tanggal'),
                            subtitle: Text(
                              _selectedDate != null
                                  ? DateFormat('dd MMMM yyyy', 'id_ID')
                                      .format(_selectedDate!)
                                  : 'Belum dipilih',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(
                                    currentYear, currentMonth, currentDay),
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedDate = date;
                                });
                              }
                            },
                          )
                        else if (_selectedDateFilter == 'month')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pilih Bulan'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value:
                                          _selectedDate?.month ?? currentMonth,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10),
                                      ),
                                      items: List.generate(12, (index) {
                                        final month = index + 1;
                                        // Jika tahun yang dipilih adalah tahun ini, batasi bulan yang bisa dipilih
                                        if (_selectedDate?.year ==
                                                currentYear &&
                                            month > currentMonth) {
                                          return DropdownMenuItem(
                                            value: month,
                                            child: Text(DateFormat(
                                                    'MMMM', 'id_ID')
                                                .format(DateTime(2024, month))),
                                            enabled: false,
                                          );
                                        }
                                        return DropdownMenuItem(
                                          value: month,
                                          child: Text(DateFormat(
                                                  'MMMM', 'id_ID')
                                              .format(DateTime(2024, month))),
                                        );
                                      }),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedDate = DateTime(
                                              _selectedDate?.year ??
                                                  currentYear,
                                              value,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: _selectedDate?.year ?? currentYear,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10),
                                      ),
                                      items: List.generate(5, (index) {
                                        final year = currentYear - index;
                                        return DropdownMenuItem(
                                          value: year,
                                          child: Text(year.toString()),
                                        );
                                      }),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedDate = DateTime(
                                              value,
                                              _selectedDate?.month ??
                                                  currentMonth,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else if (_selectedDateFilter == 'year')
                          TextFormField(
                            initialValue:
                                (_selectedDate?.year ?? currentYear).toString(),
                            decoration: const InputDecoration(
                              labelText: 'Pilih Tahun',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final year = int.tryParse(value);
                                if (year != null && year <= currentYear) {
                                  setState(() {
                                    _selectedDate = DateTime(year);
                                  });
                                }
                              }
                            },
                            onTap: () {
                              // Tampilkan dialog untuk memilih tahun
                              showDialog(
                                context: context,
                                builder: (context) => StatefulBuilder(
                                  builder: (context, setDialogState) =>
                                      AlertDialog(
                                    title: const Text('Pilih Tahun'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () {
                                                final currentYear =
                                                    _selectedDate?.year ??
                                                        DateTime.now().year;
                                                if (currentYear > 1900) {
                                                  setDialogState(() {
                                                    _selectedDate = DateTime(
                                                        currentYear - 1);
                                                  });
                                                }
                                              },
                                            ),
                                            Text(
                                              (_selectedDate?.year ??
                                                      DateTime.now().year)
                                                  .toString(),
                                              style:
                                                  const TextStyle(fontSize: 20),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () {
                                                final currentYear =
                                                    _selectedDate?.year ??
                                                        DateTime.now().year;
                                                if (currentYear <
                                                    DateTime.now().year) {
                                                  setDialogState(() {
                                                    _selectedDate = DateTime(
                                                        currentYear + 1);
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          this.setState(() {});
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Pilih'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
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
          if (_selectedFilter != 'all' || _selectedDateFilter != 'all')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      _selectedFilter == 'all'
                          ? 'Semua'
                          : _selectedFilter == 'income'
                              ? 'Pemasukan'
                              : 'Pengeluaran',
                    ),
                    backgroundColor: Colors.blue[100],
                  ),
                  const SizedBox(width: 8),
                  if (_selectedDateFilter != 'all')
                    Chip(
                      label: Text(
                        _selectedDateFilter == 'day'
                            ? DateFormat('dd MMMM yyyy', 'id_ID')
                                .format(_selectedDate!)
                            : _selectedDateFilter == 'month'
                                ? DateFormat('MMMM yyyy', 'id_ID')
                                    .format(_selectedDate!)
                                : DateFormat('yyyy', 'id_ID')
                                    .format(_selectedDate!),
                      ),
                      backgroundColor: Colors.green[100],
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'all';
                        _selectedDateFilter = 'all';
                        _selectedDate = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Reset Filter'),
                  ),
                ],
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
                      _searchQuery.isEmpty &&
                              _selectedFilter == 'all' &&
                              _selectedDateFilter == 'all'
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
                        trailing: FutureBuilder<String>(
                          future: Provider.of<CurrencyProvider>(context,
                                  listen: false)
                              .formatAmount(transaction.amount),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                snapshot.data!,
                                style: TextStyle(
                                  color: transaction.type == 'income'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                            return Text(
                              'Loading...',
                              style: TextStyle(
                                color: transaction.type == 'income'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
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

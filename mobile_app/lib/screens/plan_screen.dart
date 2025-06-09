import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/plan_provider.dart';
import '../providers/category_provider.dart';
import '../providers/currency_provider.dart';
import '../models/plan_model.dart';
import '../models/category_model.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  Category? _selectedCategory;
  Plan? _editingPlan;
  bool _isLoading = false;
  final Color kPrimaryColor = const Color(0xFF3383E2);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<PlanProvider>(context, listen: false).loadPlans();
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showPlanDialog({Plan? plan}) {
    if (plan != null) {
      _amountController.text = plan.amount.toString();
      _descriptionController.text = plan.description ?? '';
      _selectedCategory = Provider.of<CategoryProvider>(context, listen: false)
          .categories
          .firstWhere((c) => c.id == plan.categoryId);
      _editingPlan = plan;
    } else {
      _amountController.clear();
      _descriptionController.clear();
      _selectedCategory = null;
      _editingPlan = null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          plan == null ? 'Tambah Rencana' : 'Edit Rencana',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, _) {
                    return DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        labelStyle: TextStyle(color: kPrimaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: kPrimaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: kPrimaryColor, width: 2),
                        ),
                      ),
                      items: categoryProvider.categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Pilih kategori';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Jumlah',
                    labelStyle: TextStyle(color: kPrimaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: kPrimaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: kPrimaryColor, width: 2),
                    ),
                    prefixText: Provider.of<CurrencyProvider>(context)
                            .selectedCurrency
                            .symbol +
                        ' ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah tidak boleh kosong';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    labelStyle: TextStyle(color: kPrimaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: kPrimaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: kPrimaryColor, width: 2),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal', style: TextStyle(color: kPrimaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _handleSubmit,
            child: Text(
              plan == null ? 'Tambah' : 'Simpan',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    print('PlanScreen: Tombol submit ditekan');
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      print('PlanScreen: Form valid');
      print('PlanScreen: categoryId: ${_selectedCategory?.id}');
      print('PlanScreen: amount: ${_amountController.text}');
      print('PlanScreen: description: ${_descriptionController.text}');

      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        bool success;
        if (_editingPlan != null) {
          print('PlanScreen: Memperbarui rencana yang ada');
          print(
              'PlanScreen: ID rencana yang akan diupdate: ${_editingPlan!.id}');

          final updatedPlan = Plan(
            id: _editingPlan!.id,
            userId: _editingPlan!.userId,
            categoryId: _selectedCategory!.id,
            amount: double.parse(_amountController.text),
            remainingAmount: _editingPlan!.remainingAmount,
            description: _descriptionController.text,
            createdAt: _editingPlan!.createdAt,
            updatedAt: DateTime.now(),
          );

          print(
              'PlanScreen: Data rencana yang akan diupdate: ${updatedPlan.toJson()}');
          success = await Provider.of<PlanProvider>(context, listen: false)
              .updatePlan(updatedPlan);
        } else {
          print('PlanScreen: Membuat rencana baru');
          success = await Provider.of<PlanProvider>(context, listen: false)
              .createPlan(
            categoryId: _selectedCategory!.id,
            amount: double.parse(_amountController.text),
            description: _descriptionController.text,
          );
        }

        print('PlanScreen: Hasil operasi: $success');
        if (success) {
          print('PlanScreen: Operasi berhasil');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rencana berhasil disimpan')),
            );
            Navigator.pop(context);
          }
        } else {
          print('PlanScreen: Operasi gagal');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal menyimpan rencana')),
            );
          }
        }
      } catch (e) {
        print('PlanScreen: Error saat menyimpan rencana: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      print('PlanScreen: Form tidak valid atau kategori belum dipilih');
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
        );
      }
    }
  }

  void _confirmDeletePlan(int planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content:
            const Text('Apakah Anda yakin ingin menghapus perencanaan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: kPrimaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deletePlan(planId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlan(int planId) async {
    try {
      await context.read<PlanProvider>().deletePlan(planId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perencanaan berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus perencanaan: $e')),
        );
      }
    }
  }

  String getCategoryName(int categoryId) {
    final category = context.read<CategoryProvider>().categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () =>
              Category(id: 0, name: 'Kategori tidak ditemukan', userId: 0),
        );
    return category.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rencana',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: kPrimaryColor,
      ),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, _) {
          if (planProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (planProvider.error != null) {
            return Center(
              child: Text(
                'Error: ${planProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (planProvider.plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: kPrimaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada rencana',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: planProvider.plans.length,
            itemBuilder: (context, index) {
              final plan = planProvider.plans[index];
              final category =
                  Provider.of<CategoryProvider>(context, listen: false)
                      .categories
                      .firstWhere((c) => c.id == plan.categoryId);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Dismissible(
                  key: Key(plan.id.toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Hapus Rencana'),
                            content: const Text(
                                'Apakah Anda yakin ingin menghapus rencana ini?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Batal',
                                    style: TextStyle(color: kPrimaryColor)),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Hapus',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (direction) async {
                    try {
                      await planProvider.deletePlan(plan.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rencana berhasil dihapus'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal menghapus rencana: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: kPrimaryColor.withOpacity(0.15),
                              child: Icon(Icons.category, color: kPrimaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                getCategoryName(plan.categoryId),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: kPrimaryColor),
                              onPressed: () => _showPlanDialog(plan: plan),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<String>(
                          future: Provider.of<CurrencyProvider>(context,
                                  listen: false)
                              .formatAmount(plan.amount),
                          builder: (context, snapshot) {
                            return Text(
                              'Jumlah: ${snapshot.data ?? 'Loading...'}',
                              style: const TextStyle(fontSize: 14),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<String>(
                          future: Provider.of<CurrencyProvider>(context,
                                  listen: false)
                              .formatAmount(plan.remainingAmount),
                          builder: (context, snapshot) {
                            return Text(
                              'Sisa: ${snapshot.data ?? 'Loading...'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: plan.remainingAmount > 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        if (plan.description != null &&
                            plan.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Deskripsi: ${plan.description}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: plan.amount > 0
                              ? (plan.amount - plan.remainingAmount) /
                                  plan.amount
                              : 0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            plan.remainingAmount > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Penggunaan: ${((plan.amount - plan.remainingAmount) / plan.amount * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: plan.remainingAmount > 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        onPressed: () => _showPlanDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

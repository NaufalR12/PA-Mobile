import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../models/category_model.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  void _showCategoryDialog({
    Category? category,
  }) {
    final nameController = TextEditingController(
      text: category?.name ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nama kategori tidak boleh kosong';
            }
            return null;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nama kategori tidak boleh kosong'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final categoryProvider =
                  Provider.of<CategoryProvider>(context, listen: false);
              bool success;

              if (category == null) {
                success =
                    await categoryProvider.createCategory(nameController.text);
              } else {
                success = await categoryProvider.updateCategory(
                  Category(
                    id: category.id,
                    name: nameController.text,
                    userId: category.userId,
                    createdAt: category.createdAt,
                  ),
                );
              }

              if (success && context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      category == null
                          ? 'Kategori berhasil ditambahkan'
                          : 'Kategori berhasil diperbarui',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(category == null ? 'Tambah' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, _) {
          if (categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryProvider.error != null) {
            return Center(
              child: Text(
                'Error: ${categoryProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (categoryProvider.categories.isEmpty) {
            return const Center(
              child: Text('Belum ada kategori'),
            );
          }

          return ListView.builder(
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              return Dismissible(
                key: Key(category.id.toString()),
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
                          title: const Text('Hapus Kategori'),
                          content: const Text(
                              'Apakah Anda yakin ingin menghapus kategori ini?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
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
                    await categoryProvider.deleteCategory(category.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kategori berhasil dihapus'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menghapus kategori: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(category.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showCategoryDialog(category: category),
                  ),
                  onTap: () => _showCategoryDialog(category: category),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

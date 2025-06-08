import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';
import 'map_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false)
          .loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final user = authProvider.user;
    final transactions = transactionProvider.transactions;
    final isLoading = transactionProvider.isLoading;

    // Filter transaksi bulan ini
    final month = selectedDate.month;
    final year = selectedDate.year;
    final monthTransactions = transactions
        .where((t) => t.date.month == month && t.date.year == year)
        .toList();

    // Hitung income, expense, saldo
    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in monthTransactions) {
      if (t.type == 'income') {
        totalIncome += t.amount;
      } else if (t.type == 'expense') {
        totalExpense += t.amount;
      }
    }
    double saldo = totalIncome - totalExpense;

    // Format currency
    String formatCurrency(double value) {
      final formatter =
          NumberFormat.currency(locale: 'id', symbol: 'IDR ', decimalDigits: 0);
      return formatter.format(value);
    }

    // Widget foto profil
    Widget profilePhoto() {
      if (user?.fotoProfil != null && user!.fotoProfil!.isNotEmpty) {
        return CircleAvatar(
          radius: 22,
          backgroundImage: NetworkImage(user.fotoProfil!),
        );
      } else {
        return const CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: Colors.grey, size: 28),
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3383E2),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Montrack',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Spacer(),
            if (user != null) profilePhoto(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await Provider.of<TransactionProvider>(context, listen: false)
                    .loadTransactions();
              },
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    color: const Color(0xFF3383E2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user != null)
                          Text(
                            user.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          formatCurrency(saldo),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Main Wallet',
                                style: TextStyle(color: Colors.white70)),
                            const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white70),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: const Color(0xFFF5F7FA),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Summary',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            DropdownButton<DateTime>(
                              value: selectedDate,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: List.generate(12, (i) {
                                final date = DateTime(year, i + 1);
                                return DropdownMenuItem(
                                  value: DateTime(year, i + 1),
                                  child: Text(DateFormat('MMMM').format(date)),
                                );
                              }),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedDate = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _summaryCard(
                              icon: '🤑',
                              title: 'Income',
                              value: formatCurrency(totalIncome),
                              color: Colors.green.shade50,
                              textColor: Colors.green.shade800,
                            ),
                            const SizedBox(width: 12),
                            _summaryCard(
                              icon: '💸',
                              title: 'Expense',
                              value: formatCurrency(totalExpense),
                              color: Colors.red.shade50,
                              textColor: Colors.red.shade800,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                icon: '👜',
                                title: 'Pockets',
                                value: '7 Pockets',
                                color: Colors.brown.shade50,
                                textColor: Colors.brown.shade800,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const MapScreen()),
                                  );
                                },
                                child: _summaryCard(
                                  icon: '🏦',
                                  title: 'Bank & ATM',
                                  value: 'Terdekat',
                                  color: Colors.blue.shade50,
                                  textColor: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: const [
                        Text('Recent Transaction',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Spacer(),
                        Text('All', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                  ...monthTransactions
                      .take(5)
                      .map((t) => _transactionTile(t))
                      .toList(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard({
    required String icon,
    required String title,
    required String value,
    required Color color,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(fontSize: 13, color: textColor)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _transactionTile(Transaction t) {
    final isExpense = t.type == 'expense';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(isExpense ? Icons.arrow_downward : Icons.arrow_upward,
              color: isExpense ? Colors.red : Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.description,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(DateFormat('dd/MM/yy').format(t.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            (isExpense ? '- ' : '+ ') +
                NumberFormat.currency(
                        locale: 'id', symbol: 'IDR ', decimalDigits: 0)
                    .format(t.amount),
            style: TextStyle(
              color: isExpense ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

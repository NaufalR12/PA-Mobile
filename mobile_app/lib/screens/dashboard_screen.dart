import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/plan_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/currency_selector.dart';
import '../widgets/timezone_selector.dart';
import 'login_screen.dart';
import 'transaction_screen.dart';
import 'package:intl/intl.dart';
import 'map_screen.dart';
import '../providers/timezone_provider.dart';

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
    final currencyProvider = Provider.of<CurrencyProvider>(context);
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
            const CurrencySelector(),
            const SizedBox(width: 8),
            const TimeZoneSelector(),
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
                        FutureBuilder<String>(
                          future: currencyProvider.formatAmount(saldo),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                snapshot.data!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold),
                              );
                            }
                            return const Text(
                              'Loading...',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold),
                            );
                          },
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
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('🤑',
                                            style: TextStyle(fontSize: 24)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Income',
                                          style: TextStyle(
                                            color: Colors.green.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        FutureBuilder<String>(
                                          future: currencyProvider
                                              .formatAmount(totalIncome),
                                          builder: (context, snapshot) {
                                            return Text(
                                              snapshot.data ?? 'Loading...',
                                              style: TextStyle(
                                                color: Colors.green.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('💸',
                                            style: TextStyle(fontSize: 24)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Expense',
                                          style: TextStyle(
                                            color: Colors.red.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        FutureBuilder<String>(
                                          future: currencyProvider
                                              .formatAmount(totalExpense),
                                          builder: (context, snapshot) {
                                            return Text(
                                              snapshot.data ?? 'Loading...',
                                              style: TextStyle(
                                                color: Colors.red.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/plan');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.brown.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('📋',
                                              style: TextStyle(fontSize: 24)),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Rencana',
                                            style: TextStyle(
                                              color: Colors.brown.shade800,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Consumer<PlanProvider>(
                                            builder:
                                                (context, planProvider, _) {
                                              return Text(
                                                '${planProvider.plans.length} Rencana',
                                                style: TextStyle(
                                                  color: Colors.brown.shade800,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
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
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('🏦',
                                              style: TextStyle(fontSize: 24)),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Bank & ATM',
                                            style: TextStyle(
                                              color: Colors.blue.shade800,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Terdekat',
                                            style: TextStyle(
                                              color: Colors.blue.shade800,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                      children: [
                        const Text('Recent Transaction',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TransactionScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'All',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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
    required Widget value,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
  }

  Widget _transactionTile(Transaction t) {
    final isExpense = t.type == 'expense';
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final timeZoneProvider = Provider.of<TimeZoneProvider>(context);
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
                Text(
                  timeZoneProvider.format(t.date, pattern: 'dd/MM/yy HH:mm'),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          FutureBuilder<String>(
            future: currencyProvider.formatAmount(t.amount),
            builder: (context, snapshot) {
              return Text(
                (isExpense ? '- ' : '+ ') + (snapshot.data ?? 'Loading...'),
                style: TextStyle(
                  color: isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

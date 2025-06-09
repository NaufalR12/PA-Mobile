import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'transaction_screen.dart';
import 'category_screen.dart';
import 'plan_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final Color kPrimaryColor = const Color(0xFF3383E2);

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionScreen(),
    const CategoryScreen(),
    const PlanScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            selectedItemColor: kPrimaryColor,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.dashboard,
                  color: _selectedIndex == 0 ? kPrimaryColor : Colors.grey,
                ),
                activeIcon: Icon(
                  Icons.dashboard,
                  color: kPrimaryColor,
                ),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.receipt_long,
                  color: _selectedIndex == 1 ? kPrimaryColor : Colors.grey,
                ),
                activeIcon: Icon(
                  Icons.receipt_long,
                  color: kPrimaryColor,
                ),
                label: 'Transaksi',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.category,
                  color: _selectedIndex == 2 ? kPrimaryColor : Colors.grey,
                ),
                activeIcon: Icon(
                  Icons.category,
                  color: kPrimaryColor,
                ),
                label: 'Kategori',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.calendar_today,
                  color: _selectedIndex == 3 ? kPrimaryColor : Colors.grey,
                ),
                activeIcon: Icon(
                  Icons.calendar_today,
                  color: kPrimaryColor,
                ),
                label: 'Rencana',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.person,
                  color: _selectedIndex == 4 ? kPrimaryColor : Colors.grey,
                ),
                activeIcon: Icon(
                  Icons.person,
                  color: kPrimaryColor,
                ),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

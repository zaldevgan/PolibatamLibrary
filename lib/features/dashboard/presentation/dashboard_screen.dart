import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../catalog/presentation/catalog_screen.dart';
import '../../repository/presentation/repository_screen.dart';
import '../../loans/presentation/my_loans_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CatalogScreen(),
    RepositoryScreen(),
    MyLoansScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book, color: AppTheme.primaryBlue),
            label: 'E-Book',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school, color: AppTheme.primaryBlue),
            label: 'Repository',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled, color: AppTheme.primaryBlue),
            label: 'Pinjaman',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryBlue),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}


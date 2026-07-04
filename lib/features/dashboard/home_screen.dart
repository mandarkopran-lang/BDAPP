import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_provider.dart';
import '../../core/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../breakdown/screens/breakdown_list_screen.dart';
import '../admin/screens/admin_dashboard_screen.dart';

/// Root authenticated screen. Admins see the Admin Dashboard directly;
/// all other roles land on the Breakdown list (their day-to-day workspace).
/// A bottom nav lets Admin/Manager switch between Breakdowns and Admin tools.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.currentUserProfile?.role ?? UserRole.user;
    final canSeeAdminTab = role == UserRole.admin || role == UserRole.manager;

    final pages = <Widget>[
      const BreakdownListScreen(embedded: true),
      if (canSeeAdminTab) const AdminDashboardScreen(embedded: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Breakdown Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.accent,
              onPressed: () => context.push('/breakdowns/create'),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: canSeeAdminTab
          ? NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.build_outlined),
                  selectedIcon: Icon(Icons.build),
                  label: 'Breakdowns',
                ),
                NavigationDestination(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  selectedIcon: Icon(Icons.admin_panel_settings),
                  label: 'Admin',
                ),
              ],
            )
          : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  final bool embedded;
  const AdminDashboardScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.currentUserProfile;
    final isAdmin = auth.isAdmin;

    final tiles = <_AdminTile>[
      if (isAdmin)
        _AdminTile(
          icon: Icons.corporate_fare,
          label: 'Companies',
          subtitle: 'Create & manage companies',
          onTap: () => context.push('/admin/companies'),
        ),
      _AdminTile(
        icon: Icons.account_tree_outlined,
        label: 'Departments & Plants',
        subtitle: 'Manage org structure',
        onTap: () => context.push('/admin/departments-plants'),
      ),
      _AdminTile(
        icon: Icons.people_outline,
        label: 'Users & Roles',
        subtitle: 'Assign roles to team members',
        onTap: () => context.push('/admin/users'),
      ),
    ];

    final content = GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.05,
      children: tiles,
    );

    if (embedded) return content;

    return Scaffold(
      appBar: AppBar(title: Text('Admin — ${profile?.name ?? ''}')),
      body: content,
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
              ),
              const Spacer(),
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

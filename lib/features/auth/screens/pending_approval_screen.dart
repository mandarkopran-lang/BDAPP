import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

/// Shown to authenticated users who are not yet linked to a company.
/// An Admin must assign them a company + role from the User Management
/// screen before they can access the rest of the app.
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final phone = authProvider.currentUserProfile?.phoneNumber ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top, size: 72, color: AppColors.warning),
                const SizedBox(height: 20),
                const Text(
                  'Awaiting Approval',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account ($phone) has been created but not yet '
                  'assigned to a company. Please contact your company '
                  'Admin to get access.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  label: 'Sign Out',
                  color: AppColors.danger,
                  onPressed: () => authProvider.signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

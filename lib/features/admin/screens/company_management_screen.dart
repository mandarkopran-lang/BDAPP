import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/company_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_widget.dart';

/// Only Admins can create new companies. When a company is created, the
/// creating admin is auto-assigned as its owner/admin (companyId set on
/// their own user doc) so they land in that tenant immediately.
class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  State<CompanyManagementScreen> createState() => _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  final _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  bool _isCreating = false;

  Future<void> _createCompany() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isCreating = true);

    final auth = context.read<AuthProvider>();
    final uid = auth.firebaseUser!.uid;

    try {
      final company = CompanyModel(
        id: '',
        name: name,
        ownerId: uid,
        createdAt: DateTime.now(),
      );
      final companyId = await _firestoreService.createCompany(company);

      // Auto-link the creating admin to this new company as its admin.
      await _firestoreService.assignUserToCompany(
        uid: uid,
        companyId: companyId,
        role: UserRole.admin,
      );

      _nameController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Company',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CustomTextField(controller: _nameController, label: 'Company Name'),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Create Company',
              isLoading: _isCreating,
              onPressed: () async {
                await _createCompany();
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Companies')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<CompanyModel>>(
        stream: _firestoreService.streamAllCompanies(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingWidget();
          final companies = snapshot.data!;
          if (companies.isEmpty) {
            return const EmptyStateWidget(
              message: 'No companies yet. Tap + to create one.',
              icon: Icons.corporate_fare,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: companies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final company = companies[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  title: Text(company.name),
                  subtitle: Text(
                    company.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: company.isActive ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

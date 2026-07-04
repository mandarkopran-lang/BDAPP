import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_widget.dart';

/// Admins/Managers use this screen to:
///  - See all users currently in their company
///  - Search & invite an existing (already-registered) phone number into
///    their company with a chosen role
///  - Change a user's role
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _firestoreService = FirestoreService();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.user;
  bool _isInviting = false;

  String? get _companyId =>
      context.read<AuthProvider>().currentUserProfile?.companyId;

  Future<void> _inviteUser() async {
    final companyId = _companyId;
    final phone = _phoneController.text.trim();
    if (companyId == null || phone.isEmpty) return;

    setState(() => _isInviting = true);
    try {
      final fullPhone = phone.startsWith('+') ? phone : '+91$phone';
      final user = await _firestoreService.findUserByPhone(fullPhone);
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No user found with this number. Ask them to sign up first via OTP login.'),
          ));
        }
        return;
      }
      await _firestoreService.assignUserToCompany(
        uid: user.uid,
        companyId: companyId,
        role: _selectedRole,
      );
      _phoneController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added to company')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  void _showInviteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
              const Text('Add User to Company',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '9876543210',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              const Text('Role', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: UserRole.values.map((role) {
                  final selected = _selectedRole == role;
                  return ChoiceChip(
                    label: Text(role.name),
                    selected: selected,
                    onSelected: (_) {
                      setModalState(() => _selectedRole = role);
                      setState(() => _selectedRole = role);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: 'Add to Company',
                isLoading: _isInviting,
                onPressed: () async {
                  await _inviteUser();
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyId = _companyId;
    if (companyId == null) {
      return const Scaffold(
        body: Center(child: Text('No company assigned to your account.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Users & Roles')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInviteSheet,
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.streamCompanyUsers(companyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingWidget();
          final users = snapshot.data!;
          if (users.isEmpty) {
            return const EmptyStateWidget(message: 'No users in this company yet.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final user = users[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.phoneNumber),
                  trailing: DropdownButton<UserRole>(
                    value: user.role,
                    underline: const SizedBox(),
                    items: UserRole.values
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                        .toList(),
                    onChanged: (newRole) {
                      if (newRole == null) return;
                      _firestoreService.assignUserToCompany(
                        uid: user.uid,
                        companyId: companyId,
                        role: newRole,
                      );
                    },
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

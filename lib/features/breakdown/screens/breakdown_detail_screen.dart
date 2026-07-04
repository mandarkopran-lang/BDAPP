import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/breakdown_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/custom_button.dart';

class BreakdownDetailScreen extends StatefulWidget {
  final String breakdownId;
  const BreakdownDetailScreen({super.key, required this.breakdownId});

  @override
  State<BreakdownDetailScreen> createState() => _BreakdownDetailScreenState();
}

class _BreakdownDetailScreenState extends State<BreakdownDetailScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.currentUserProfile;
    final companyId = profile?.companyId;

    if (companyId == null) {
      return const Scaffold(body: Center(child: Text('No company assigned.')));
    }

    final canManage = profile!.role == UserRole.admin ||
        profile.role == UserRole.manager ||
        profile.role == UserRole.supervisor;

    return Scaffold(
      appBar: AppBar(title: const Text('Breakdown Details')),
      body: StreamBuilder<BreakdownModel?>(
        stream: _firestoreService.streamBreakdown(companyId, widget.breakdownId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingWidget();
          final breakdown = snapshot.data;
          if (breakdown == null) {
            return const Center(child: Text('Breakdown not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      breakdown.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  StatusBadge(status: breakdownStatusToString(breakdown.status)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Reported ${DateFormat('dd MMM yyyy, hh:mm a').format(breakdown.createdAt)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(breakdown.description),
                      const SizedBox(height: 10),
                      Text('Priority: ${breakdown.priority.name}',
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              if (breakdown.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: breakdown.imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        breakdown.imageUrls[i],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (canManage) _buildManagementActions(breakdown, companyId, profile),
              const SizedBox(height: 20),
              const Text('Status History', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...breakdown.statusHistory.reversed.map((h) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.timeline, size: 18),
                    title: Text(h['status']?.toString() ?? ''),
                    subtitle: Text(h['note']?.toString() ?? ''),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildManagementActions(
      BreakdownModel breakdown, String companyId, UserModel profile) {
    return Card(
      color: AppColors.primary.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BreakdownStatus.values.map((status) {
                return OutlinedButton(
                  onPressed: breakdown.status == status
                      ? null
                      : () => _firestoreService.updateBreakdownStatus(
                            companyId: companyId,
                            breakdownId: breakdown.id,
                            status: status,
                            updatedBy: profile.uid,
                          ),
                  child: Text(status.name),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            if (breakdown.assignedTo == null)
              CustomButton(
                label: 'Assign to Me',
                onPressed: () => _firestoreService.assignBreakdown(
                  companyId: companyId,
                  breakdownId: breakdown.id,
                  assignedTo: profile.uid,
                  assignedBy: profile.uid,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

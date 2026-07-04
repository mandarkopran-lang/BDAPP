import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/breakdown_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';

class BreakdownListScreen extends StatefulWidget {
  final bool embedded;
  const BreakdownListScreen({super.key, this.embedded = false});

  @override
  State<BreakdownListScreen> createState() => _BreakdownListScreenState();
}

class _BreakdownListScreenState extends State<BreakdownListScreen> {
  final _firestoreService = FirestoreService();
  BreakdownStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.currentUserProfile;
    final companyId = profile?.companyId;

    if (companyId == null) {
      return const Center(child: Text('No company assigned.'));
    }

    // Regular "user" role only sees breakdowns assigned to them or reported
    // by them; Admin/Manager/Supervisor see the full company feed.
    final restrictToSelf = profile!.role == UserRole.user;

    final content = Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: StreamBuilder<List<BreakdownModel>>(
            stream: _firestoreService.streamBreakdowns(
              companyId,
              status: _filterStatus,
              assignedTo: restrictToSelf ? profile.uid : null,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LoadingWidget();
              final breakdowns = snapshot.data!;
              if (breakdowns.isEmpty) {
                return const EmptyStateWidget(
                  message: 'No breakdowns reported yet.',
                  icon: Icons.build_circle_outlined,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: breakdowns.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _BreakdownCard(
                  breakdown: breakdowns[i],
                  onTap: () => context.push('/breakdowns/${breakdowns[i].id}'),
                ),
              );
            },
          ),
        ),
      ],
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Breakdowns')),
      body: content,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/breakdowns/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _chip('All', null),
          _chip('Open', BreakdownStatus.open),
          _chip('Assigned', BreakdownStatus.assigned),
          _chip('In Progress', BreakdownStatus.inProgress),
          _chip('Resolved', BreakdownStatus.resolved),
          _chip('Closed', BreakdownStatus.closed),
        ],
      ),
    );
  }

  Widget _chip(String label, BreakdownStatus? status) {
    final selected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filterStatus = status),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final BreakdownModel breakdown;
  final VoidCallback onTap;

  const _BreakdownCard({required this.breakdown, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (breakdown.imageUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    breakdown.imageUrls.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.build, color: AppColors.primary),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      breakdown.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(breakdown.createdAt),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: breakdownStatusToString(breakdown.status)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

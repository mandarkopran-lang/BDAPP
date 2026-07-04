import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/department_model.dart';
import '../../../core/models/plant_model.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/loading_widget.dart';

class DepartmentPlantScreen extends StatefulWidget {
  const DepartmentPlantScreen({super.key});

  @override
  State<DepartmentPlantScreen> createState() => _DepartmentPlantScreenState();
}

class _DepartmentPlantScreenState extends State<DepartmentPlantScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? get _companyId =>
      context.read<AuthProvider>().currentUserProfile?.companyId;

  void _addDepartment() {
    final companyId = _companyId;
    if (companyId == null) return;
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            const Text('New Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            CustomTextField(controller: controller, label: 'Department Name'),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Add',
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                await _firestoreService.createDepartment(DepartmentModel(
                  id: '',
                  companyId: companyId,
                  name: controller.text.trim(),
                  createdAt: DateTime.now(),
                ));
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addPlant() {
    final companyId = _companyId;
    if (companyId == null) return;
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            const Text('New Plant / Machine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            CustomTextField(controller: nameController, label: 'Plant Name'),
            const SizedBox(height: 12),
            CustomTextField(controller: locationController, label: 'Location'),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Add',
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await _firestoreService.createPlant(PlantModel(
                  id: '',
                  companyId: companyId,
                  name: nameController.text.trim(),
                  location: locationController.text.trim(),
                  createdAt: DateTime.now(),
                ));
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
    final companyId = _companyId;
    if (companyId == null) {
      return const Scaffold(
        body: Center(child: Text('No company assigned to your account.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments & Plants'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Departments'), Tab(text: 'Plants')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _tabController.index == 0 ? _addDepartment() : _addPlant(),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<List<DepartmentModel>>(
            stream: _firestoreService.streamDepartments(companyId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LoadingWidget();
              final departments = snapshot.data!;
              if (departments.isEmpty) {
                return const EmptyStateWidget(message: 'No departments yet.');
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: departments.length,
                itemBuilder: (context, i) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_tree_outlined),
                    title: Text(departments[i].name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _firestoreService.deleteDepartment(
                          companyId, departments[i].id),
                    ),
                  ),
                ),
              );
            },
          ),
          StreamBuilder<List<PlantModel>>(
            stream: _firestoreService.streamPlants(companyId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LoadingWidget();
              final plants = snapshot.data!;
              if (plants.isEmpty) {
                return const EmptyStateWidget(message: 'No plants yet.');
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: plants.length,
                itemBuilder: (context, i) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.precision_manufacturing_outlined),
                    title: Text(plants[i].name),
                    subtitle: Text(plants[i].location ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          _firestoreService.deletePlant(companyId, plants[i].id),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

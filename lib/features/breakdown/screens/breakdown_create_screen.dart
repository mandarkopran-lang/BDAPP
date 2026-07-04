import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/breakdown_model.dart';
import '../../../core/models/plant_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class BreakdownCreateScreen extends StatefulWidget {
  const BreakdownCreateScreen({super.key});

  @override
  State<BreakdownCreateScreen> createState() => _BreakdownCreateScreenState();
}

class _BreakdownCreateScreenState extends State<BreakdownCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  String? _selectedPlantId;
  BreakdownPriority _priority = BreakdownPriority.medium;
  final List<File> _images = [];
  bool _isSubmitting = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlantId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a plant/machine')));
      return;
    }

    final auth = context.read<AuthProvider>();
    final profile = auth.currentUserProfile!;
    final companyId = profile.companyId!;

    setState(() => _isSubmitting = true);
    try {
      final breakdown = BreakdownModel(
        id: '',
        companyId: companyId,
        plantId: _selectedPlantId!,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        reportedBy: profile.uid,
        createdAt: DateTime.now(),
      );
      final breakdownId = await _firestoreService.createBreakdown(breakdown);

      if (_images.isNotEmpty) {
        final urls = await _storageService.uploadMultiple(
          companyId: companyId,
          breakdownId: breakdownId,
          files: _images,
        );
        await _firestoreService.addBreakdownImages(
          companyId: companyId,
          breakdownId: breakdownId,
          imageUrls: urls,
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to report: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyId = context.read<AuthProvider>().currentUserProfile?.companyId;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Breakdown')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CustomTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'e.g. Motor overheating',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _descController,
                label: 'Description',
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 14),
              if (companyId != null)
                StreamBuilder<List<PlantModel>>(
                  stream: _firestoreService.streamPlants(companyId),
                  builder: (context, snapshot) {
                    final plants = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      value: _selectedPlantId,
                      decoration: const InputDecoration(labelText: 'Plant / Machine'),
                      items: plants
                          .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPlantId = v),
                    );
                  },
                ),
              const SizedBox(height: 14),
              const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: BreakdownPriority.values.map((p) {
                  return ChoiceChip(
                    label: Text(p.name),
                    selected: _priority == p,
                    onSelected: (_) => setState(() => _priority = p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              const Text('Photos', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._images.map((file) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                      )),
                  InkWell(
                    onTap: () => _showImageSourceSheet(),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              CustomButton(
                label: 'Submit Breakdown',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

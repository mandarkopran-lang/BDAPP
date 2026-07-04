import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Handles uploading breakdown images to Firebase Storage.
/// Storage path convention keeps company data isolated:
///   companies/{companyId}/breakdowns/{breakdownId}/{uuid}.jpg
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadBreakdownImage({
    required String companyId,
    required String breakdownId,
    required File file,
  }) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage
        .ref()
        .child('companies/$companyId/breakdowns/$breakdownId/$fileName');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'companyId': companyId, 'breakdownId': breakdownId},
    );

    final uploadTask = await ref.putFile(file, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<List<String>> uploadMultiple({
    required String companyId,
    required String breakdownId,
    required List<File> files,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadBreakdownImage(
        companyId: companyId,
        breakdownId: breakdownId,
        file: file,
      );
      urls.add(url);
    }
    return urls;
  }

  Future<void> deleteImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {
      // Ignore if already deleted / permission edge-case.
    }
  }
}

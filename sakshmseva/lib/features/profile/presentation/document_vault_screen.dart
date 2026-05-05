import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

final documentsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('documents')
      .orderBy('uploadedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList());
});

class DocumentVaultScreen extends ConsumerStatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  ConsumerState<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends ConsumerState<DocumentVaultScreen> {
  bool _isUploading = false;

  Future<void> _uploadDocument() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      
      // Case-insensitive PDF validation
      if (!file.name.toLowerCase().endsWith('.pdf')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid file type. Only PDF files are allowed.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setState(() => _isUploading = true);

      final uid = user.uid;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/$uid/documents/$fileName');

      // Upload file depending on platform (Web uses bytes, Mobile uses path)
      if (file.bytes != null) {
        await storageRef.putData(
            file.bytes!, SettableMetadata(contentType: 'application/pdf'));
      } else if (file.path != null) {
        await storageRef.putFile(
            File(file.path!), SettableMetadata(contentType: 'application/pdf'));
      } else {
        throw Exception("Could not read file data.");
      }

      final downloadUrl = await storageRef.getDownloadURL();

      // Save metadata to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('documents')
          .add({
        'fileName': file.name,
        'url': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title: const Text('Document Vault'),
      ),
      body: docsAsync.when(
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No documents uploaded yet', style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreenSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: AppColors.primaryGreen),
                  ),
                  title: Text(doc['fileName'] ?? 'Document', style: AppTextStyles.titleMedium),
                  subtitle: Text(
                    doc['uploadedAt'] != null
                        ? 'Uploaded on ${(doc['uploadedAt'] as Timestamp).toDate().toString().split(' ')[0]}'
                        : 'Uploading...',
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download_rounded, color: AppColors.primaryGreen),
                    onPressed: () async {
                      if (doc['url'] != null) {
                        final url = Uri.parse(doc['url']);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadDocument,
        backgroundColor: AppColors.primaryGreen,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.upload_file),
        label: Text(_isUploading ? 'Uploading...' : 'Upload PDF'),
      ),
    );
  }
}

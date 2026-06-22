import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class AdminLeadDetailsScreen extends ConsumerStatefulWidget {
  final Lead lead;
  const AdminLeadDetailsScreen({Key? key, required this.lead}) : super(key: key);

  @override
  ConsumerState<AdminLeadDetailsScreen> createState() => _AdminLeadDetailsScreenState();
}

class _AdminLeadDetailsScreenState extends ConsumerState<AdminLeadDetailsScreen> {
  bool _isUploading = false;
  List<LeadDocument> _documents = [];
  bool _isLoadingDocs = true;

  @override
  void initState() {
    super.initState();
    _fetchDocs();
  }

  Future<void> _fetchDocs() async {
    try {
      final docs = await ref.read(adminServiceProvider).fetchLeadDocuments(widget.lead.id);
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoadingDocs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDocs = false);
    }
  }

  Future<void> _uploadDoc(String docType) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom, 
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );
      
      if (result != null && result.files.single.bytes != null) {
        setState(() => _isUploading = true);
        try {
          final fileName = '${docType}_${DateTime.now().millisecondsSinceEpoch}.${result.files.single.extension}';
          await ref.read(adminServiceProvider).uploadLeadDocument(
                widget.lead.id,
                docType,
                fileName,
                result.files.single.bytes!,
              );
          await _fetchDocs();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$docType uploaded successfully!')));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading: $e')));
        } finally {
          if (mounted) setState(() => _isUploading = false);
        }
      } else if (result != null) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read file data. Try another file.')));
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File picker error: $e')));
    }
  }

  bool _hasDocType(String type) => _documents.any((d) => d.documentType == type);

  @override
  Widget build(BuildContext context) {
    final requiredDocs = ['Electricity Bill', 'Owner Aadhaar', 'Owner PAN', 'Tenant Aadhaar', 'Tenant PAN', 'Witness 1 Aadhaar', 'Witness 2 Aadhaar'];
    final allCollected = requiredDocs.every((doc) => _hasDocType(doc));

    return Scaffold(
      appBar: AppBar(
        title: Text('Lead: ${widget.lead.clientName}'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: Row(
        children: [
          // Left Sidebar: Lead Info & Status
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Client: ${widget.lead.clientName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Phone: ${widget.lead.phone}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Property: ${widget.lead.propertyAddress}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  const Text('Current Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Chip(
                    label: Text(widget.lead.status, style: const TextStyle(color: Colors.white)),
                    backgroundColor: widget.lead.status == 'New' ? Colors.orange : Colors.green,
                  ),
                  const Spacer(),
                  if (allCollected)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_document),
                        label: const Text('Draft Agreement'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(16)),
                        onPressed: () async {
                          // Update lead status to drafted
                          await ref.read(adminServiceProvider).updateLeadStatus(widget.lead.id, 'Drafted');
                          if (context.mounted) {
                            context.push('/admin/agreement/new', extra: {'lead': widget.lead});
                          }
                        },
                      ),
                    )
                  else
                    const Text('Collect all required documents to draft agreement.', style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
          // Right Panel: Document Collection
          Expanded(
            flex: 3,
            child: _isLoadingDocs
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Text('Required Documents', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (_isUploading) const LinearProgressIndicator(),
                      const SizedBox(height: 16),
                      ...requiredDocs.map((docType) {
                        final isUploaded = _hasDocType(docType);
                        final doc = isUploaded ? _documents.firstWhere((d) => d.documentType == docType) : null;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              isUploaded ? Icons.check_circle : Icons.upload_file,
                              color: isUploaded ? Colors.green : Colors.grey,
                              size: 32,
                            ),
                            title: Text(docType, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(isUploaded ? 'Uploaded on ${doc!.createdAt.toLocal().toString().split(' ')[0]}' : 'Pending Upload'),
                            trailing: isUploaded
                                ? TextButton.icon(
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('View'),
                                    onPressed: () async {
                                      final uri = Uri.parse(doc!.fileUrl);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                                  )
                                : ElevatedButton(
                                    onPressed: _isUploading ? null : () => _uploadDoc(docType),
                                    child: const Text('Upload'),
                                  ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

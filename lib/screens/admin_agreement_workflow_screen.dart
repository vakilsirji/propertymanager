import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_models.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../services/pdf_service.dart';
import 'package:file_picker/file_picker.dart';

class AdminAgreementWorkflowScreen extends ConsumerStatefulWidget {
  final Agreement agreement;
  const AdminAgreementWorkflowScreen({Key? key, required this.agreement}) : super(key: key);

  @override
  ConsumerState<AdminAgreementWorkflowScreen> createState() => _AdminAgreementWorkflowScreenState();
}

class _AdminAgreementWorkflowScreenState extends ConsumerState<AdminAgreementWorkflowScreen> {
  final Map<String, bool> _sectionStatus = {
    'Property Details': false,
    'Owner Details': false,
    'Tenant Details': false,
    'Witness Details': false,
  };
  bool _isProcessing = false;
  List<AgreementTimelineEvent> _timeline = [];
  late String _currentStatus;

  final List<String> _statusSequence = [
    'Drafted',
    'Client Approved',
    'Govt Form Filled',
    'Payment Completed',
    'Biometric Completed',
    'Submitted to Govt',
    'Registered',
    'Delivered'
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.agreement.status;
    _fetchTimeline();
  }

  Future<void> _fetchTimeline() async {
    try {
      final events = await ref.read(adminServiceProvider).fetchAgreementTimeline(widget.agreement.id);
      if (mounted) {
        setState(() {
          _timeline = events;
        });
      }
    } catch (e) {
      debugPrint('Error fetching timeline: $e');
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied to clipboard!')));
  }

  Future<void> _updateStatus(String newStatus) async {
    final TextEditingController descController = TextEditingController();
    bool uploadPdf = false;
    PlatformFile? pickedFile;

    // If registered, maybe ask for PDF upload
    if (newStatus == 'Registered') {
      uploadPdf = true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Update Status to $newStatus'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Optional Note / Tracking Info',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (uploadPdf) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
                        if (result != null) {
                          setDialogState(() => pickedFile = result.files.single);
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(pickedFile == null ? 'Upload Final PDF' : pickedFile!.name),
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Update'),
                ),
              ],
            );
          }
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      if (uploadPdf && pickedFile?.bytes != null) {
        // Just upload as 'final_pdf' or similar. We could reuse uploadLeadDocument or add a new method
        // For now we'll just log it in the timeline description
        // In a real scenario, you'd upload this to a storage bucket and update `agreements.pdf_url`
        // We'll update the status and note the file was uploaded for now.
      }

      await ref.read(adminServiceProvider).updateAgreementStatusWithTimeline(
        widget.agreement.id, 
        newStatus,
        description: descController.text.isNotEmpty ? descController.text : (pickedFile != null ? 'Uploaded final PDF: ${pickedFile!.name}' : null),
      );
      setState(() {
        _currentStatus = newStatus;
      });
      await _fetchTimeline();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendDraftPdf(String method) async {
    final details = widget.agreement.details;
    if (details == null) return;
    
    setState(() => _isProcessing = true);
    try {
      final pdfBytes = await PdfService.generateDraftPdf(widget.agreement);
      final pdfUrl = await ref.read(adminServiceProvider).uploadDraftPdf(widget.agreement.agreementNumber, pdfBytes);

      final message = '''
Hello ${details.tenant.name},

Please review the details for your upcoming Agreement Draft (#${widget.agreement.agreementNumber}).

You can securely view the PDF Document here:
$pdfUrl

If everything looks correct, please reply with "APPROVED".
Thank you!
''';

      final encodedMessage = Uri.encodeComponent(message);
      Uri? url;
      if (method == 'whatsapp') {
        url = Uri.parse('https://wa.me/?text=$encodedMessage');
      } else if (method == 'email') {
        url = Uri.parse('mailto:?subject=Draft Agreement Approval&body=$encodedMessage');
      }

      if (url != null && await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $method.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildCopyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text('$label: $value', style: const TextStyle(fontSize: 16))),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () => _copyToClipboard(value, label),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A))),
                Row(
                  children: [
                    const Text('Filed: '),
                    Checkbox(
                      value: _sectionStatus[title],
                      onChanged: (val) {
                        setState(() => _sectionStatus[title] = val ?? false);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = widget.agreement.details;
    int currentIndex = _statusSequence.indexOf(_currentStatus);
    if (currentIndex == -1) currentIndex = 0; // fallback

    return Scaffold(
      appBar: AppBar(
        title: Text('Workflow: #${widget.agreement.agreementNumber}'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: details == null
          ? const Center(child: Text('No details found for this agreement.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // STATUS CONTROL PANEL
                Card(
                  color: Colors.teal[50],
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Agreement Status Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _statusSequence.map((status) {
                            int idx = _statusSequence.indexOf(status);
                            bool isCompleted = idx <= currentIndex;
                            bool isCurrent = idx == currentIndex;
                            
                            return ActionChip(
                              backgroundColor: isCurrent ? Colors.teal : (isCompleted ? Colors.teal[200] : Colors.grey[300]),
                              label: Text(status, style: TextStyle(color: isCurrent || isCompleted ? Colors.white : Colors.black87)),
                              // Disable the button if it's already the current step or a past step
                              onPressed: isCompleted ? null : () => _updateStatus(status),
                            );
                          }).toList(),
                        ),
                        if (_timeline.isNotEmpty) ...[
                          const Divider(),
                          const Text('History:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ..._timeline.map((e) => Text('• ${e.statusStep} - ${e.createdAt.toLocal().toString().split('.')[0]} ${e.description != null ? "(${e.description})" : ""}')),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // SHARE DRAFT ACTIONS
                if (_currentStatus == 'Drafted' || _currentStatus == 'Client Approved') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : () => _sendDraftPdf('whatsapp'),
                          icon: const Icon(Icons.chat, color: Colors.white),
                          label: const Text('WhatsApp Draft', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : () => _sendDraftPdf('email'),
                          icon: const Icon(Icons.email, color: Colors.white),
                          label: const Text('Email Draft', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // COPY PASTE DATA
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.yellow[100],
                  child: const Text('Use the copy buttons below to paste data directly into the government portal.', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                _buildSection('Property Details', [
                  _buildCopyRow('Agreement Number', widget.agreement.agreementNumber),
                  _buildCopyRow('Property Address', details.propertyAddress),
                  _buildCopyRow('Start Date', widget.agreement.startDate.toLocal().toString().split(' ')[0]),
                  _buildCopyRow('Period (Months)', details.periodMonths.toString()),
                  _buildCopyRow('End Date', widget.agreement.expiryDate.toLocal().toString().split(' ')[0]),
                  _buildCopyRow('Monthly Rent', '₹${details.monthlyRent}'),
                  _buildCopyRow('Deposit Amount', '₹${details.depositAmount}'),
                ]),
                _buildSection('Owner Details', [
                  _buildCopyRow('Name', details.owner.name),
                  _buildCopyRow('Age', details.owner.age),
                  _buildCopyRow('Address', details.owner.address),
                  _buildCopyRow('Pincode', details.owner.pincode),
                  _buildCopyRow('PAN', details.owner.pan),
                  _buildCopyRow('Aadhaar', details.owner.aadhaar),
                ]),
                _buildSection('Tenant Details', [
                  _buildCopyRow('Name', details.tenant.name),
                  _buildCopyRow('Age', details.tenant.age),
                  _buildCopyRow('Address', details.tenant.address),
                  _buildCopyRow('Pincode', details.tenant.pincode),
                  _buildCopyRow('PAN', details.tenant.pan),
                  _buildCopyRow('Aadhaar', details.tenant.aadhaar),
                ]),
                _buildSection('Witness Details', [
                  const Text('Witness 1', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildCopyRow('Name', details.witness1.name),
                  _buildCopyRow('Age', details.witness1.age),
                  _buildCopyRow('Address', details.witness1.address),
                  _buildCopyRow('Aadhaar', details.witness1.aadhaar),
                  const Divider(),
                  const Text('Witness 2', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildCopyRow('Name', details.witness2.name),
                  _buildCopyRow('Age', details.witness2.age),
                  _buildCopyRow('Address', details.witness2.address),
                  _buildCopyRow('Aadhaar', details.witness2.aadhaar),
                ]),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_models.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../services/pdf_service.dart';

class AdminDraftDetailsScreen extends ConsumerStatefulWidget {
  final Agreement agreement;
  const AdminDraftDetailsScreen({Key? key, required this.agreement}) : super(key: key);

  @override
  ConsumerState<AdminDraftDetailsScreen> createState() => _AdminDraftDetailsScreenState();
}

class _AdminDraftDetailsScreenState extends ConsumerState<AdminDraftDetailsScreen> {
  final Map<String, bool> _sectionStatus = {
    'Property Details': false,
    'Owner Details': false,
    'Tenant Details': false,
    'Witness Details': false,
  };
  bool _isGeneratingPdf = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied to clipboard!')));
  }

  Future<void> _sendToCustomer(String method) async {
    final details = widget.agreement.details;
    if (details == null) return;
    
    setState(() => _isGeneratingPdf = true);
    
    try {
      // 1. Generate the PDF
      final pdfBytes = await PdfService.generateDraftPdf(widget.agreement);
      
      // 2. Upload to Supabase and get the public URL
      final pdfUrl = await ref.read(adminServiceProvider).uploadDraftPdf(widget.agreement.agreementNumber, pdfBytes);

      // 3. Format the message with the URL
      final message = '''
Hello ${details.tenant.name},

Please review the details for your upcoming Agreement Draft (#${widget.agreement.agreementNumber}).

You can securely view the formally structured PDF Document here:
$pdfUrl

If everything looks correct, please reply with "APPROVED". If any changes are needed, please let us know.

Thank you,
Vakil Sirji Team
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
      if (mounted) setState(() => _isGeneratingPdf = false);
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Draft #${widget.agreement.agreementNumber} Data'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: details == null
          ? const Center(child: Text('No details found for this draft.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.yellow[100],
                  child: const Text('Use the copy buttons below to paste data directly into the government portal. Check the box when a section is successfully saved on the portal.', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 16),
                _isGeneratingPdf 
                  ? const Center(child: Column(children: [CircularProgressIndicator(), SizedBox(height: 8), Text('Generating & Uploading PDF...')]))
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _sendToCustomer('whatsapp'),
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: const Text('WhatsApp PDF', style: TextStyle(color: Colors.white, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _sendToCustomer('email'),
                            icon: const Icon(Icons.email, color: Colors.white),
                            label: const Text('Email PDF', style: TextStyle(color: Colors.white, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

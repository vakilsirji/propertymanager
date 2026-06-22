import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OwnerAgreementDetailsScreen extends StatefulWidget {
  final dynamic item;
  final bool isLead;

  const OwnerAgreementDetailsScreen({Key? key, required this.item, required this.isLead}) : super(key: key);

  @override
  State<OwnerAgreementDetailsScreen> createState() => _OwnerAgreementDetailsScreenState();
}

class _OwnerAgreementDetailsScreenState extends State<OwnerAgreementDetailsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _timeline = [];

  final List<String> _statusSequence = [
    'New', // Requested
    'Documents Collected',
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
    _fetchTimeline();
  }

  Future<void> _fetchTimeline() async {
    try {
      if (widget.isLead) {
        setState(() => _isLoading = false);
        return;
      }
      
      final timeline = await _supabase
          .from('agreement_timeline')
          .select()
          .eq('agreement_id', widget.item['id'])
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _timeline = timeline;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching timeline: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _downloadPdf() async {
    if (widget.isLead) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agreement is still in request phase.')));
      return;
    }
    final pdfUrl = widget.item['pdf_url'];
    if (pdfUrl != null && pdfUrl.toString().isNotEmpty) {
      final url = Uri.parse(pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open PDF.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Final PDF not uploaded yet.')));
    }
  }

  int _getCurrentStepIndex() {
    final status = widget.item['status'] as String? ?? (widget.isLead ? 'New' : 'Drafted');
    int idx = _statusSequence.indexOf(status);
    if (widget.isLead && status == 'Drafted') {
      idx = _statusSequence.indexOf('Drafted');
    }
    return idx == -1 ? (widget.isLead ? 0 : _statusSequence.indexOf('Drafted')) : idx;
  }

  List<Step> _buildSteps() {
    int currentIdx = _getCurrentStepIndex();
    
    return List.generate(_statusSequence.length, (index) {
      final stepStatus = _statusSequence[index];
      
      Map<String, dynamic> event = {};
      if (!widget.isLead || stepStatus == 'Drafted') {
         event = _timeline.cast<Map<String,dynamic>>().lastWhere(
          (e) => e['status_step'] == stepStatus, 
          orElse: () => {}
        );
      }
      
      bool isCompleted = index <= currentIdx;
      
      String subtitle = '';
      if (event.isNotEmpty) {
        final date = DateTime.parse(event['created_at'].toString()).toLocal();
        subtitle = '${date.toString().split('.')[0]}';
        if (event['description'] != null && event['description'].toString().isNotEmpty) {
          subtitle += '\n${event['description']}';
        }
      } else if (isCompleted) {
        subtitle = 'Completed';
        if (stepStatus == 'New' && widget.item['created_at'] != null) {
          final date = DateTime.parse(widget.item['created_at'].toString()).toLocal();
          subtitle = '${date.toString().split('.')[0]}';
        }
      } else if (index == currentIdx + 1) {
        subtitle = 'Pending Next';
      }

      return Step(
        title: Text(stepStatus, style: TextStyle(fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
        state: isCompleted ? StepState.complete : StepState.indexed,
        isActive: isCompleted,
        content: const SizedBox.shrink(),
      );
    });
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 24, color: iconColor),
      label: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.isLead ? 'Agreement Request' : 'Agreement #${widget.item['agreement_number']}'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isLead ? 'Tenant Request' : 'Property',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isLead ? widget.item['client_name'] : (widget.item['properties']?['property_name'] ?? 'Unknown Property'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (!widget.isLead)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Starts: ${widget.item['start_date'].toString().split(' ')[0]}'),
                              Text('Expires: ${widget.item['expiry_date'].toString().split(' ')[0]}'),
                            ],
                          ),
                        if (widget.isLead)
                          Text('Property: ${widget.item['property_address']}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Timeline Tracker
                const Text(
                  'Lifecycle Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Stepper(
                      physics: const NeverScrollableScrollPhysics(),
                      controlsBuilder: (context, details) => const SizedBox.shrink(),
                      currentStep: _getCurrentStepIndex(),
                      steps: _buildSteps(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                if (!widget.isLead && (widget.item['status'] == 'Registered' || widget.item['status'] == 'Delivered'))
                  _buildActionButton(context, 'Download Final Agreement', Icons.picture_as_pdf, Colors.red[700]!, _downloadPdf),
              ],
            ),
          ),
    );
  }
}

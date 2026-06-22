import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({Key? key}) : super(key: key);

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _userName = 'Tenant';
  dynamic _activeItem; // can be Lead or Agreement
  bool _isActiveItemLead = false;
  List<dynamic> _timeline = [];

  final List<String> _statusSequence = [
    'New', // Translates to 'Requested'
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
    _fetchTenantData();
  }

  Future<void> _fetchTenantData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
        return;
      }

      // Fetch user name & mobile
      String? mobile;
      final userRes = await _supabase.from('users').select('name, mobile').eq('id', user.id).maybeSingle();
      if (userRes != null) {
        _userName = userRes['name'] ?? 'Tenant';
        mobile = userRes['mobile'];
      }

      // Fetch active agreement
      final agreementRes = await _supabase
          .from('agreements')
          .select('*, properties(*), tenants!inner(user_id)')
          .eq('tenants.user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      List<dynamic> timeline = [];
      dynamic activeItem;
      bool isLead = false;

      if (agreementRes != null) {
        activeItem = agreementRes;
        timeline = await _supabase
            .from('agreement_timeline')
            .select()
            .eq('agreement_id', agreementRes['id'])
            .order('created_at', ascending: true);
      } else if (mobile != null) {
        // Fallback: search for a lead
        final leadRes = await _supabase
            .from('leads')
            .select()
            .eq('phone', mobile)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        
        if (leadRes != null) {
          activeItem = leadRes;
          isLead = true;
        }
      }

      if (mounted) {
        setState(() {
          _activeItem = activeItem;
          _isActiveItemLead = isLead;
          _timeline = timeline;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tenant data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _downloadPdf() async {
    if (_isActiveItemLead) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agreement is still in request phase.')));
      return;
    }
    final pdfUrl = _activeItem['pdf_url'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Tenancy', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(_userName, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _supabase.auth.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _activeItem == null 
          ? const Center(child: Text('No active agreements found for this account.', style: TextStyle(fontSize: 16)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Property Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Property',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isActiveItemLead 
                              ? _activeItem['property_address'] ?? 'Unknown Property'
                              : _activeItem['properties']?['address'] ?? 'Unknown Property',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_isActiveItemLead ? 'Agreement Request' : 'Agreement #${_activeItem['agreement_number']}'),
                              if (!_isActiveItemLead)
                                Text('Expires: ${_activeItem['expiry_date'].toString().split(' ')[0]}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timeline Tracker
                  const Text(
                    'Agreement Lifecycle Progress',
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
                  if (!_isActiveItemLead && (_activeItem['status'] == 'Registered' || _activeItem['status'] == 'Delivered'))
                    _buildActionButton(context, 'Download Final Agreement', Icons.picture_as_pdf, Colors.red[700]!, _downloadPdf),
                  const SizedBox(height: 12),
                  _buildActionButton(context, 'View Rent History', Icons.history, Colors.blue[700]!, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Rent History...')));
                  }),
                  const SizedBox(height: 12),
                  _buildActionButton(context, 'Request Renewal', Icons.autorenew, Colors.teal[700]!, () {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Requesting Renewal...')));
                  }),
                ],
              ),
            ),
    );
  }

  int _getCurrentStepIndex() {
    final status = _activeItem['status'] as String;
    // Map Lead status "Drafted" to Agreement "Drafted" step
    int idx = _statusSequence.indexOf(status);
    if (_isActiveItemLead && status == 'Drafted') {
      // In leads table, Drafted means it has been converted to an Agreement.
      // The timeline will actually jump to the agreement. So as a lead, its max status is Drafted.
      idx = _statusSequence.indexOf('Drafted');
    }
    return idx == -1 ? (_isActiveItemLead ? 0 : _statusSequence.indexOf('Drafted')) : idx;
  }

  List<Step> _buildSteps() {
    int currentIdx = _getCurrentStepIndex();
    
    return List.generate(_statusSequence.length, (index) {
      final stepStatus = _statusSequence[index];
      
      // Find if we have a timeline event for this step (only for Agreement steps)
      Map<String, dynamic> event = {};
      if (!_isActiveItemLead || stepStatus == 'Drafted') {
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
        // Use lead creation date for "New" if it's the requested step
        if (stepStatus == 'New' && _activeItem['created_at'] != null) {
          final date = DateTime.parse(_activeItem['created_at'].toString()).toLocal();
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
        content: const SizedBox.shrink(), // No extra content inside the step
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
}

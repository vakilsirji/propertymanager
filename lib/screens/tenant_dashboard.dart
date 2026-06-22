import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import '../services/pdf_service.dart';
import '../models/admin_models.dart';
import 'login_screen.dart';
import 'tenant_rent_history_screen.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({Key? key}) : super(key: key);

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _userName = 'Tenant';
  dynamic _activeTenancy;
  dynamic _agreement;
  bool _isPdfLoading = false;
  bool _isRenewalRequesting = false;

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

      // Fetch user name
      final userRes = await _supabase.from('users').select('name').eq('id', user.id).maybeSingle();
      if (userRes != null && userRes['name'] != null) {
        _userName = userRes['name'];
      }

      // Fetch active tenancy
      final tenancyRes = await _supabase
          .from('tenants')
          .select('*, properties(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Fetch the agreement linked to this tenancy, if one exists.
      dynamic agreementRes;
      if (tenancyRes != null && tenancyRes['id'] != null) {
        agreementRes = await _supabase
            .from('agreements')
            .select()
            .eq('tenant_id', tenancyRes['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
      }

      if (mounted) {
        setState(() {
          _activeTenancy = tenancyRes;
          _agreement = agreementRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tenant data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Opens the tenant's agreement PDF. If a finalized PDF has already been
  /// generated and uploaded (pdf_url is set), it's opened directly.
  /// Otherwise, a draft view is generated on the fly from the stored
  /// agreement details so the tenant always sees something useful.
  Future<void> _viewAgreementPdf() async {
    if (_agreement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No agreement found for your account yet.')),
      );
      return;
    }

    setState(() => _isPdfLoading = true);
    try {
      final pdfUrl = _agreement['pdf_url'] as String?;
      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        // Final PDF already generated and stored — fetch and open it.
        final storagePath = _extractStoragePath(pdfUrl);
        if (storagePath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not resolve the agreement file location.')),
          );
          return;
        }
        final bytes = await _supabase.storage.from('agreements').download(storagePath);
        await Printing.sharePdf(bytes: bytes, filename: 'Agreement_${_agreement['agreement_number'] ?? ''}.pdf');
      } else if (_agreement['details'] != null) {
        // No final PDF yet — build a draft view from the stored JSON so the
        // tenant still gets to see their agreement details.
        final agreementObj = Agreement.fromMap(Map<String, dynamic>.from(_agreement as Map));
        if (agreementObj.details == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your agreement details could not be read. Please contact your property manager.')),
          );
          return;
        }
        final bytes = await PdfService.generateDraftPdf(agreementObj);
        await Printing.sharePdf(bytes: bytes, filename: 'Agreement_Draft_${agreementObj.agreementNumber}.pdf');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your agreement details are not available yet. Please contact your property manager.')),
        );
      }
    } catch (e) {
      debugPrint('Error opening agreement PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open agreement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPdfLoading = false);
    }
  }

  /// Extracts the storage object path from a Supabase public Storage URL,
  /// e.g. ".../storage/v1/object/public/agreements/final_123.pdf" -> "final_123.pdf".
  String? _extractStoragePath(String publicUrl) {
    final marker = '/object/public/agreements/';
    final idx = publicUrl.indexOf(marker);
    if (idx == -1) return null;
    return publicUrl.substring(idx + marker.length);
  }

  void _viewRentHistory() {
    if (_activeTenancy == null || _activeTenancy['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tenancy found for your account yet.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TenantRentHistoryScreen(tenantId: _activeTenancy['id'].toString()),
      ),
    );
  }

  /// Submits a renewal request for the tenant's current agreement. This
  /// inserts into `renewal_leads`, the same table the admin's existing
  /// Renewals screen already watches, so the request shows up there
  /// automatically — no separate notification system needed.
  Future<void> _requestRenewal() async {
    if (_agreement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No agreement found for your account yet.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Renewal'),
        content: Text(
          'This will notify your property manager that you would like to renew '
          'your agreement (expiring ${_activeTenancy?['end_date'] ?? _agreement['expiry_date']}). Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Request Renewal')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isRenewalRequesting = true);
    try {
      // Avoid duplicate open requests for the same agreement.
      final existing = await _supabase
          .from('renewal_leads')
          .select('id')
          .eq('agreement_id', _agreement['id'])
          .inFilter('status', ['New', 'Contacted', 'Quote Sent'])
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A renewal request is already pending for this agreement.')),
          );
        }
        return;
      }

      final expiryDate = DateTime.parse(_agreement['expiry_date']);
      final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;

      await _supabase.from('renewal_leads').insert({
        'agreement_id': _agreement['id'],
        'expiry_date': _agreement['expiry_date'],
        'days_until_expiry': daysUntilExpiry,
        'status': 'New',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Renewal request sent! Your property manager will be in touch soon.')),
        );
      }
    } catch (e) {
      debugPrint('Error requesting renewal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit renewal request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRenewalRequesting = false);
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
        : _activeTenancy == null 
          ? const Center(child: Text('No active properties found for this account.', style: TextStyle(fontSize: 16)))
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
                            _activeTenancy['properties']['property_name'] ?? 'Unknown Property',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_activeTenancy['properties']['address']}, ${_activeTenancy['properties']['city']}',
                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rent Status & Agreement Status
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Monthly Rent',
                          'Rs. ${_activeTenancy['properties']['rent_amount']}',
                          'Pay to Owner',
                          Icons.currency_rupee,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusCard(
                          'Agreement',
                          'Active',
                          'Expires: ${_activeTenancy['end_date']}',
                          Icons.verified,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  const Text(
                    'My Actions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildActionButton(
                    context,
                    'View Agreement (PDF)',
                    Icons.picture_as_pdf,
                    Colors.red[700]!,
                    onPressed: _isPdfLoading ? null : _viewAgreementPdf,
                    isLoading: _isPdfLoading,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    'View Rent History',
                    Icons.history,
                    Colors.blue[700]!,
                    onPressed: _viewRentHistory,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    'Request Renewal',
                    Icons.autorenew,
                    Colors.teal[700]!,
                    onPressed: _isRenewalRequesting ? null : _requestRenewal,
                    isLoading: _isRenewalRequesting,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(String title, String value, String subtitle, IconData icon, MaterialColor color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color[700]),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color[900]),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor, {
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening $title...')));
          },
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
            )
          : Icon(icon, size: 24, color: iconColor),
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

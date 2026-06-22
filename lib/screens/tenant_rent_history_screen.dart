import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Read-only rent history view for a tenant — shows their own payments
/// (pending/paid, amount, month, payment mode) without the owner-only
/// actions like "Mark Paid" or "Add Rent Record".
class TenantRentHistoryScreen extends StatefulWidget {
  final String tenantId;

  const TenantRentHistoryScreen({Key? key, required this.tenantId}) : super(key: key);

  @override
  State<TenantRentHistoryScreen> createState() => _TenantRentHistoryScreenState();
}

class _TenantRentHistoryScreenState extends State<TenantRentHistoryScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await _supabase
          .from('rent_payments')
          .select()
          .eq('tenant_id', widget.tenantId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _payments = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tenant rent history: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Rent History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Could not load rent history: $_error'))
              : _payments.isEmpty
                  ? const Center(child: Text('No rent records found yet.', style: TextStyle(fontSize: 16)))
                  : RefreshIndicator(
                      onRefresh: _fetchPayments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          final isPaid = payment['status'] == 'paid';
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        payment['month'] ?? 'N/A',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rs. ${payment['amount']}',
                                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                      ),
                                      if (isPaid && payment['payment_date'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Paid on ${payment['payment_date']}'
                                            '${payment['payment_mode'] != null ? ' via ${payment['payment_mode']}' : ''}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isPaid ? Colors.green[100] : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isPaid ? 'PAID' : 'PENDING',
                                      style: TextStyle(
                                        color: isPaid ? Colors.green[900] : Colors.orange[900],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

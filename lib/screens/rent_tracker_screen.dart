import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';

class RentTrackerScreen extends StatefulWidget {
  const RentTrackerScreen({Key? key}) : super(key: key);

  @override
  State<RentTrackerScreen> createState() => _RentTrackerScreenState();
}

class _RentTrackerScreenState extends State<RentTrackerScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _rentPayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _syncAndFetchRents();
  }

  Future<void> _syncAndFetchRents() async {
    await _syncPendingRents();
    await _fetchRentPayments();
  }

  String _getMonthYearString(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _syncPendingRents() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final currentMonthStr = _getMonthYearString(DateTime.now());

      // Fetch active properties with their active tenants
      final activeProperties = await _supabase
          .from('properties')
          .select('id, rent_amount, tenants(id)')
          .eq('owner_id', user.id)
          .eq('status', 'active');

      for (var prop in activeProperties) {
        if (prop['tenants'] != null && (prop['tenants'] as List).isNotEmpty) {
          final tenantId = (prop['tenants'] as List).last['id'];

          // Check if rent record already exists for this tenant and month
          final existingRent = await _supabase
              .from('rent_payments')
              .select('id')
              .eq('tenant_id', tenantId)
              .eq('month', currentMonthStr)
              .maybeSingle();

          // If not, automatically insert a pending record
          if (existingRent == null) {
            await _supabase.from('rent_payments').insert({
              'property_id': prop['id'],
              'tenant_id': tenantId,
              'amount': prop['rent_amount'],
              'month': currentMonthStr,
              'status': 'pending',
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing pending rents: $e');
    }
  }

  Future<void> _fetchRentPayments() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      setState(() => _isLoading = true);

      final response = await _supabase
          .from('rent_payments')
          .select('*, properties!inner(property_name, owner_id)')
          .eq('properties.owner_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _rentPayments = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching rent payments: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rent payments: $e')),
        );
      }
    }
  }

  Future<void> _markAsPaid(int paymentId) async {
    String? selectedMode;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Payment Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Cash'),
                leading: const Icon(Icons.money),
                onTap: () { selectedMode = 'Cash'; Navigator.pop(context); },
              ),
              ListTile(
                title: const Text('Online'),
                leading: const Icon(Icons.language),
                onTap: () { selectedMode = 'Online'; Navigator.pop(context); },
              ),
              ListTile(
                title: const Text('UPI'),
                leading: const Icon(Icons.qr_code),
                onTap: () { selectedMode = 'UPI'; Navigator.pop(context); },
              ),
            ],
          ),
        );
      }
    );

    if (selectedMode == null) return; // User cancelled

    try {
      setState(() => _isLoading = true);
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      await _supabase
          .from('rent_payments')
          .update({'status': 'paid', 'payment_date': today, 'payment_mode': selectedMode})
          .eq('id', paymentId);
          
      await _fetchRentPayments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked as paid via $selectedMode!')),
        );
      }
    } catch (e) {
      debugPrint('Error marking as paid: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e. Did you run alter_schema.sql?')),
        );
      }
    }
  }

  Future<void> _shareReceipt(dynamic payment) async {
    try {
      setState(() => _isLoading = true);
      
      final pdf = pw.Document();
      
      final propertyName = payment['properties'] != null ? payment['properties']['property_name'] : 'Property';
      final amount = payment['amount'].toString();
      final month = payment['month'];
      final date = payment['payment_date'] ?? 'N/A';
      final mode = payment['payment_mode'] ?? 'N/A';

      // Ensure we have tenant name
      // We need to fetch tenant name since we only have tenant_id in rent_payments
      final tenantRes = await _supabase
          .from('tenants')
          .select('user_id, tenant_name, users(name)')
          .eq('id', payment['tenant_id'])
          .maybeSingle();

      String tenantName = 'Tenant';
      if (tenantRes != null) {
        if (tenantRes['users'] != null && tenantRes['users']['name'] != null) {
          tenantName = tenantRes['users']['name'];
        } else if (tenantRes['tenant_name'] != null) {
          tenantName = tenantRes['tenant_name'];
        }
      }

      // Fetch Owner Name
      final ownerRes = await _supabase
          .from('users')
          .select('name')
          .eq('id', payment['properties']['owner_id'])
          .maybeSingle();
      final ownerName = (ownerRes != null && ownerRes['name'] != null) ? ownerRes['name'] : 'Owner';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('RENT RECEIPT', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.SizedBox(height: 4),
                          pw.Text('Vakil Sirji Property Manager', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                        ]
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Receipt No: #${payment['id']}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 14)),
                        ]
                      ),
                    ]
                  ),
                  pw.SizedBox(height: 30),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 30),
                  
                  // Body
                  pw.Text('Payment Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.SizedBox(height: 15),
                  
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Amount Received:', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                            pw.Text('Rs. $amount', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ]
                        ),
                        pw.SizedBox(height: 10),
                        pw.Divider(color: PdfColors.grey300),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Payment Mode:', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                            pw.Text(mode, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          ]
                        ),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Rental Month:', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                            pw.Text(month, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          ]
                        ),
                      ]
                    )
                  ),
                  pw.SizedBox(height: 30),
                  
                  // Parties Info
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Received From (Tenant):', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                            pw.SizedBox(height: 4),
                            pw.Text(tenantName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ]
                        )
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Received By (Landlord):', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                            pw.SizedBox(height: 4),
                            pw.Text(ownerName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ]
                        )
                      ),
                    ]
                  ),
                  pw.SizedBox(height: 30),
                  
                  // Property Info
                  pw.Text('Property Details:', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  pw.SizedBox(height: 4),
                  pw.Text(propertyName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  
                  pw.SizedBox(height: 50),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 20),
                  
                  pw.Center(
                    child: pw.Text('This is a computer generated digital receipt and does not require a physical signature.', 
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                      textAlign: pw.TextAlign.center
                    )
                  )
                ],
              ),
            );
          },
        ),
      );

      if (mounted) setState(() => _isLoading = false);

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'Receipt_${payment['id']}.pdf');
      
    } catch (e, stack) {
      debugPrint('Error sharing receipt: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error Details'),
            content: SingleChildScrollView(
              child: Text('$e\n\n$stack'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
            ],
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Rent Tracker'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rentPayments.isEmpty
              ? const Center(child: Text('No rent records found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _rentPayments.length,
                  itemBuilder: (context, index) {
                    final payment = _rentPayments[index];
                    final property = payment['properties'];
                    final isPaid = payment['status'] == 'paid';
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isPaid ? Colors.green.shade200 : Colors.red.shade200,
                          width: 1,
                        )
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isPaid ? Colors.green[100] : Colors.red[100],
                              radius: 24,
                              child: Icon(
                                isPaid ? Icons.check : Icons.pending_actions,
                                color: isPaid ? Colors.green[700] : Colors.red[700],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${payment['month']} Rent',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    property != null ? property['property_name'] : 'Unknown Property',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rs. ${payment['amount']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  (payment['status'] ?? 'Unknown').toUpperCase(),
                                  style: TextStyle(
                                    color: isPaid ? Colors.green[700] : Colors.red[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isPaid && payment['payment_date'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Paid: ${payment['payment_date']}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _shareReceipt(payment),
                                    icon: const Icon(Icons.share, size: 16),
                                    label: const Text('Share Receipt'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[900],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                                if (!isPaid) ...[
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => _markAsPaid(payment['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Mark Paid', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const _AddRentDialog(),
          );
          _syncAndFetchRents();
        },
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddRentDialog extends StatefulWidget {
  const _AddRentDialog({Key? key}) : super(key: key);

  @override
  State<_AddRentDialog> createState() => _AddRentDialogState();
}

class _AddRentDialogState extends State<_AddRentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  
  List<dynamic> _properties = [];
  dynamic _selectedProperty;
  
  final _amountController = TextEditingController();
  final _monthController = TextEditingController();
  String _status = 'pending';
  DateTime? _paymentDate;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      // Fetch properties that are active and have a tenant
      final response = await _supabase
          .from('properties')
          .select('id, property_name, rent_amount, tenants(id)')
          .eq('owner_id', user.id)
          .eq('status', 'active');
          
      if (mounted) {
        setState(() {
          // Filter out properties that somehow don't have tenants
          _properties = response.where((p) => p['tenants'] != null && (p['tenants'] as List).isNotEmpty).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching properties: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProperty == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a property')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final tenantList = _selectedProperty['tenants'] as List;
      final tenantId = tenantList.last['id'];

      await _supabase.from('rent_payments').insert({
        'property_id': _selectedProperty['id'],
        'tenant_id': tenantId,
        'amount': double.parse(_amountController.text),
        'month': _monthController.text,
        'status': _status,
        'payment_date': _status == 'paid' ? (_paymentDate?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0]) : null,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rent record added')));
      }
    } catch (e) {
      debugPrint('Error adding rent record: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Rent Record'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<dynamic>(
                decoration: const InputDecoration(labelText: 'Select Property'),
                value: _selectedProperty,
                items: _properties.map((p) {
                  return DropdownMenuItem<dynamic>(
                    value: p,
                    child: Text(p['property_name']),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedProperty = val;
                    if (val != null) {
                      _amountController.text = val['rent_amount'].toString();
                    }
                  });
                },
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _monthController,
                decoration: const InputDecoration(labelText: 'Month (e.g. January 2026)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (Rs.)'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Status'),
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              if (_status == 'paid') ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_paymentDate == null 
                    ? 'Payment Date (Default: Today)' 
                    : 'Paid on: ${_paymentDate!.toIso8601String().split('T')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _paymentDate = date);
                    }
                  },
                ),
              ]
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const CircularProgressIndicator() : const Text('Save'),
        ),
      ],
    );
  }
}

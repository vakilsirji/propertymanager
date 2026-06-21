import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
class ViewPropertiesScreen extends StatefulWidget {
  const ViewPropertiesScreen({Key? key}) : super(key: key);

  @override
  State<ViewPropertiesScreen> createState() => _ViewPropertiesScreenState();
}

class _ViewPropertiesScreenState extends State<ViewPropertiesScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final response = await _supabase
          .from('properties')
          .select('*, tenants(*, users(name, mobile))')
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _properties = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching properties: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading properties: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Properties'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty
              ? const Center(child: Text('No properties found. Add one!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _properties.length,
                  itemBuilder: (context, index) {
                    final prop = _properties[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    prop['property_name'] ?? 'Unnamed Property',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: prop['status'] == 'active'
                                        ? Colors.green[100]
                                        : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (prop['status'] ?? 'Unknown').toUpperCase(),
                                    style: TextStyle(
                                      color: prop['status'] == 'active'
                                          ? Colors.green[900]
                                          : Colors.orange[900],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${prop['address']}, ${prop['city']}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Monthly Rent',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12)),
                                    Text('Rs. ${prop['rent_amount']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Deposit',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12)),
                                    Text('Rs. ${prop['deposit']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                            if (prop['tenants'] != null && (prop['tenants'] as List).isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tenant: ${(prop['tenants'] as List).last['users'] != null ? (prop['tenants'] as List).last['users']['name'] : ((prop['tenants'] as List).last['tenant_name'] ?? 'Unknown')}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'Rented Upto: ${(prop['tenants'] as List).last['end_date']}',
                                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      icon: const Icon(Icons.chat, color: Colors.green, size: 18),
                                      label: const Text('Reminder', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                                      onPressed: () async {
                                        final tenantList = prop['tenants'] as List;
                                        final tenant = tenantList.last;
                                        String? mobile = tenant['users'] != null ? tenant['users']['mobile'] : tenant['tenant_mobile'];
                                        if (mobile == null || mobile.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No mobile number found for tenant')));
                                          return;
                                        }
                                        final message = "Hello, this is a reminder to pay the rent for the property ${prop['property_name']}. Please pay at your earliest convenience.";
                                        final url = Uri.parse("https://wa.me/$mobile?text=${Uri.encodeComponent(message)}");
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        } else {
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch WhatsApp')));
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (prop['tenants'] == null || (prop['tenants'] as List).isEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showAddTenantDialog(context, prop['id']);
                                  },
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Add Tenant & Duration'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[50],
                                    foregroundColor: Colors.blue[900],
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _showAddTenantDialog(BuildContext context, int propertyId) async {
    await showDialog(
      context: context,
      builder: (context) {
        return _AddTenantDialog(propertyId: propertyId);
      },
    );
    _fetchProperties();
  }
}

class _AddTenantDialog extends StatefulWidget {
  final int propertyId;
  const _AddTenantDialog({Key? key, required this.propertyId}) : super(key: key);

  @override
  State<_AddTenantDialog> createState() => _AddTenantDialogState();
}

class _AddTenantDialogState extends State<_AddTenantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  
  List<dynamic> _tenants = [];
  String? _selectedTenantId;
  final _aadhaarController = TextEditingController();
  DateTime? _startDate;
  final _durationController = TextEditingController();

  bool _isUnregistered = false;
  final _manualNameController = TextEditingController();
  final _manualEmailController = TextEditingController();
  final _manualMobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTenants();
  }

  Future<void> _fetchTenants() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, email')
          .eq('role', 'tenant');
      if (mounted) {
        setState(() {
          _tenants = response;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tenants: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isUnregistered && _selectedTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a tenant')));
      return;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a start date')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final months = int.parse(_durationController.text);
      final endDate = DateTime(_startDate!.year, _startDate!.month + months, _startDate!.day);

      String? activeTenantId = _selectedTenantId;

      if (_isUnregistered) {
        // Create user silently via REST API to avoid logging out the owner
        final url = dotenv.env['SUPABASE_URL']!;
        final anonKey = dotenv.env['SUPABASE_ANON_KEY']!;
        
        final response = await http.post(
          Uri.parse('$url/auth/v1/signup'),
          headers: {
            'apikey': anonKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': _manualEmailController.text.trim(),
            'password': '123456',
          }),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          final String newUserId = data['user']['id'];
          activeTenantId = newUserId;

          // Insert into public.users
          await _supabase.from('users').insert({
            'id': newUserId,
            'name': _manualNameController.text.trim(),
            'email': _manualEmailController.text.trim(),
            'mobile': _manualMobileController.text.trim(),
            'role': 'tenant',
          });
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['msg'] ?? 'Failed to create tenant account');
        }
      }

      // Insert tenant
      await _supabase.from('tenants').insert({
        'property_id': widget.propertyId,
        'user_id': activeTenantId,
        'aadhaar_last4': _aadhaarController.text,
        'start_date': _startDate!.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
      });

      // Update property status to active
      await _supabase
          .from('properties')
          .update({'status': 'active'})
          .eq('id', widget.propertyId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tenant added successfully. Default password is 123456')));
      }
    } catch (e) {
      debugPrint('Error adding tenant: $e');
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
      title: const Text('Add Tenant & Duration'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Tenant is not registered?'),
                value: _isUnregistered,
                onChanged: (val) {
                  setState(() {
                    _isUnregistered = val;
                    _selectedTenantId = null;
                  });
                },
              ),
              if (!_isUnregistered)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Tenant'),
                  value: _selectedTenantId,
                  items: _tenants.map((t) {
                    return DropdownMenuItem<String>(
                      value: t['id'] as String,
                      child: Text('${t['name']} (${t['email']})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedTenantId = val),
                  validator: (val) => !_isUnregistered && val == null ? 'Required' : null,
                ),
              if (_isUnregistered) ...[
                TextFormField(
                  controller: _manualNameController,
                  decoration: const InputDecoration(labelText: 'Tenant Name'),
                  validator: (val) => _isUnregistered && (val == null || val.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _manualEmailController,
                  decoration: const InputDecoration(labelText: 'Tenant Email (For Login)'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (!_isUnregistered) return null;
                    if (val == null || val.isEmpty) return 'Required for login';
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _manualMobileController,
                  decoration: const InputDecoration(labelText: 'Tenant Mobile'),
                  keyboardType: TextInputType.phone,
                  validator: (val) => _isUnregistered && (val == null || val.isEmpty) ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _aadhaarController,
                decoration: const InputDecoration(labelText: 'Aadhaar Last 4 Digits'),
                keyboardType: TextInputType.number,
                maxLength: 4,
                validator: (val) => val == null || val.length != 4 ? 'Enter 4 digits' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_startDate == null 
                  ? 'Select Start Date' 
                  : 'Start: ${_startDate!.toIso8601String().split('T')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration (Months)'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (int.tryParse(val) == null) return 'Enter a valid number';
                  return null;
                },
              ),
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

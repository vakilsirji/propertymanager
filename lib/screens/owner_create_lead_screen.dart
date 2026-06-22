import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OwnerCreateLeadScreen extends StatefulWidget {
  const OwnerCreateLeadScreen({Key? key}) : super(key: key);

  @override
  State<OwnerCreateLeadScreen> createState() => _OwnerCreateLeadScreenState();
}

class _OwnerCreateLeadScreenState extends State<OwnerCreateLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _tenantNameController = TextEditingController();
  final TextEditingController _tenantPhoneController = TextEditingController();
  final TextEditingController _propertyAddressController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingProperties = true;
  List<dynamic> _properties = [];
  String? _selectedPropertyAddress;
  bool _isAddingNewProperty = false;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('properties')
            .select('id, property_name, address')
            .eq('owner_id', user.id);
        if (mounted) {
          setState(() {
            _properties = data;
            _isLoadingProperties = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching properties: $e');
      if (mounted) setState(() => _isLoadingProperties = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPropertyAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add a property address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      
      String finalAddress = _selectedPropertyAddress!;
      if (_isAddingNewProperty) {
        finalAddress = _propertyAddressController.text.trim();
      }

      await supabase.from('leads').insert({
        'client_name': _tenantNameController.text.trim(),
        'phone': _tenantPhoneController.text.trim(),
        'property_address': finalAddress,
        'status': 'New',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agreement Request sent to Admin!')),
        );
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Rent Agreement'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoadingProperties 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter the details of your tenant and property. The Admin will contact you to collect documents and draft the agreement.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _tenantNameController,
                decoration: InputDecoration(
                  labelText: 'Tenant Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _tenantPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Tenant Mobile Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedPropertyAddress,
                decoration: InputDecoration(
                  labelText: 'Select Property',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.home),
                ),
                items: [
                  ..._properties.map((prop) {
                    final addr = prop['address'] as String;
                    final name = prop['property_name'] as String;
                    return DropdownMenuItem(
                      value: addr,
                      child: Text('$name ($addr)', maxLines: 1, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  const DropdownMenuItem(
                    value: 'NEW',
                    child: Text('+ Add New Property Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedPropertyAddress = val;
                    _isAddingNewProperty = val == 'NEW';
                  });
                },
              ),
              
              if (_isAddingNewProperty) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _propertyAddressController,
                  decoration: InputDecoration(
                    labelText: 'New Property Address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                  validator: (val) {
                    if (_isAddingNewProperty && (val == null || val.isEmpty)) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Send Request to Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

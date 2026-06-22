import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';
import '../models/models.dart';

class AdminVendorAssignScreen extends ConsumerStatefulWidget {
  const AdminVendorAssignScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminVendorAssignScreen> createState() => _AdminVendorAssignScreenState();
}

class _AdminVendorAssignScreenState extends ConsumerState<AdminVendorAssignScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAgreementId;
  String? _selectedVendorId;
  String? _selectedVendorName;
  DateTime _visitDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final agreementsAsync = ref.watch(agreementsStreamProvider);
    final usersAsync = ref.watch(customersStreamProvider); // In a real app we'd fetch users with role='vendor'

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Vendor'),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: agreementsAsync.when(
        data: (agreements) => usersAsync.when(
          data: (users) {
            // Vendors are users with role == 'vendor' or just mapping all customers as fallback
            final vendors = users.where((u) => u.role == 'vendor').toList();
            // Just for demo if no vendors exist yet, let admin select from owners/tenants too
            final vendorList = vendors.isEmpty ? users : vendors;

            if (agreements.isEmpty) {
              return const Center(child: Text('No agreements available to assign.'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schedule a Biometric Visit:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Agreement', border: OutlineInputBorder()),
                      value: _selectedAgreementId,
                      items: agreements
                          .map((a) => DropdownMenuItem(value: a.id, child: Text('Agreement #${a.agreementNumber}')))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedAgreementId = val),
                      validator: (val) => val == null ? 'Please select an agreement' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Vendor', border: OutlineInputBorder()),
                      value: _selectedVendorId,
                      items: vendorList
                          .map((v) => DropdownMenuItem(value: v.id, child: Text(v.name)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedVendorId = val;
                          _selectedVendorName = vendorList.firstWhere((v) => v.id == val).name;
                        });
                      },
                      validator: (val) => val == null ? 'Please select a vendor' : null,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                      title: const Text('Visit Date'),
                      subtitle: Text('${_visitDate.toLocal()}'.split(' ')[0]),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: _visitDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (d != null) setState(() => _visitDate = d);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A)),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() => _isLoading = true);
                                  try {
                                    await ref.read(adminServiceProvider).assignVendor(
                                          _selectedAgreementId!,
                                          _selectedVendorId!,
                                          _selectedVendorName!,
                                          _visitDate,
                                        );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor Assigned!')));
                                      context.pop();
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  } finally {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Assign Vendor', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class AdminRegistrationScreen extends ConsumerStatefulWidget {
  const AdminRegistrationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminRegistrationScreen> createState() => _AdminRegistrationScreenState();
}

class _AdminRegistrationScreenState extends ConsumerState<AdminRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAgreementId;
  final _regNumController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Usually only agreements that have an IGR filed and Biometrics completed reach Registration
    // For demo purposes, we will load all agreements or drafts
    final agreementsAsync = ref.watch(agreementsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Registration'),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: agreementsAsync.when(
        data: (agreements) {
          // Filtering for demo: usually we look for status that indicates ready for registration.
          final pending = agreements.where((a) => a.status.startsWith('IGR') || a.status == 'Draft').toList();
          
          if (pending.isEmpty) {
            return const Center(child: Text('No agreements pending registration.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select an Agreement to finalize registration:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Agreement', border: OutlineInputBorder()),
                    value: _selectedAgreementId,
                    items: pending
                        .map((a) => DropdownMenuItem(value: a.id, child: Text('Agreement #${a.agreementNumber}')))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedAgreementId = val),
                    validator: (val) => val == null ? 'Please select an agreement' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _regNumController,
                    decoration: const InputDecoration(labelText: 'Govt. Registration Number', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
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
                                  await ref.read(adminServiceProvider).completeRegistration(_selectedAgreementId!, _regNumController.text);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Completed!')));
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
                          : const Text('Complete Registration', style: TextStyle(color: Colors.white, fontSize: 16)),
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
    );
  }
}

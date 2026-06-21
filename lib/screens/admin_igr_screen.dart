import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';

class AdminIgrScreen extends ConsumerStatefulWidget {
  const AdminIgrScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminIgrScreen> createState() => _AdminIgrScreenState();
}

class _AdminIgrScreenState extends ConsumerState<AdminIgrScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedAgreementId;
  final _tokenController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final draftsAsync = ref.watch(draftAgreementsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('File IGR'),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: draftsAsync.when(
        data: (agreements) {
          if (agreements.isEmpty) {
            return const Center(child: Text('No draft agreements to file IGR for.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select an Agreement to generate an IGR token for:', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  TextFormField(
                    controller: _tokenController,
                    decoration: const InputDecoration(labelText: 'IGR Token Number', border: OutlineInputBorder()),
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
                                  await ref.read(adminServiceProvider).fileIgr(_selectedAgreementId!, _tokenController.text);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IGR Filed Successfully!')));
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
                          : const Text('Submit IGR', style: TextStyle(color: Colors.white, fontSize: 16)),
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

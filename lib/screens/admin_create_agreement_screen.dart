import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';
import '../models/models.dart';

class AdminCreateAgreementScreen extends ConsumerStatefulWidget {
  const AdminCreateAgreementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminCreateAgreementScreen> createState() => _AdminCreateAgreementScreenState();
}

class _AdminCreateAgreementScreenState extends ConsumerState<AdminCreateAgreementScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Step 1: Basics
  final _basicsFormKey = GlobalKey<FormState>();
  String? _selectedPropertyId;
  String? _selectedTenantId;
  final _agreementNumController = TextEditingController();
  DateTime _startDate = DateTime.now();
  int _periodMonths = 11;
  DateTime get _expiryDate => DateTime(_startDate.year, _startDate.month + _periodMonths, _startDate.day);

  // Step 2: Owner Details
  final _ownerFormKey = GlobalKey<FormState>();
  final _ownerName = TextEditingController();
  final _ownerAddress = TextEditingController();
  final _ownerPin = TextEditingController();
  final _ownerPan = TextEditingController();
  final _ownerAadhaar = TextEditingController();

  // Step 3: Tenant Details
  final _tenantFormKey = GlobalKey<FormState>();
  final _tenantName = TextEditingController();
  final _tenantAddress = TextEditingController();
  final _tenantPin = TextEditingController();
  final _tenantPan = TextEditingController();
  final _tenantAadhaar = TextEditingController();

  // Step 4: Witnesses
  final _witnessesFormKey = GlobalKey<FormState>();
  final _w1Name = TextEditingController();
  final _w1Address = TextEditingController();
  final _w1Aadhaar = TextEditingController();
  final _w1Age = TextEditingController();
  final _w2Name = TextEditingController();
  final _w2Address = TextEditingController();
  final _w2Aadhaar = TextEditingController();
  final _w2Age = TextEditingController();

  void _onTenantSelected(UserModel t) {
    _tenantName.text = t.name;
    // Auto fill other fields if available in future
  }

  void _onPropertySelected(Property p) {
    _ownerName.text = p.ownerName;
  }

  void _submit() async {
    if (!_witnessesFormKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final details = AgreementDetails(
        owner: AgreementPerson(
          name: _ownerName.text,
          address: _ownerAddress.text,
          pincode: _ownerPin.text,
          pan: _ownerPan.text,
          aadhaar: _ownerAadhaar.text,
        ),
        tenant: AgreementPerson(
          name: _tenantName.text,
          address: _tenantAddress.text,
          pincode: _tenantPin.text,
          pan: _tenantPan.text,
          aadhaar: _tenantAadhaar.text,
        ),
        witness1: AgreementWitness(
          name: _w1Name.text,
          address: _w1Address.text,
          aadhaar: _w1Aadhaar.text,
          age: _w1Age.text,
        ),
        witness2: AgreementWitness(
          name: _w2Name.text,
          address: _w2Address.text,
          aadhaar: _w2Aadhaar.text,
          age: _w2Age.text,
        ),
        periodMonths: _periodMonths,
      );

      await ref.read(adminServiceProvider).createAgreement(
            propertyId: _selectedPropertyId!,
            tenantId: _selectedTenantId!,
            startDate: _startDate,
            expiryDate: _expiryDate,
            agreementNumber: _agreementNumController.text,
            details: details.toMap(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft Agreement Saved Successfully!')));
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving draft: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesStreamProvider);
    final customersAsync = ref.watch(customersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Draft Agreement'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: propertiesAsync.when(
        data: (properties) => customersAsync.when(
          data: (customers) {
            final tenantsList = customers.where((c) => c.role == 'tenant').toList();
            return Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                bool isValid = false;
                switch (_currentStep) {
                  case 0:
                    isValid = _basicsFormKey.currentState!.validate();
                    break;
                  case 1:
                    isValid = _ownerFormKey.currentState!.validate();
                    break;
                  case 2:
                    isValid = _tenantFormKey.currentState!.validate();
                    break;
                  case 3:
                    isValid = _witnessesFormKey.currentState!.validate();
                    if (isValid) _submit();
                    break;
                }
                if (isValid && _currentStep < 3) {
                  setState(() => _currentStep += 1);
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                } else {
                  context.pop();
                }
              },
              controlsBuilder: (context, details) {
                if (_isLoading) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
                return Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A)),
                      child: Text(_currentStep == 3 ? 'Save Draft' : 'Next', style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(_currentStep == 0 ? 'Cancel' : 'Back', style: const TextStyle(color: Colors.grey)),
                    ),
                  ],
                );
              },
              steps: [
                Step(
                  title: const Text('Agreement Basics'),
                  isActive: _currentStep >= 0,
                  content: Form(
                    key: _basicsFormKey,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Select Property', border: OutlineInputBorder()),
                          value: _selectedPropertyId,
                          items: properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.address))).toList(),
                          onChanged: (val) {
                            setState(() => _selectedPropertyId = val);
                            if (val != null) _onPropertySelected(properties.firstWhere((p) => p.id == val));
                          },
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Select Tenant Profile', border: OutlineInputBorder()),
                          value: _selectedTenantId,
                          items: tenantsList.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.name} (${t.mobile})'))).toList(),
                          onChanged: (val) {
                            setState(() => _selectedTenantId = val);
                            if (val != null) _onTenantSelected(tenantsList.firstWhere((t) => t.id == val));
                          },
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _agreementNumController,
                          decoration: const InputDecoration(labelText: 'Agreement Number (Temp)', border: OutlineInputBorder()),
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                                title: const Text('Start Date'),
                                subtitle: Text('${_startDate.toLocal()}'.split(' ')[0]),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                  if (d != null) setState(() => _startDate = d);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: '11',
                                decoration: const InputDecoration(labelText: 'Period (Months)', border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  if (val.isNotEmpty) setState(() => _periodMonths = int.parse(val));
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Calculated End Date: ${_expiryDate.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('Owner Details'),
                  isActive: _currentStep >= 1,
                  content: Form(
                    key: _ownerFormKey,
                    child: Column(
                      children: [
                        TextFormField(controller: _ownerName, decoration: const InputDecoration(labelText: 'Full Name'), validator: (val) => val!.isEmpty ? 'Required' : null),
                        TextFormField(controller: _ownerAddress, decoration: const InputDecoration(labelText: 'Full Address'), maxLines: 2, validator: (val) => val!.isEmpty ? 'Required' : null),
                        TextFormField(controller: _ownerPin, decoration: const InputDecoration(labelText: 'Pincode'), keyboardType: TextInputType.number),
                        TextFormField(controller: _ownerPan, decoration: const InputDecoration(labelText: 'PAN Number')),
                        TextFormField(controller: _ownerAadhaar, decoration: const InputDecoration(labelText: 'Aadhaar Number'), keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('Tenant Details'),
                  isActive: _currentStep >= 2,
                  content: Form(
                    key: _tenantFormKey,
                    child: Column(
                      children: [
                        TextFormField(controller: _tenantName, decoration: const InputDecoration(labelText: 'Full Name'), validator: (val) => val!.isEmpty ? 'Required' : null),
                        TextFormField(controller: _tenantAddress, decoration: const InputDecoration(labelText: 'Full Address'), maxLines: 2, validator: (val) => val!.isEmpty ? 'Required' : null),
                        TextFormField(controller: _tenantPin, decoration: const InputDecoration(labelText: 'Pincode'), keyboardType: TextInputType.number),
                        TextFormField(controller: _tenantPan, decoration: const InputDecoration(labelText: 'PAN Number')),
                        TextFormField(controller: _tenantAadhaar, decoration: const InputDecoration(labelText: 'Aadhaar Number'), keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('Witnesses'),
                  isActive: _currentStep >= 3,
                  content: Form(
                    key: _witnessesFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Witness 1', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextFormField(controller: _w1Name, decoration: const InputDecoration(labelText: 'Name'), validator: (val) => val!.isEmpty ? 'Required' : null),
                        TextFormField(controller: _w1Age, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
                        TextFormField(controller: _w1Address, decoration: const InputDecoration(labelText: 'Address')),
                        TextFormField(controller: _w1Aadhaar, decoration: const InputDecoration(labelText: 'Aadhaar')),
                        const Divider(height: 32),
                        const Text('Witness 2', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextFormField(controller: _w2Name, decoration: const InputDecoration(labelText: 'Name'), validator: (val) => val!.isEmpty ? 'Required' : null),
                        TextFormField(controller: _w2Age, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
                        TextFormField(controller: _w2Address, decoration: const InputDecoration(labelText: 'Address')),
                        TextFormField(controller: _w2Aadhaar, decoration: const InputDecoration(labelText: 'Aadhaar')),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading customers: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading properties: $e')),
      ),
    );
  }
}

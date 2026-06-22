import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';
import '../models/models.dart';

class AdminCreateAgreementScreen extends ConsumerStatefulWidget {
  const AdminCreateAgreementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminCreateAgreementScreen> createState() =>
      _AdminCreateAgreementScreenState();
}

class _AdminCreateAgreementScreenState
    extends ConsumerState<AdminCreateAgreementScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNextAgreementNumber();
  }

  Future<void> _fetchNextAgreementNumber() async {
    try {
      final num = await ref
          .read(adminServiceProvider)
          .generateNextAgreementNumber();
      if (mounted) setState(() => _agreementNumController.text = num);
    } catch (e) {
      debugPrint('Error generating agreement number: $e');
    }
  }

  // Step 1: Basics
  final _basicsFormKey = GlobalKey<FormState>();
  String? _selectedPropertyId;
  String? _selectedTenantId;
  final _agreementNumController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _depositController = TextEditingController();
  DateTime _startDate = DateTime.now();
  int _periodMonths = 11;
  DateTime get _expiryDate => DateTime(
    _startDate.year,
    _startDate.month + _periodMonths,
    _startDate.day,
  );

  // Step 2: Owner Details
  final _ownerFormKey = GlobalKey<FormState>();
  final _ownerName = TextEditingController();
  final _ownerAddress = TextEditingController();
  final _ownerPin = TextEditingController();
  final _ownerPan = TextEditingController();
  final _ownerAadhaar = TextEditingController();
  DateTime _ownerDob = DateTime.now().subtract(const Duration(days: 365 * 30));
  int get _ownerCalculatedAge =>
      DateTime.now().year -
      _ownerDob.year -
      (DateTime.now().month < _ownerDob.month ||
              (DateTime.now().month == _ownerDob.month &&
                  DateTime.now().day < _ownerDob.day)
          ? 1
          : 0);

  // Step 3: Tenant Details
  final _tenantFormKey = GlobalKey<FormState>();
  final _tenantName = TextEditingController();
  final _tenantAddress = TextEditingController();
  final _tenantPin = TextEditingController();
  final _tenantPan = TextEditingController();
  final _tenantAadhaar = TextEditingController();
  DateTime _tenantDob = DateTime.now().subtract(const Duration(days: 365 * 30));
  int get _tenantCalculatedAge =>
      DateTime.now().year -
      _tenantDob.year -
      (DateTime.now().month < _tenantDob.month ||
              (DateTime.now().month == _tenantDob.month &&
                  DateTime.now().day < _tenantDob.day)
          ? 1
          : 0);

  // Step 4: Witnesses
  final _witnessesFormKey = GlobalKey<FormState>();
  final _w1Name = TextEditingController();
  final _w1Address = TextEditingController();
  final _w1Aadhaar = TextEditingController();
  DateTime _w1Dob = DateTime.now().subtract(const Duration(days: 365 * 30));
  int get _w1CalculatedAge =>
      DateTime.now().year -
      _w1Dob.year -
      (DateTime.now().month < _w1Dob.month ||
              (DateTime.now().month == _w1Dob.month &&
                  DateTime.now().day < _w1Dob.day)
          ? 1
          : 0);

  final _w2Name = TextEditingController();
  final _w2Address = TextEditingController();
  final _w2Aadhaar = TextEditingController();
  DateTime _w2Dob = DateTime.now().subtract(const Duration(days: 365 * 30));
  int get _w2CalculatedAge =>
      DateTime.now().year -
      _w2Dob.year -
      (DateTime.now().month < _w2Dob.month ||
              (DateTime.now().month == _w2Dob.month &&
                  DateTime.now().day < _w2Dob.day)
          ? 1
          : 0);

  void _onTenantSelected(UserModel t) {
    _tenantName.text = t.name;
    // Auto fill other fields if available in future
  }

  void _onPropertySelected(Property p) {
    _ownerName.text = p.ownerName;
  }

  /// Fills the Owner fields from a previously-saved AgreementPersonRecord.
  void _applyOwnerRecord(AgreementPersonRecord r) {
    setState(() {
      _ownerName.text = r.name;
      _ownerAddress.text = r.address;
      _ownerPin.text = r.pincode;
      _ownerPan.text = r.pan;
      _ownerAadhaar.text = r.aadhaar;
      if (r.dob != null) _ownerDob = r.dob!;
    });
  }

  /// Fills Witness 1 fields from a previously-saved AgreementPersonRecord.
  void _applyWitness1Record(AgreementPersonRecord r) {
    setState(() {
      _w1Name.text = r.name;
      _w1Address.text = r.address;
      _w1Aadhaar.text = r.aadhaar;
      if (r.dob != null) _w1Dob = r.dob!;
    });
  }

  /// Fills Witness 2 fields from a previously-saved AgreementPersonRecord.
  void _applyWitness2Record(AgreementPersonRecord r) {
    setState(() {
      _w2Name.text = r.name;
      _w2Address.text = r.address;
      _w2Aadhaar.text = r.aadhaar;
      if (r.dob != null) _w2Dob = r.dob!;
    });
  }

  /// A type-ahead search box that looks up existing Owner/Witness people by
  /// name, Aadhaar, or PAN and lets the executive tap a match to auto-fill
  /// the form below — so a repeat owner/witness is never retyped twice.
  Widget _buildPersonReuseSearch({
    required String role,
    required String hint,
    required void Function(AgreementPersonRecord) onSelected,
  }) {
    return _PersonReuseSearchField(
      role: role,
      hint: hint,
      onSelected: onSelected,
      adminService: ref.read(adminServiceProvider),
    );
  }

  void _showAddPropertyDialog() {
    final addressCtrl = TextEditingController();
    final ownerCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Property'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Property Address'),
            ),
            TextField(
              controller: ownerCtrl,
              decoration: const InputDecoration(labelText: 'Owner Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (addressCtrl.text.isEmpty) return;
              try {
                final id = await ref.read(adminServiceProvider).createProperty(addressCtrl.text, ownerCtrl.text);
                if (context.mounted) context.pop();
                
                // Show loading indicator or simple delay to allow DB to update
                await Future.delayed(const Duration(milliseconds: 500));
                ref.invalidate(propertiesStreamProvider);
                
                setState(() {
                  _selectedPropertyId = id;
                  _ownerName.text = ownerCtrl.text;
                });
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddTenantDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Tenant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tenant Name'),
            ),
            TextField(
              controller: mobileCtrl,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              try {
                final id = await ref.read(adminServiceProvider).createTenantProfile(nameCtrl.text, mobileCtrl.text);
                if (context.mounted) context.pop();
                
                await Future.delayed(const Duration(milliseconds: 500));
                ref.invalidate(customersStreamProvider);
                
                setState(() {
                  _selectedTenantId = id;
                  _tenantName.text = nameCtrl.text;
                });
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
          age: _ownerCalculatedAge.toString(),
        ),
        tenant: AgreementPerson(
          name: _tenantName.text,
          address: _tenantAddress.text,
          pincode: _tenantPin.text,
          pan: _tenantPan.text,
          aadhaar: _tenantAadhaar.text,
          age: _tenantCalculatedAge.toString(),
        ),
        witness1: AgreementWitness(
          name: _w1Name.text,
          address: _w1Address.text,
          aadhaar: _w1Aadhaar.text,
          age: _w1CalculatedAge.toString(),
        ),
        witness2: AgreementWitness(
          name: _w2Name.text,
          address: _w2Address.text,
          aadhaar: _w2Aadhaar.text,
          age: _w2CalculatedAge.toString(),
        ),
        periodMonths: _periodMonths,
        monthlyRent: _monthlyRentController.text,
        depositAmount: _depositController.text,
        propertyAddress: ref.read(propertiesStreamProvider).value?.firstWhere((p) => p.id == _selectedPropertyId).address ?? '',
      );

      await ref
          .read(adminServiceProvider)
          .createAgreement(
            propertyId: _selectedPropertyId!,
            tenantId: _selectedTenantId!,
            startDate: _startDate,
            expiryDate: _expiryDate,
            agreementNumber: _agreementNumController.text,
            details: details.toMap(),
          );

      // Save Owner + both Witnesses to the reusable people list, so the next
      // agreement involving the same person doesn't need retyping. This is
      // best-effort — if it fails, the agreement itself is still saved.
      final adminService = ref.read(adminServiceProvider);
      try {
        await adminService.saveAgreementPerson(
          role: 'owner',
          name: _ownerName.text,
          address: _ownerAddress.text,
          pincode: _ownerPin.text,
          pan: _ownerPan.text,
          aadhaar: _ownerAadhaar.text,
          dob: _ownerDob,
        );
        await adminService.saveAgreementPerson(
          role: 'witness',
          name: _w1Name.text,
          address: _w1Address.text,
          pincode: '',
          pan: '',
          aadhaar: _w1Aadhaar.text,
          dob: _w1Dob,
        );
        await adminService.saveAgreementPerson(
          role: 'witness',
          name: _w2Name.text,
          address: _w2Address.text,
          pincode: '',
          pan: '',
          aadhaar: _w2Aadhaar.text,
          dob: _w2Dob,
        );
      } catch (e) {
        debugPrint('Could not save reusable person records: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft Agreement Saved Successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving draft: $e')));
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
            final tenantsList = customers
                .where((c) => c.role == 'tenant')
                .toList();
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
                if (_isLoading)
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  );
                return Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                      ),
                      child: Text(
                        _currentStep == 3 ? 'Save Draft' : 'Next',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(
                        _currentStep == 0 ? 'Cancel' : 'Back',
                        style: const TextStyle(color: Colors.grey),
                      ),
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
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: 'Select Property', border: OutlineInputBorder()),
                                value: properties.any((p) => p.id == _selectedPropertyId) ? _selectedPropertyId : null,
                                items: properties.map((p) => DropdownMenuItem(value: p.id, child: Text(p.address))).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedPropertyId = val);
                                  if (val != null) _onPropertySelected(properties.firstWhere((p) => p.id == val));
                                },
                                validator: (val) => val == null ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add_circle, color: Color(0xFF6A1B9A)),
                              label: const Text('Add New', style: TextStyle(color: Color(0xFF6A1B9A))),
                              onPressed: _showAddPropertyDialog,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF6A1B9A)),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: 'Select Tenant Profile', border: OutlineInputBorder()),
                                value: tenantsList.any((t) => t.id == _selectedTenantId) ? _selectedTenantId : null,
                                items: tenantsList.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.name} (${t.mobile})'))).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedTenantId = val);
                                },
                                validator: (val) =>
                                    val == null ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.person_add, color: Color(0xFF6A1B9A)),
                              label: const Text('Add New', style: TextStyle(color: Color(0xFF6A1B9A))),
                              onPressed: _showAddTenantDialog,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF6A1B9A)),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _agreementNumController,
                          decoration: const InputDecoration(
                            labelText: 'Agreement Number (Auto-Generated)',
                            border: OutlineInputBorder(),
                          ),
                          readOnly:
                              true, // Make it read-only since it's auto-generated
                          validator: (val) =>
                              val!.isEmpty ? 'Generating...' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _monthlyRentController,
                                decoration: const InputDecoration(
                                  labelText: 'Monthly Rent (₹)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (val) =>
                                    val!.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _depositController,
                                decoration: const InputDecoration(
                                  labelText: 'Deposit Amount (₹)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (val) =>
                                    val!.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                title: const Text('Start Date'),
                                subtitle: Text(
                                  '${_startDate.toLocal()}'.split(' ')[0],
                                ),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (d != null) setState(() => _startDate = d);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: '11',
                                decoration: const InputDecoration(
                                  labelText: 'Period (Months)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  if (val.isNotEmpty)
                                    setState(
                                      () => _periodMonths = int.parse(val),
                                    );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Calculated End Date: ${_expiryDate.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
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
                        _buildPersonReuseSearch(
                          role: 'owner',
                          hint: 'Search existing Owner',
                          onSelected: _applyOwnerRecord,
                        ),
                        TextFormField(
                          controller: _ownerName,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                          ),
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Date of Birth'),
                          subtitle: Text(
                            '${_ownerDob.toLocal()}'.split(' ')[0],
                          ),
                          trailing: Text(
                            'Age: $_ownerCalculatedAge',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _ownerDob,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setState(() => _ownerDob = d);
                          },
                        ),
                        TextFormField(
                          controller: _ownerAddress,
                          decoration: const InputDecoration(
                            labelText: 'Full Address',
                          ),
                          maxLines: 2,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _ownerPin,
                          decoration: const InputDecoration(
                            labelText: 'Pincode',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        TextFormField(
                          controller: _ownerPan,
                          decoration: const InputDecoration(
                            labelText: 'PAN Number',
                          ),
                        ),
                        TextFormField(
                          controller: _ownerAadhaar,
                          decoration: const InputDecoration(
                            labelText: 'Aadhaar Number',
                          ),
                          keyboardType: TextInputType.number,
                        ),
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
                        TextFormField(
                          controller: _tenantName,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                          ),
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Date of Birth'),
                          subtitle: Text(
                            '${_tenantDob.toLocal()}'.split(' ')[0],
                          ),
                          trailing: Text(
                            'Age: $_tenantCalculatedAge',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _tenantDob,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setState(() => _tenantDob = d);
                          },
                        ),
                        TextFormField(
                          controller: _tenantAddress,
                          decoration: const InputDecoration(
                            labelText: 'Full Address',
                          ),
                          maxLines: 2,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _tenantPin,
                          decoration: const InputDecoration(
                            labelText: 'Pincode',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        TextFormField(
                          controller: _tenantPan,
                          decoration: const InputDecoration(
                            labelText: 'PAN Number',
                          ),
                        ),
                        TextFormField(
                          controller: _tenantAadhaar,
                          decoration: const InputDecoration(
                            labelText: 'Aadhaar Number',
                          ),
                          keyboardType: TextInputType.number,
                        ),
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
                        const Text(
                          'Witness 1',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        _buildPersonReuseSearch(
                          role: 'witness',
                          hint: 'Search existing Witness',
                          onSelected: _applyWitness1Record,
                        ),
                        TextFormField(
                          controller: _w1Name,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Date of Birth'),
                          subtitle: Text('${_w1Dob.toLocal()}'.split(' ')[0]),
                          trailing: Text(
                            'Age: $_w1CalculatedAge',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _w1Dob,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setState(() => _w1Dob = d);
                          },
                        ),
                        TextFormField(
                          controller: _w1Address,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                          ),
                        ),
                        TextFormField(
                          controller: _w1Aadhaar,
                          decoration: const InputDecoration(
                            labelText: 'Aadhaar',
                          ),
                        ),
                        const Divider(height: 32),
                        const Text(
                          'Witness 2',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        _buildPersonReuseSearch(
                          role: 'witness',
                          hint: 'Search existing Witness',
                          onSelected: _applyWitness2Record,
                        ),
                        TextFormField(
                          controller: _w2Name,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Date of Birth'),
                          subtitle: Text('${_w2Dob.toLocal()}'.split(' ')[0]),
                          trailing: Text(
                            'Age: $_w2CalculatedAge',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _w2Dob,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setState(() => _w2Dob = d);
                          },
                        ),
                        TextFormField(
                          controller: _w2Address,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                          ),
                        ),
                        TextFormField(
                          controller: _w2Aadhaar,
                          decoration: const InputDecoration(
                            labelText: 'Aadhaar',
                          ),
                        ),
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

/// Debounced type-ahead search box for finding an existing Owner or Witness
/// by name, Aadhaar, or PAN. Shows up to 8 matches in a dropdown-style list;
/// tapping one calls [onSelected] so the caller can auto-fill its form.
class _PersonReuseSearchField extends StatefulWidget {
  final String role;
  final String hint;
  final void Function(AgreementPersonRecord) onSelected;
  final AdminService adminService;

  const _PersonReuseSearchField({
    required this.role,
    required this.hint,
    required this.onSelected,
    required this.adminService,
  });

  @override
  State<_PersonReuseSearchField> createState() => _PersonReuseSearchFieldState();
}

class _PersonReuseSearchFieldState extends State<_PersonReuseSearchField> {
  final _controller = TextEditingController();
  List<AgreementPersonRecord> _results = [];
  bool _isSearching = false;
  bool _showResults = false;

  void _onChanged(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await widget.adminService.searchAgreementPeople(widget.role, query.trim());
      if (mounted) {
        setState(() {
          _results = results;
          _showResults = true;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.hint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
            border: const OutlineInputBorder(),
            helperText: 'Search by name, Aadhaar, or PAN to reuse a saved record',
          ),
          onChanged: _onChanged,
        ),
        if (_showResults && _results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = _results[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_outline),
                  title: Text(r.name),
                  subtitle: Text(
                    [
                      if (r.aadhaar.isNotEmpty) 'Aadhaar: ${r.aadhaar}',
                      if (r.pan.isNotEmpty) 'PAN: ${r.pan}',
                    ].join('  •  '),
                  ),
                  onTap: () {
                    widget.onSelected(r);
                    setState(() {
                      _controller.text = r.name;
                      _showResults = false;
                    });
                  },
                );
              },
            ),
          )
        else if (_showResults && _results.isEmpty && !_isSearching)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'No match found — fill in the fields below to save a new record',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

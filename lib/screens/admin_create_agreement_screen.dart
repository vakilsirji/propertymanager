import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

const List<String> kMaharashtraDistricts = [
  'Mumbai City', 'Mumbai Suburban', 'Thane', 'Palghar', 'Raigad', 'Pune',
  'Nashik', 'Ahmednagar', 'Solapur', 'Satara', 'Sangli', 'Kolhapur',
  'Nagpur', 'Aurangabad', 'Other',
];

const List<String> kPropertyAttributeTypes = [
  'Survey Number', 'Plot Number', 'Khata Number', 'CTS Number', 'Milkat Number',
];

const List<String> kUnitTypes = [
  'Apartment/Flat', 'Godown', 'Land+Building/Shed', 'Office Shop',
];

const List<String> kAreaUnits = ['Square Feet', 'Square Meter'];

class AdminCreateAgreementScreen extends ConsumerStatefulWidget {
  final Lead? prefillLead;
  const AdminCreateAgreementScreen({Key? key, this.prefillLead}) : super(key: key);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.prefillLead != null) {
        // Property address from the lead pre-fills the free-text fallback
        // field; the structured govt fields below still need to be filled
        // in by the executive since a lead only carries a plain address.
        _propertyAddressFallback.text = widget.prefillLead!.propertyAddress;
        _promptForPrefillRole();
      }
    });
  }

  void _promptForPrefillRole() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Auto-Fill Lead Details'),
          content: Text('Is ${widget.prefillLead!.clientName} the Owner or the Tenant?'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _ownerName.text = widget.prefillLead!.clientName;
                  _ownerAddress.text = widget.prefillLead!.propertyAddress;
                });
                Navigator.pop(context);
              },
              child: const Text('Owner'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _tenantName.text = widget.prefillLead!.clientName;
                  _tenantAddress.text = widget.prefillLead!.propertyAddress;
                });
                Navigator.pop(context);
              },
              child: const Text('Tenant'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
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

  // ─── Step 0: Property Details (government eRegistration fields) ───
  final _propertyFormKey = GlobalKey<FormState>();
  String? _selectedPropertyId; // set once an existing property is chosen, or after a new one is created
  bool _isCreatingNewProperty = true;

  final _districtController = TextEditingController();
  final _talukaController = TextEditingController();
  final _villageController = TextEditingController();
  String _areaType = 'Urban';
  final _localLimitController = TextEditingController();
  String _attributeType = kPropertyAttributeTypes.first;
  final _attributeNumberController = TextEditingController();
  String _unitType = kUnitTypes.first;
  final _unitAreaController = TextEditingController();
  String _unitAreaUnit = kAreaUnits.first;
  final _buildingNameController = TextEditingController();
  final _flatNoController = TextEditingController();
  final _floorNoController = TextEditingController();
  final _roadController = TextEditingController();
  final _locationController = TextEditingController();
  String _useType = 'Residential';
  final _galleryAreaController = TextEditingController();
  final _parkingAreaController = TextEditingController();
  final _policeStationController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _propertyOwnerNameFallback = TextEditingController(); // legacy owner_name column
  final _propertyAddressFallback = TextEditingController(); // legacy address column, auto-built below

  /// Builds the legacy single-line `address` string from the structured
  /// fields, so older screens that still read `properties.address` keep
  /// working without modification.
  String _composeAddressFromFields() {
    final parts = [
      _buildingNameController.text,
      if (_flatNoController.text.isNotEmpty) 'Flat ${_flatNoController.text}',
      if (_floorNoController.text.isNotEmpty) '${_floorNoController.text} Floor',
      _roadController.text,
      _locationController.text,
      _villageController.text,
      _talukaController.text,
      _districtController.text,
      _pincodeController.text,
    ].where((p) => p.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  Future<void> _saveOrSelectProperty() async {
    if (!_isCreatingNewProperty) return; // already picked an existing one
    if (!_propertyFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final id = await ref.read(adminServiceProvider).createProperty(
            _composeAddressFromFields(),
            _propertyOwnerNameFallback.text.isNotEmpty ? _propertyOwnerNameFallback.text : _ownerName.text,
            district: _districtController.text,
            taluka: _talukaController.text,
            village: _villageController.text,
            areaType: _areaType,
            localLimitName: _localLimitController.text,
            propertyAttributeType: _attributeType,
            propertyAttributeNumber: _attributeNumberController.text,
            unitType: _unitType,
            unitArea: _unitAreaController.text,
            unitAreaUnit: _unitAreaUnit,
            buildingName: _buildingNameController.text,
            flatNo: _flatNoController.text,
            floorNo: _floorNoController.text,
            road: _roadController.text,
            location: _locationController.text,
            useType: _useType,
            galleryArea: _galleryAreaController.text,
            parkingArea: _parkingAreaController.text,
            policeStation: _policeStationController.text,
            pincode: _pincodeController.text,
          );
      ref.invalidate(propertiesStreamProvider);
      setState(() {
        _selectedPropertyId = id;
        _currentStep = 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving property: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Fills the Property Details form from a previously-saved Property, used
  /// when the executive picks "use an existing property" instead of typing
  /// fresh government fields every time.
  void _applyExistingProperty(Property p) {
    setState(() {
      _isCreatingNewProperty = false;
      _selectedPropertyId = p.id;
      _districtController.text = p.district ?? '';
      _talukaController.text = p.taluka ?? '';
      _villageController.text = p.village ?? '';
      _areaType = p.areaType ?? 'Urban';
      _localLimitController.text = p.localLimitName ?? '';
      _attributeType = p.propertyAttributeType ?? kPropertyAttributeTypes.first;
      _attributeNumberController.text = p.propertyAttributeNumber ?? '';
      _unitType = p.unitType ?? kUnitTypes.first;
      _unitAreaController.text = p.unitArea ?? '';
      _unitAreaUnit = p.unitAreaUnit ?? kAreaUnits.first;
      _buildingNameController.text = p.buildingName ?? '';
      _flatNoController.text = p.flatNo ?? '';
      _floorNoController.text = p.floorNo ?? '';
      _roadController.text = p.road ?? '';
      _locationController.text = p.location ?? '';
      _useType = p.useType ?? 'Residential';
      _galleryAreaController.text = p.galleryArea ?? '';
      _parkingAreaController.text = p.parkingArea ?? '';
      _policeStationController.text = p.policeStation ?? '';
      _pincodeController.text = p.pincode ?? '';
      _propertyOwnerNameFallback.text = p.ownerName;
      _ownerName.text = p.ownerName;
    });
  }

  // ─── Step 1: Agreement Terms ───
  final _basicsFormKey = GlobalKey<FormState>();
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

  // ─── Step 2: Owner Details ───
  final _ownerFormKey = GlobalKey<FormState>();
  final _ownerName = TextEditingController();
  final _ownerAddress = TextEditingController();
  final _ownerPin = TextEditingController();
  final _ownerPan = TextEditingController();
  final _ownerAadhaar = TextEditingController();
  DateTime _ownerDob = DateTime.now().subtract(const Duration(days: 365 * 30));
  int get _ownerCalculatedAge => calculateAgeFromDob(_ownerDob);

  // ─── Step 3: Tenant Details ───
  final _tenantFormKey = GlobalKey<FormState>();
  final _tenantName = TextEditingController();
  final _tenantAddress = TextEditingController();
  final _tenantPin = TextEditingController();
  final _tenantPan = TextEditingController();
  final _tenantAadhaar = TextEditingController();
  DateTime _tenantDob = DateTime.now().subtract(const Duration(days: 365 * 30));
  int get _tenantCalculatedAge => calculateAgeFromDob(_tenantDob);

  // ─── Step 4: Witnesses ───
  final _witnessesFormKey = GlobalKey<FormState>();
  final _w1Name = TextEditingController();
  final _w1Address = TextEditingController();
  final _w1Aadhaar = TextEditingController();
  DateTime _w1Dob = DateTime.now().subtract(const Duration(days: 365 * 30));
  int get _w1CalculatedAge => calculateAgeFromDob(_w1Dob);

  final _w2Name = TextEditingController();
  final _w2Address = TextEditingController();
  final _w2Aadhaar = TextEditingController();
  DateTime _w2Dob = DateTime.now().subtract(const Duration(days: 365 * 30));
  int get _w2CalculatedAge => calculateAgeFromDob(_w2Dob);

  void _onTenantSelected(UserModel t) {
    _tenantName.text = t.name;
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
    if (_selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete Property Details first (Step 1).')),
      );
      setState(() => _currentStep = 0);
      return;
    }

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

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(labelText: label, hintText: hint);
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesStreamProvider);
    final customersAsync = ref.watch(customersStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.parchment,
      appBar: AppBar(
        title: Text('Create Draft Agreement', style: AppTheme.display(fontSize: 17, color: Colors.white)),
        backgroundColor: AppTheme.ink,
      ),
      body: propertiesAsync.when(
        data: (properties) => customersAsync.when(
          data: (customers) {
            final tenantsList = customers
                .where((c) => c.role == 'tenant')
                .toList();
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.terracotta),
              ),
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () async {
                  bool isValid = false;
                  switch (_currentStep) {
                    case 0:
                      await _saveOrSelectProperty();
                      return; // _saveOrSelectProperty advances the step itself on success
                    case 1:
                      isValid = _basicsFormKey.currentState!.validate();
                      break;
                    case 2:
                      isValid = _ownerFormKey.currentState!.validate();
                      break;
                    case 3:
                      isValid = _tenantFormKey.currentState!.validate();
                      break;
                    case 4:
                      isValid = _witnessesFormKey.currentState!.validate();
                      if (isValid) _submit();
                      break;
                  }
                  if (isValid && _currentStep < 4) {
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
                  if (_isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppTheme.terracotta),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.terracotta),
                          child: Text(_currentStep == 4 ? 'Save Draft' : 'Next'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: Text(
                            _currentStep == 0 ? 'Cancel' : 'Back',
                            style: AppTheme.body(color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                steps: [
                  // ─── STEP 0: PROPERTY DETAILS ───
                  Step(
                    title: Text('Property Details', style: AppTheme.display(fontSize: 16)),
                    subtitle: Text('Government eRegistration fields', style: AppTheme.body(fontSize: 12, color: AppTheme.textSecondary)),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    content: Form(
                      key: _propertyFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (properties.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DropdownButtonFormField<String>(
                                decoration: _fieldDecoration('Use an existing property (optional)'),
                                value: !_isCreatingNewProperty && properties.any((p) => p.id == _selectedPropertyId) ? _selectedPropertyId : null,
                                items: properties
                                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.address, overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  final p = properties.firstWhere((p) => p.id == val);
                                  _applyExistingProperty(p);
                                },
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => setState(() => _isCreatingNewProperty = true),
                                  icon: const Icon(Icons.add_circle_outline, size: 16),
                                  label: const Text('Enter a new property'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _isCreatingNewProperty ? AppTheme.terracotta : AppTheme.textSecondary,
                                    side: BorderSide(color: _isCreatingNewProperty ? AppTheme.terracotta : AppTheme.border),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_isCreatingNewProperty) ...[
                            Text('Location', style: AppTheme.display(fontSize: 13)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: _fieldDecoration('District'),
                              value: kMaharashtraDistricts.contains(_districtController.text) ? _districtController.text : null,
                              items: kMaharashtraDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                              onChanged: (val) => setState(() => _districtController.text = val ?? ''),
                              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _talukaController,
                                    decoration: _fieldDecoration('Taluka'),
                                    validator: (val) => val!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _villageController,
                                    decoration: _fieldDecoration('Village'),
                                    validator: (val) => val!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: _fieldDecoration('Area'),
                                    value: _areaType,
                                    items: const ['Urban', 'Rural'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                                    onChanged: (val) => setState(() => _areaType = val ?? 'Urban'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _localLimitController,
                                    decoration: _fieldDecoration('Local Limit Name'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pincodeController,
                              decoration: _fieldDecoration('Pincode'),
                              keyboardType: TextInputType.number,
                              validator: (val) => val!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _policeStationController,
                              decoration: _fieldDecoration('Police Station'),
                              validator: (val) => val!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            Text('Property identification', style: AppTheme.display(fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    decoration: _fieldDecoration('Attribute Type'),
                                    value: _attributeType,
                                    items: kPropertyAttributeTypes.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (val) => setState(() => _attributeType = val ?? kPropertyAttributeTypes.first),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _attributeNumberController,
                                    decoration: _fieldDecoration('Number'),
                                    validator: (val) => val!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    decoration: _fieldDecoration('Type of Unit'),
                                    value: _unitType,
                                    items: kUnitTypes.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (val) => setState(() => _unitType = val ?? kUnitTypes.first),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _unitAreaController,
                                    decoration: _fieldDecoration('Unit Area'),
                                    keyboardType: TextInputType.number,
                                    validator: (val) => val!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              decoration: _fieldDecoration('Area Unit'),
                              value: _unitAreaUnit,
                              items: kAreaUnits.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                              onChanged: (val) => setState(() => _unitAreaUnit = val ?? kAreaUnits.first),
                            ),
                            const SizedBox(height: 20),
                            Text('Address', style: AppTheme.display(fontSize: 13)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _buildingNameController,
                              decoration: _fieldDecoration('Building Name'),
                              validator: (val) => val!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _flatNoController,
                                    decoration: _fieldDecoration('Flat / Unit No.'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _floorNoController,
                                    decoration: _fieldDecoration('Floor No.'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _roadController,
                              decoration: _fieldDecoration('Road'),
                              validator: (val) => val!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _locationController,
                              decoration: _fieldDecoration('Location'),
                              validator: (val) => val!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            Text('Use & extras', style: AppTheme.display(fontSize: 13)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: _fieldDecoration('Use of Property'),
                              value: _useType,
                              items: const ['Residential', 'Non-Residential'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                              onChanged: (val) => setState(() => _useType = val ?? 'Residential'),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _galleryAreaController,
                                    decoration: _fieldDecoration('Gallery Area (optional)'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _parkingAreaController,
                                    decoration: _fieldDecoration('Parking Area (optional)'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _propertyOwnerNameFallback,
                              decoration: _fieldDecoration('Owner Name (for property record)'),
                            ),
                          ] else
                            Text(
                              'Property selected from the list above. Continue to the next step.',
                              style: AppTheme.body(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ─── STEP 1: AGREEMENT TERMS ───
                  Step(
                    title: Text('Agreement Terms', style: AppTheme.display(fontSize: 16)),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    content: Form(
                      key: _basicsFormKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: _fieldDecoration('Select Tenant Profile'),
                                  value: tenantsList.any((t) => t.id == _selectedTenantId) ? _selectedTenantId : null,
                                  items: tenantsList.map((t) => DropdownMenuItem(value: t.id, child: Text('${t.name} (${t.mobile})'))).toList(),
                                  onChanged: (val) {
                                    setState(() => _selectedTenantId = val);
                                  },
                                  validator: (val) => val == null ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.person_add, color: AppTheme.terracotta, size: 18),
                                label: Text('Add New', style: AppTheme.body(color: AppTheme.terracotta, fontWeight: FontWeight.w600)),
                                onPressed: _showAddTenantDialog,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.terracotta),
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _agreementNumController,
                            decoration: _fieldDecoration('Agreement Number (Auto-Generated)'),
                            readOnly: true,
                            validator: (val) => val!.isEmpty ? 'Generating...' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _monthlyRentController,
                                  decoration: _fieldDecoration('Monthly Rent (₹)'),
                                  keyboardType: TextInputType.number,
                                  validator: (val) => val!.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _depositController,
                                  decoration: _fieldDecoration('Deposit Amount (₹)'),
                                  keyboardType: TextInputType.number,
                                  validator: (val) => val!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(color: AppTheme.border),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  tileColor: AppTheme.cardSurface,
                                  title: Text('Start Date', style: AppTheme.body(fontSize: 12, color: AppTheme.textSecondary)),
                                  subtitle: Text('${_startDate.toLocal()}'.split(' ')[0], style: AppTheme.body(fontWeight: FontWeight.w600)),
                                  trailing: const Icon(Icons.calendar_today, size: 18, color: AppTheme.terracotta),
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
                                  decoration: _fieldDecoration('Period (Months)'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    if (val.isNotEmpty) setState(() => _periodMonths = int.parse(val));
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Calculated end date: ${_expiryDate.toLocal().toString().split(' ')[0]}',
                              style: AppTheme.body(fontWeight: FontWeight.w600, color: AppTheme.sage),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── STEP 2: OWNER DETAILS ───
                  Step(
                    title: Text('Owner Details', style: AppTheme.display(fontSize: 16)),
                    isActive: _currentStep >= 2,
                    state: _currentStep > 2 ? StepState.complete : StepState.indexed,
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
                            decoration: _fieldDecoration('Full Name'),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            tileColor: AppTheme.cardSurface,
                            title: Text('Date of Birth', style: AppTheme.body(fontSize: 12, color: AppTheme.textSecondary)),
                            subtitle: Text('${_ownerDob.toLocal()}'.split(' ')[0], style: AppTheme.body(fontWeight: FontWeight.w600)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: AppTheme.sageLight, borderRadius: BorderRadius.circular(8)),
                              child: Text('Age $_ownerCalculatedAge', style: AppTheme.body(fontWeight: FontWeight.w700, color: AppTheme.sage, fontSize: 13)),
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _ownerAddress,
                            decoration: _fieldDecoration('Full Address'),
                            maxLines: 2,
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _ownerPin,
                            decoration: _fieldDecoration('Pincode'),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _ownerPan,
                            decoration: _fieldDecoration('PAN Number'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _ownerAadhaar,
                            decoration: _fieldDecoration('Aadhaar Number'),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── STEP 3: TENANT DETAILS ───
                  Step(
                    title: Text('Tenant Details', style: AppTheme.display(fontSize: 16)),
                    isActive: _currentStep >= 3,
                    state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                    content: Form(
                      key: _tenantFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _tenantName,
                            decoration: _fieldDecoration('Full Name'),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            tileColor: AppTheme.cardSurface,
                            title: Text('Date of Birth', style: AppTheme.body(fontSize: 12, color: AppTheme.textSecondary)),
                            subtitle: Text('${_tenantDob.toLocal()}'.split(' ')[0], style: AppTheme.body(fontWeight: FontWeight.w600)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: AppTheme.sageLight, borderRadius: BorderRadius.circular(8)),
                              child: Text('Age $_tenantCalculatedAge', style: AppTheme.body(fontWeight: FontWeight.w700, color: AppTheme.sage, fontSize: 13)),
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _tenantAddress,
                            decoration: _fieldDecoration('Full Address'),
                            maxLines: 2,
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _tenantPin,
                            decoration: _fieldDecoration('Pincode'),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _tenantPan,
                            decoration: _fieldDecoration('PAN Number'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _tenantAadhaar,
                            decoration: _fieldDecoration('Aadhaar Number'),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── STEP 4: WITNESSES ───
                  Step(
                    title: Text('Witnesses', style: AppTheme.display(fontSize: 16)),
                    isActive: _currentStep >= 4,
                    state: StepState.indexed,
                    content: Form(
                      key: _witnessesFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Witness 1', style: AppTheme.display(fontSize: 14)),
                          const SizedBox(height: 8),
                          _buildPersonReuseSearch(
                            role: 'witness',
                            hint: 'Search existing Witness',
                            onSelected: _applyWitness1Record,
                          ),
                          TextFormField(
                            controller: _w1Name,
                            decoration: _fieldDecoration('Name'),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            tileColor: AppTheme.cardSurface,
                            title: Text('Date of Birth', style: AppTheme.body(fontSize: 12, color: AppTheme.textSecondary)),
                            subtitle: Text('${_w1Dob.toLocal()}'.split(' ')[0], style: AppTheme.body(fontWeight: FontWeight.w600)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: AppTheme.sageLight, borderRadius: BorderRadius.circular(8)),
                              child: Text('Age $_w1CalculatedAge', style: AppTheme.body(fontWeight: FontWeight.w700, color: AppTheme.sage, fontSize: 13)),
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _w1Address,
                            decoration: _fieldDecoration('Address'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _w1Aadhaar,
                            decoration: _fieldDecoration('Aadhaar'),
                          ),
                          Divider(height: 32, color: AppTheme.border),
                          Text('Witness 2', style: AppTheme.display(fontSize: 14)),
                          const SizedBox(height: 8),
                          _buildPersonReuseSearch(
                            role: 'witness',
                            hint: 'Search existing Witness',
                            onSelected: _applyWitness2Record,
                          ),
                          TextFormField(
                            controller: _w2Name,
                            decoration: _fieldDecoration('Name'),
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            tileColor: AppTheme.cardSurface,
                            title: Text('Date of Birth', style: AppTheme.body(fontSize: 12, color: AppTheme.textSecondary)),
                            subtitle: Text('${_w2Dob.toLocal()}'.split(' ')[0], style: AppTheme.body(fontWeight: FontWeight.w600)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: AppTheme.sageLight, borderRadius: BorderRadius.circular(8)),
                              child: Text('Age $_w2CalculatedAge', style: AppTheme.body(fontWeight: FontWeight.w700, color: AppTheme.sage, fontSize: 13)),
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _w2Address,
                            decoration: _fieldDecoration('Address'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _w2Aadhaar,
                            decoration: _fieldDecoration('Aadhaar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.terracotta)),
          error: (e, s) => Center(child: Text('Error loading customers: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.terracotta)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.hint,
              prefixIcon: const Icon(Icons.search, color: AppTheme.terracotta, size: 20),
              helperText: 'Search by name, Aadhaar, or PAN to reuse a saved record',
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.terracotta)),
                    )
                  : null,
            ),
            onChanged: _onChanged,
          ),
          if (_showResults && _results.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.cardSurface,
              ),
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.border),
                itemBuilder: (context, i) {
                  final r = _results[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.person_outline, color: AppTheme.terracotta),
                    title: Text(r.name, style: AppTheme.body(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      [
                        if (r.aadhaar.isNotEmpty) 'Aadhaar: ${r.aadhaar}',
                        if (r.pan.isNotEmpty) 'PAN: ${r.pan}',
                      ].join('  •  '),
                      style: AppTheme.body(fontSize: 12, color: AppTheme.textSecondary),
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
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'No match found — fill in the fields below to save a new record',
                style: AppTheme.body(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

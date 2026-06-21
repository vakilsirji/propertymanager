import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_models.dart';
import '../models/models.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.watch(supabaseClientProvider));
});

// Stream Providers for Real-time Data
final leadsStreamProvider = StreamProvider<List<Lead>>((ref) {
  return ref.watch(supabaseClientProvider).from('leads').stream(primaryKey: ['id']).map(
    (data) => data.map((e) => Lead.fromMap(e)).toList(),
  );
});

final agreementsStreamProvider = StreamProvider<List<Agreement>>((ref) {
  return ref.watch(supabaseClientProvider).from('agreements').stream(primaryKey: ['id']).map(
    (data) => data.map((e) => Agreement.fromMap(e)).toList(),
  );
});

final draftAgreementsStreamProvider = StreamProvider<List<Agreement>>((ref) {
  return ref.watch(supabaseClientProvider).from('agreements').stream(primaryKey: ['id']).eq('status', 'Draft').map(
    (data) => data.map((e) => Agreement.fromMap(e)).toList(),
  );
});

final propertiesStreamProvider = StreamProvider<List<Property>>((ref) {
  return ref.watch(supabaseClientProvider).from('properties').stream(primaryKey: ['id']).map(
    (data) => data.map((e) => Property.fromMap(e)).toList(),
  );
});

final paymentsStreamProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(supabaseClientProvider).from('payments').stream(primaryKey: ['id']).map(
    (data) => data.map((e) => Payment.fromMap(e)).toList(),
  );
});

final biometricVisitsStreamProvider = StreamProvider<List<BiometricVisit>>((ref) {
  return ref.watch(supabaseClientProvider).from('biometric_visits').stream(primaryKey: ['id']).map(
    (data) => data.map((e) => BiometricVisit.fromMap(e)).toList(),
  );
});

final renewalLeadsStreamProvider = StreamProvider<List<RenewalLead>>((ref) {
  return ref.watch(supabaseClientProvider).from('renewal_leads').stream(primaryKey: ['id']).map(
    (data) => data.map((e) => RenewalLead.fromMap(e)).toList(),
  );
});

final customersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(supabaseClientProvider)
      .from('users')
      .stream(primaryKey: ['id'])
      .map((data) => data
          .map((e) => UserModel.fromMap(e))
          .where((u) => u.role == 'owner' || u.role == 'tenant')
          .toList());
});

class AdminService {
  final SupabaseClient _client;

  AdminService(this._client);

  /// Fetch leads created today (simple implementation – returns all leads).
  Future<List<Lead>> fetchTodayLeads() async {
    final data = await _client.from('leads').select();
    return (data as List<dynamic>)
        .map((e) => Lead.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Update the status of a lead.
  Future<void> updateLeadStatus(String leadId, String newStatus) async {
    await _client.from('leads').update({'status': newStatus}).eq('id', leadId);
  }

  /// Fetch all agreements.
  Future<List<Agreement>> fetchAllAgreements() async {
    final data = await _client.from('agreements').select();
    return (data as List<dynamic>)
        .map((e) => Agreement.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch agreements that are in Draft status.
  Future<List<Agreement>> fetchDraftAgreements() async {
    final data = await _client.from('agreements').select().eq('status', 'Draft');
    return (data as List<dynamic>)
        .map((e) => Agreement.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all properties
  Future<List<Property>> fetchProperties() async {
    final data = await _client.from('properties').select();
    return (data as List<dynamic>)
        .map((e) => Property.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // --- Form Actions ---

  /// Create a new Draft Agreement
  Future<void> createAgreement({
    required String propertyId,
    required String tenantId,
    required DateTime startDate,
    required DateTime expiryDate,
    required String agreementNumber,
    required Map<String, dynamic> details,
  }) async {
    // The tenantId passed here is the user UUID. We must create a 'tenants' record first.
    final aadhaar = details['tenant']['aadhaar'] as String? ?? '0000';
    final last4 = aadhaar.length >= 4 ? aadhaar.substring(aadhaar.length - 4) : '0000';

    final tenantRes = await _client.from('tenants').insert({
      'property_id': propertyId,
      'user_id': tenantId,
      'aadhaar_last4': last4,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': expiryDate.toIso8601String().split('T')[0],
    }).select('id').single();

    final realTenantId = tenantRes['id'];

    await _client.from('agreements').insert({
      'property_id': propertyId,
      'tenant_id': realTenantId, // The BIGINT id from the tenants table
      'start_date': startDate.toIso8601String().split('T')[0],
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'agreement_number': agreementNumber,
      'status': 'Draft',
      'details': details,
    });
  }

  /// Update agreement status
  Future<void> updateAgreementStatus(String agreementId, String newStatus) async {
    await _client.from('agreements').update({'status': newStatus}).eq('id', agreementId);
  }

  /// File IGR (Update status to IGR Filed or similar)
  Future<void> fileIgr(String agreementId, String tokenNumber) async {
    // In a real app, you might save the tokenNumber in a column.
    // For now, we update the status.
    await updateAgreementStatus(agreementId, 'IGR Filed: $tokenNumber');
  }

  /// Complete Registration
  Future<void> completeRegistration(String agreementId, String regNumber) async {
    // Update status to 'Registered'
    await updateAgreementStatus(agreementId, 'Registered: $regNumber');
  }

  /// Assign a vendor for biometric visit
  Future<void> assignVendor(String agreementId, String vendorId, String vendorName, DateTime visitDate) async {
    await _client.from('biometric_visits').insert({
      'agreement_id': agreementId,
      'vendor_name': vendorName,
      'visit_date': visitDate.toIso8601String().split('T')[0],
      'status': 'Assigned',
    });
  }
}


import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_models.dart';
import '../models/models.dart';
import 'pdf_service.dart';

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

  /// Create a new Lead
  Future<void> createLead(String clientName, String phone, String address) async {
    await _client.from('leads').insert({
      'client_name': clientName,
      'phone': phone,
      'property_address': address,
      'status': 'New',
    });
  }

  /// Fetch all leads
  Future<List<Lead>> fetchLeads() async {
    final response = await _client
        .from('leads')
        .select()
        .order('created_at', ascending: false);
    
    final leads = (response as List).map((map) => Lead.fromMap(map)).toList();

    // Enrich with Owner data based on property address
    for (var i = 0; i < leads.length; i++) {
       final lead = leads[i];
       
       try {
         // Find property matching this address
         final propRes = await _client.from('properties').select('owner_id').eq('address', lead.propertyAddress).maybeSingle();
         if (propRes != null && propRes['owner_id'] != null) {
            final userRes = await _client.from('users').select('name, mobile').eq('id', propRes['owner_id']).maybeSingle();
            if (userRes != null) {
                leads[i] = lead.copyWith(
                   ownerName: userRes['name'],
                   ownerPhone: userRes['mobile'],
                );
            }
         }
       } catch (e) {
         // Silently fail for individual lead enrichment, just means owner info will be null
       }
    }
    
    return leads;
  }

  /// Fetch Lead Documents
  Future<List<LeadDocument>> fetchLeadDocuments(String leadId) async {
    final data = await _client.from('lead_documents').select().eq('lead_id', leadId).order('created_at', ascending: true);
    return (data as List<dynamic>).map((e) => LeadDocument.fromMap(e as Map<String, dynamic>)).toList();
  }

  /// Upload Lead Document (Web compatible bytes)
  Future<void> uploadLeadDocument(String leadId, String docType, String fileName, List<int> bytes) async {
    final path = 'lead_$leadId/$fileName';
    await _client.storage.from('lead_documents').uploadBinary(path, Uint8List.fromList(bytes));
    
    final fileUrl = _client.storage.from('lead_documents').getPublicUrl(path);

    await _client.from('lead_documents').insert({
      'lead_id': leadId,
      'document_type': docType,
      'file_url': fileUrl,
    });
  }

  /// Search existing Owner/Witness people by name, Aadhaar, or PAN.
  /// [role] is 'owner' or 'witness'. Returns up to 8 closest matches.
  Future<List<AgreementPersonRecord>> searchAgreementPeople(String role, String query) async {
    if (query.trim().isEmpty) return [];
    final data = await _client
        .from('agreement_people')
        .select()
        .eq('role', role)
        .or('name.ilike.%$query%,aadhaar.ilike.%$query%,pan.ilike.%$query%')
        .limit(8);
    return (data as List<dynamic>)
        .map((e) => AgreementPersonRecord.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Save (or update, if already on file by Aadhaar/PAN) an Owner/Witness
  /// person record so they can be found and reused on a future agreement.
  Future<void> saveAgreementPerson({
    required String role,
    required String name,
    required String address,
    required String pincode,
    required String pan,
    required String aadhaar,
    required DateTime? dob,
  }) async {
    final payload = {
      'role': role,
      'name': name,
      'address': address,
      'pincode': pincode,
      'pan': pan,
      'aadhaar': aadhaar,
      'dob': dob?.toIso8601String().split('T')[0],
    };

    // Try to find an existing record for this person (match on Aadhaar first,
    // then PAN) so repeat agreements update rather than duplicate them.
    String? existingId;
    if (aadhaar.trim().isNotEmpty) {
      final match = await _client
          .from('agreement_people')
          .select('id')
          .eq('role', role)
          .eq('aadhaar', aadhaar)
          .maybeSingle();
      existingId = match?['id']?.toString();
    }
    if (existingId == null && pan.trim().isNotEmpty) {
      final match = await _client
          .from('agreement_people')
          .select('id')
          .eq('role', role)
          .eq('pan', pan)
          .maybeSingle();
      existingId = match?['id']?.toString();
    }

    if (existingId != null) {
      await _client.from('agreement_people').update(payload).eq('id', existingId);
    } else {
      await _client.from('agreement_people').insert(payload);
    }
  }

  /// Update the status of a lead.
  Future<void> updateLeadStatus(String leadId, String newStatus) async {
    await _client.from('leads').update({'status': newStatus}).eq('id', leadId);
  }

  /// Update the status of an agreement and record it in the timeline.
  Future<void> updateAgreementStatusWithTimeline(String agreementId, String newStatus, {String? description}) async {
    // 1. Update the agreement status
    await _client.from('agreements').update({'status': newStatus}).eq('id', agreementId);
    // 2. Insert into timeline
    await _client.from('agreement_timeline').insert({
      'agreement_id': agreementId,
      'status_step': newStatus,
      if (description != null) 'description': description,
    });
  }

  /// Fetch the timeline events for a specific agreement
  Future<List<AgreementTimelineEvent>> fetchAgreementTimeline(String agreementId) async {
    final data = await _client
        .from('agreement_timeline')
        .select()
        .eq('agreement_id', agreementId)
        .order('created_at', ascending: true);
    return (data as List<dynamic>)
        .map((e) => AgreementTimelineEvent.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all agreements.
  Future<List<Agreement>> fetchAllAgreements() async {
    final data = await _client.from('agreements').select('*, properties(address)');
    return (data as List<dynamic>)
        .map((e) => Agreement.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch agreements that are in Draft status.
  Future<List<Agreement>> fetchDraftAgreements() async {
    final data = await _client.from('agreements').select('*, properties(address)').eq('status', 'Draft');
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

  /// Create a new Property with all government eRegistration fields
  /// 
  /// This is the UPDATED method that accepts all the fields from the 
  /// property form in the agreement creation screen.
  Future<String> createProperty({
    required String address,
    required String ownerName,
    String? district,
    String? taluka,
    String? village,
    String? areaType,
    String? localLimitName,
    String? propertyAttributeType,
    String? propertyAttributeNumber,
    String? unitType,
    String? unitArea,
    String? unitAreaUnit,
    String? buildingName,
    String? flatNo,
    String? floorNo,
    String? road,
    String? location,
    String? useType,
    String? galleryArea,
    String? parkingArea,
    String? policeStation,
    String? pincode,
  }) async {
    final Map<String, dynamic> data = {
      'address': address,
      'owner_name': ownerName,
      'status': 'available',
    };

    // Only add fields that have non-empty values
    if (district != null && district.isNotEmpty) data['district'] = district;
    if (taluka != null && taluka.isNotEmpty) data['taluka'] = taluka;
    if (village != null && village.isNotEmpty) data['village'] = village;
    if (areaType != null && areaType.isNotEmpty) data['area_type'] = areaType;
    if (localLimitName != null && localLimitName.isNotEmpty) data['local_limit_name'] = localLimitName;
    if (propertyAttributeType != null && propertyAttributeType.isNotEmpty) data['property_attribute_type'] = propertyAttributeType;
    if (propertyAttributeNumber != null && propertyAttributeNumber.isNotEmpty) data['property_attribute_number'] = propertyAttributeNumber;
    if (unitType != null && unitType.isNotEmpty) data['unit_type'] = unitType;
    if (unitArea != null && unitArea.isNotEmpty) data['unit_area'] = unitArea;
    if (unitAreaUnit != null && unitAreaUnit.isNotEmpty) data['unit_area_unit'] = unitAreaUnit;
    if (buildingName != null && buildingName.isNotEmpty) data['building_name'] = buildingName;
    if (flatNo != null && flatNo.isNotEmpty) data['flat_no'] = flatNo;
    if (floorNo != null && floorNo.isNotEmpty) data['floor_no'] = floorNo;
    if (road != null && road.isNotEmpty) data['road'] = road;
    if (location != null && location.isNotEmpty) data['location'] = location;
    if (useType != null && useType.isNotEmpty) data['use_type'] = useType;
    if (galleryArea != null && galleryArea.isNotEmpty) data['gallery_area'] = galleryArea;
    if (parkingArea != null && parkingArea.isNotEmpty) data['parking_area'] = parkingArea;
    if (policeStation != null && policeStation.isNotEmpty) data['police_station'] = policeStation;
    if (pincode != null && pincode.isNotEmpty) data['pincode'] = pincode;

    final res = await _client.from('properties').insert(data).select('id').single();
    return res['id'].toString();
  }

  /// Create a new Tenant profile inline
  Future<String> createTenantProfile(String name, String mobile) async {
    final res = await _client.from('users').insert({
      'name': name,
      'mobile': mobile,
      'role': 'tenant',
      'created_at': DateTime.now().toIso8601String(),
    }).select('id').single();
    return res['id'].toString();
  }

  /// Generate next agreement number for current month e.g., June2601
  Future<String> generateNextAgreementNumber() async {
    final now = DateTime.now();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'June',
      'July', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthName = monthNames[now.month - 1];
    final yearStr = (now.year % 100).toString().padLeft(2, '0');
    
    // Count agreements created this month
    final startDate = DateTime(now.year, now.month, 1).toIso8601String();
    final endDate = DateTime(now.year, now.month + 1, 1).toIso8601String();
    
    final data = await _client
        .from('agreements')
        .select('id')
        .gte('created_at', startDate)
        .lt('created_at', endDate);
    
    final count = (data as List).length + 1;
    final sequenceStr = count.toString().padLeft(2, '0');
    
    return '$monthName$yearStr$sequenceStr';
  }

  /// Upload Draft PDF to Supabase and return the public URL
  Future<String> uploadDraftPdf(String agreementNumber, Uint8List pdfBytes) async {
    final fileName = 'draft_$agreementNumber.pdf';
    final path = 'drafts/$fileName';
    
    // Upload or update the existing file
    await _client.storage.from('agreements').uploadBinary(
      path, 
      pdfBytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'application/pdf'),
    );
    
    // Get the public URL
    final url = _client.storage.from('agreements').getPublicUrl(path);
    
    // Optional: save this URL to the agreements table
    await _client.from('agreements').update({'pdf_url': url}).eq('agreement_number', agreementNumber);
    
    return url;
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

  /// Mark Agreement as Final (generates official PDF, uploads, and updates status)
  Future<void> markAgreementAsFinal(Agreement agreement) async {
    // 1. Generate the final PDF (without watermark)
    final pdfBytes = await PdfService.generateDraftPdf(agreement, isFinal: true);
    
    // 2. Upload the official PDF (overwriting draft or creating new)
    final fileName = 'final_${agreement.agreementNumber}.pdf';
    final path = 'agreements/$fileName'; // Ensure it goes to a valid bucket path
    
    await _client.storage.from('agreements').uploadBinary(
      path, 
      pdfBytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'application/pdf'),
    );
    
    final url = _client.storage.from('agreements').getPublicUrl(path);
    
    // 3. Update the agreement record in the database
    await _client.from('agreements').update({
      'status': 'active',
      'pdf_url': url,
    }).eq('id', agreement.id);
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
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'visit_date': visitDate.toIso8601String().split('T')[0],
      'status': 'Assigned',
    });
  }

  /// Manually trigger the generation of renewal leads
  Future<void> triggerRenewalLeadGeneration() async {
    await _client.rpc('generate_renewal_leads');
  }
}

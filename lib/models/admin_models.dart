import 'package:supabase_flutter/supabase_flutter.dart';

class Lead {
  final String id;
  final String clientName;
  final String phone;
  final String propertyAddress;
  final String status;
  final DateTime createdAt;
  final String? ownerName;
  final String? ownerPhone;

  Lead({
    required this.id,
    required this.clientName,
    required this.phone,
    required this.propertyAddress,
    required this.status,
    required this.createdAt,
    this.ownerName,
    this.ownerPhone,
  });

  factory Lead.fromMap(Map<String, dynamic> map) {
    // Check if we joined with the users table to get owner data
    final ownerData = map['users'];
    
    return Lead(
      id: map['id'].toString(),
      clientName: map['client_name'] as String,
      phone: map['phone'] as String,
      propertyAddress: map['property_address'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      ownerName: ownerData != null ? ownerData['name'] as String? : null,
      ownerPhone: ownerData != null ? ownerData['mobile'] as String? : null,
    );
  }

  Lead copyWith({
    String? id,
    String? clientName,
    String? phone,
    String? propertyAddress,
    String? status,
    DateTime? createdAt,
    String? ownerName,
    String? ownerPhone,
  }) {
    return Lead(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      phone: phone ?? this.phone,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
    );
  }
}

class LeadDocument {
  final String id;
  final String leadId;
  final String documentType;
  final String fileUrl;
  final DateTime createdAt;

  LeadDocument({
    required this.id,
    required this.leadId,
    required this.documentType,
    required this.fileUrl,
    required this.createdAt,
  });

  factory LeadDocument.fromMap(Map<String, dynamic> map) => LeadDocument(
        id: map['id'].toString(),
        leadId: map['lead_id'].toString(),
        documentType: map['document_type'] as String,
        fileUrl: map['file_url'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// Calculates age in completed years from a date of birth, as of today.
int calculateAgeFromDob(DateTime dob) {
  final today = DateTime.now();
  int age = today.year - dob.year;
  if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
    age--;
  }
  return age < 0 ? 0 : age;
}

/// A reusable Owner or Witness record, searchable by name/Aadhaar/PAN so an
/// executive never has to retype the same person across multiple agreements.
/// (Tenants already have an equivalent via the `users` table.)
class AgreementPersonRecord {
  final String id;
  final String role; // 'owner' or 'witness'
  final String name;
  final String address;
  final String pincode;
  final String pan;
  final String aadhaar;
  final DateTime? dob;

  AgreementPersonRecord({
    required this.id,
    required this.role,
    required this.name,
    required this.address,
    required this.pincode,
    required this.pan,
    required this.aadhaar,
    this.dob,
  });

  factory AgreementPersonRecord.fromMap(Map<String, dynamic> map) => AgreementPersonRecord(
        id: map['id'].toString(),
        role: map['role'] as String,
        name: map['name'] as String? ?? '',
        address: map['address'] as String? ?? '',
        pincode: map['pincode'] as String? ?? '',
        pan: map['pan'] as String? ?? '',
        aadhaar: map['aadhaar'] as String? ?? '',
        dob: map['dob'] != null ? DateTime.tryParse(map['dob'] as String) : null,
      );
}

class AgreementPerson {
  final String name;
  final String address;
  final String pincode;
  final String pan;
  final String aadhaar;
  final String age;

  AgreementPerson({
    required this.name,
    required this.address,
    required this.pincode,
    required this.pan,
    required this.aadhaar,
    required this.age,
  });

  factory AgreementPerson.fromMap(Map<String, dynamic> map) => AgreementPerson(
        name: map['name'] ?? '',
        address: map['address'] ?? '',
        pincode: map['pincode'] ?? '',
        pan: map['pan'] ?? '',
        aadhaar: map['aadhaar'] ?? '',
        age: map['age'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'pincode': pincode,
        'pan': pan,
        'aadhaar': aadhaar,
        'age': age,
      };
}

class AgreementWitness {
  final String name;
  final String address;
  final String aadhaar;
  final String age;

  AgreementWitness({
    required this.name,
    required this.address,
    required this.aadhaar,
    required this.age,
  });

  factory AgreementWitness.fromMap(Map<String, dynamic> map) => AgreementWitness(
        name: map['name'] ?? '',
        address: map['address'] ?? '',
        aadhaar: map['aadhaar'] ?? '',
        age: map['age'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'aadhaar': aadhaar,
        'age': age,
      };
}

class AgreementDetails {
  final AgreementPerson owner;
  final AgreementPerson tenant;
  final AgreementWitness witness1;
  final AgreementWitness witness2;
  final int periodMonths;
  final String monthlyRent;
  final String depositAmount;
  final String propertyAddress;

  AgreementDetails({
    required this.owner,
    required this.tenant,
    required this.witness1,
    required this.witness2,
    required this.periodMonths,
    required this.monthlyRent,
    required this.depositAmount,
    this.propertyAddress = '',
  });

  factory AgreementDetails.fromMap(Map<String, dynamic> map) => AgreementDetails(
        owner: AgreementPerson.fromMap(map['owner'] ?? {}),
        tenant: AgreementPerson.fromMap(map['tenant'] ?? {}),
        witness1: AgreementWitness.fromMap(map['witness1'] ?? {}),
        witness2: AgreementWitness.fromMap(map['witness2'] ?? {}),
        periodMonths: map['periodMonths'] ?? 11,
        monthlyRent: map['monthlyRent']?.toString() ?? '',
        depositAmount: map['depositAmount']?.toString() ?? '',
        propertyAddress: map['propertyAddress']?.toString() ?? '',
      );

  Map<String, dynamic> toMap() => {
        'owner': owner.toMap(),
        'tenant': tenant.toMap(),
        'witness1': witness1.toMap(),
        'witness2': witness2.toMap(),
        'periodMonths': periodMonths,
        'monthlyRent': monthlyRent,
        'depositAmount': depositAmount,
        'propertyAddress': propertyAddress,
      };
}

class Agreement {
  final String id;
  final String propertyId;
  final String tenantId;
  final String agreementNumber;
  final DateTime startDate;
  final DateTime expiryDate;
  final String? pdfUrl;
  final String status;
  final AgreementDetails? details;
  final String propertyAddress;

  Agreement({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.agreementNumber,
    required this.startDate,
    required this.expiryDate,
    this.pdfUrl,
    required this.status,
    this.details,
    this.propertyAddress = '',
  });

  factory Agreement.fromMap(Map<String, dynamic> map) => Agreement(
        id: map['id'].toString(),
        agreementNumber: map['agreement_number'] as String,
        propertyId: map['property_id'].toString(),
        tenantId: map['tenant_id'].toString(),
        startDate: DateTime.parse(map['start_date'] as String),
        expiryDate: DateTime.parse(map['expiry_date'] as String),
        pdfUrl: map['pdf_url'] as String?,
        status: map['status'] as String,
        details: map['details'] != null ? AgreementDetails.fromMap(map['details'] as Map<String, dynamic>) : null,
        propertyAddress: map['properties'] != null ? (map['properties']['address'] as String? ?? '') : '',
      );
}

class Payment {
  final String id;
  final String agreementId;
  final double amount;
  final DateTime paymentDate;
  final String status; // Paid, Pending

  Payment({
    required this.id,
    required this.agreementId,
    required this.amount,
    required this.paymentDate,
    required this.status,
  });

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'].toString(),
        agreementId: map['agreement_id']?.toString() ?? '',
        amount: (map['amount'] as num).toDouble(),
        paymentDate: map['payment_date'] != null ? DateTime.parse(map['payment_date'] as String) : DateTime.now(),
        status: map['status'] as String,
      );
}

class BiometricVisit {
  final String id;
  final String agreementId;
  final String? vendorId;
  final String vendorName;
  final DateTime visitDate;
  final String status; // Assigned, Completed
  final String? remarks;
  final String? photoUrl;

  BiometricVisit({
    required this.id,
    required this.agreementId,
    this.vendorId,
    required this.vendorName,
    required this.visitDate,
    required this.status,
    this.remarks,
    this.photoUrl,
  });

  factory BiometricVisit.fromMap(Map<String, dynamic> map) => BiometricVisit(
        id: map['id'].toString(),
        agreementId: map['agreement_id'].toString(),
        vendorId: map['vendor_id']?.toString(),
        vendorName: map['vendor_name'] as String,
        visitDate: DateTime.parse(map['visit_date'] as String),
        status: map['status'] as String,
        remarks: map['remarks'] as String?,
        photoUrl: map['photo_url'] as String?,
      );
}

class RenewalLead {
  final String id;
  final String agreementId;
  final DateTime expiryDate;
  final int daysUntilExpiry;
  final String status; // New, Contacted, Quote Sent

  RenewalLead({
    required this.id,
    required this.agreementId,
    required this.expiryDate,
    required this.daysUntilExpiry,
    required this.status,
  });

  factory RenewalLead.fromMap(Map<String, dynamic> map) => RenewalLead(
        id: map['id'].toString(),
        agreementId: map['agreement_id'].toString(),
        expiryDate: DateTime.parse(map['expiry_date'] as String),
        daysUntilExpiry: map['days_until_expiry'] as int,
        status: map['status'] as String,
      );
}

class Property {
  final String id;
  final String address;
  final String ownerName;
  final String status; // e.g., available, occupied
  
  // New fields needed for agreement creation - Government eRegistration fields
  final String? district;
  final String? taluka;
  final String? village;
  final String? areaType; // Urban/Rural
  final String? localLimitName; // Municipality, Gram Panchayat, etc.
  final String? propertyAttributeType; // Survey Number, City Survey, etc.
  final String? propertyAttributeNumber;
  final String? unitType; // Residential/Commercial/Industrial
  final String? unitArea;
  final String? unitAreaUnit; // sq ft, sq m, acres, etc.
  
  // Location details
  final String? buildingName;
  final String? flatNo;
  final String? floorNo;
  final String? road;
  final String? location;
  final String? useType; // Residential/Commercial
  final String? galleryArea;
  final String? parkingArea;
  final String? policeStation;
  final String? pincode;

  Property({
    required this.id,
    required this.address,
    required this.ownerName,
    required this.status,
    this.district,
    this.taluka,
    this.village,
    this.areaType,
    this.localLimitName,
    this.propertyAttributeType,
    this.propertyAttributeNumber,
    this.unitType,
    this.unitArea,
    this.unitAreaUnit,
    this.buildingName,
    this.flatNo,
    this.floorNo,
    this.road,
    this.location,
    this.useType,
    this.galleryArea,
    this.parkingArea,
    this.policeStation,
    this.pincode,
  });

  factory Property.fromMap(Map<String, dynamic> map) => Property(
    id: map['id'].toString(),
    address: map['address'] as String? ?? '',
    ownerName: map['owner_name'] as String? ?? 'Unknown',
    status: map['status'] as String? ?? 'available',
    // Map all the new fields from your database
    district: map['district'] as String?,
    taluka: map['taluka'] as String?,
    village: map['village'] as String?,
    areaType: map['area_type'] as String?,
    localLimitName: map['local_limit_name'] as String?,
    propertyAttributeType: map['property_attribute_type'] as String?,
    propertyAttributeNumber: map['property_attribute_number'] as String?,
    unitType: map['unit_type'] as String?,
    unitArea: map['unit_area'] as String?,
    unitAreaUnit: map['unit_area_unit'] as String?,
    buildingName: map['building_name'] as String?,
    flatNo: map['flat_no'] as String?,
    floorNo: map['floor_no'] as String?,
    road: map['road'] as String?,
    location: map['location'] as String?,
    useType: map['use_type'] as String?,
    galleryArea: map['gallery_area'] as String?,
    parkingArea: map['parking_area'] as String?,
    policeStation: map['police_station'] as String?,
    pincode: map['pincode'] as String?,
  );

  Property copyWith({
    String? id,
    String? address,
    String? ownerName,
    String? status,
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
  }) {
    return Property(
      id: id ?? this.id,
      address: address ?? this.address,
      ownerName: ownerName ?? this.ownerName,
      status: status ?? this.status,
      district: district ?? this.district,
      taluka: taluka ?? this.taluka,
      village: village ?? this.village,
      areaType: areaType ?? this.areaType,
      localLimitName: localLimitName ?? this.localLimitName,
      propertyAttributeType: propertyAttributeType ?? this.propertyAttributeType,
      propertyAttributeNumber: propertyAttributeNumber ?? this.propertyAttributeNumber,
      unitType: unitType ?? this.unitType,
      unitArea: unitArea ?? this.unitArea,
      unitAreaUnit: unitAreaUnit ?? this.unitAreaUnit,
      buildingName: buildingName ?? this.buildingName,
      flatNo: flatNo ?? this.flatNo,
      floorNo: floorNo ?? this.floorNo,
      road: road ?? this.road,
      location: location ?? this.location,
      useType: useType ?? this.useType,
      galleryArea: galleryArea ?? this.galleryArea,
      parkingArea: parkingArea ?? this.parkingArea,
      policeStation: policeStation ?? this.policeStation,
      pincode: pincode ?? this.pincode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'owner_name': ownerName,
      'status': status,
      'district': district,
      'taluka': taluka,
      'village': village,
      'area_type': areaType,
      'local_limit_name': localLimitName,
      'property_attribute_type': propertyAttributeType,
      'property_attribute_number': propertyAttributeNumber,
      'unit_type': unitType,
      'unit_area': unitArea,
      'unit_area_unit': unitAreaUnit,
      'building_name': buildingName,
      'flat_no': flatNo,
      'floor_no': floorNo,
      'road': road,
      'location': location,
      'use_type': useType,
      'gallery_area': galleryArea,
      'parking_area': parkingArea,
      'police_station': policeStation,
      'pincode': pincode,
    };
  }

  @override
  String toString() {
    return 'Property(id: $id, address: $address, ownerName: $ownerName, status: $status)';
  }
}

class AgreementTimelineEvent {
  final String id;
  final String agreementId;
  final String statusStep;
  final String? description;
  final DateTime createdAt;

  AgreementTimelineEvent({
    required this.id,
    required this.agreementId,
    required this.statusStep,
    this.description,
    required this.createdAt,
  });

  factory AgreementTimelineEvent.fromMap(Map<String, dynamic> map) => AgreementTimelineEvent(
        id: map['id'].toString(),
        agreementId: map['agreement_id'].toString(),
        statusStep: map['status_step'] as String,
        description: map['description'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

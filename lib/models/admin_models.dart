import 'package:supabase_flutter/supabase_flutter.dart';

class Lead {
  final String id;
  final String customerName;
  final String mobile;
  final String propertyAddress;
  final String serviceRequired;
  final DateTime createdAt;
  final String status; // New Lead, In Progress, etc.

  Lead({
    required this.id,
    required this.customerName,
    required this.mobile,
    required this.propertyAddress,
    required this.serviceRequired,
    required this.createdAt,
    required this.status,
  });

  factory Lead.fromMap(Map<String, dynamic> map) => Lead(
        id: map['id'].toString(),
        customerName: map['customer_name'] as String,
        mobile: map['mobile'] as String,
        propertyAddress: map['property_address'] as String,
        serviceRequired: map['service_required'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        status: map['status'] as String,
      );
}

class AgreementPerson {
  final String name;
  final String address;
  final String pincode;
  final String pan;
  final String aadhaar;

  AgreementPerson({
    required this.name,
    required this.address,
    required this.pincode,
    required this.pan,
    required this.aadhaar,
  });

  factory AgreementPerson.fromMap(Map<String, dynamic> map) => AgreementPerson(
        name: map['name'] ?? '',
        address: map['address'] ?? '',
        pincode: map['pincode'] ?? '',
        pan: map['pan'] ?? '',
        aadhaar: map['aadhaar'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'pincode': pincode,
        'pan': pan,
        'aadhaar': aadhaar,
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

  AgreementDetails({
    required this.owner,
    required this.tenant,
    required this.witness1,
    required this.witness2,
    required this.periodMonths,
  });

  factory AgreementDetails.fromMap(Map<String, dynamic> map) => AgreementDetails(
        owner: AgreementPerson.fromMap(map['owner'] ?? {}),
        tenant: AgreementPerson.fromMap(map['tenant'] ?? {}),
        witness1: AgreementWitness.fromMap(map['witness1'] ?? {}),
        witness2: AgreementWitness.fromMap(map['witness2'] ?? {}),
        periodMonths: map['periodMonths'] ?? 11,
      );

  Map<String, dynamic> toMap() => {
        'owner': owner.toMap(),
        'tenant': tenant.toMap(),
        'witness1': witness1.toMap(),
        'witness2': witness2.toMap(),
        'periodMonths': periodMonths,
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
  final String vendorName;
  final DateTime visitDate;
  final String status; // Assigned, Completed
  final String? remarks;
  final String? photoUrl;

  BiometricVisit({
    required this.id,
    required this.agreementId,
    required this.vendorName,
    required this.visitDate,
    required this.status,
    this.remarks,
    this.photoUrl,
  });

  factory BiometricVisit.fromMap(Map<String, dynamic> map) => BiometricVisit(
        id: map['id'].toString(),
        agreementId: map['agreement_id'].toString(),
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

  Property({
    required this.id,
    required this.address,
    required this.ownerName,
    required this.status,
  });

  factory Property.fromMap(Map<String, dynamic> map) => Property(
        id: map['id'].toString(),
        address: map['address'] as String,
        ownerName: map['owner_name'] as String? ?? 'Unknown',
        status: map['status'] as String,
      );
}

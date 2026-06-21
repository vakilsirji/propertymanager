class UserModel {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String role; // owner/tenant/admin/vendor
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'].toString(),
        name: map['name'] as String,
        mobile: map['mobile'] as String? ?? '',
        email: map['email'] as String?,
        role: map['role'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class PropertyModel {
  final int id;
  final int ownerId;
  final String propertyName;
  final String address;
  final String city;
  final double rentAmount;
  final double deposit;
  final String status; // active/vacant

  PropertyModel({
    required this.id,
    required this.ownerId,
    required this.propertyName,
    required this.address,
    required this.city,
    required this.rentAmount,
    required this.deposit,
    required this.status,
  });
}

class TenantModel {
  final int id;
  final int propertyId;
  final String name;
  final String mobile;
  final String aadhaarLast4;
  final DateTime startDate;
  final DateTime endDate;

  TenantModel({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.mobile,
    required this.aadhaarLast4,
    required this.startDate,
    required this.endDate,
  });
}

class AgreementModel {
  final int id;
  final int propertyId;
  final int tenantId;
  final String agreementNumber;
  final DateTime startDate;
  final DateTime expiryDate;
  final String? pdfUrl;
  final String status; // active/expired

  AgreementModel({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.agreementNumber,
    required this.startDate,
    required this.expiryDate,
    this.pdfUrl,
    required this.status,
  });
}

class RentPaymentModel {
  final int id;
  final int propertyId;
  final int tenantId;
  final double amount;
  final DateTime paymentDate;
  final String month;
  final String status; // paid/pending

  RentPaymentModel({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.amount,
    required this.paymentDate,
    required this.month,
    required this.status,
  });
}

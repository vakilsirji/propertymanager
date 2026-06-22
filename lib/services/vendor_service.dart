import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_models.dart';

final vendorServiceProvider = Provider<VendorService>((ref) {
  return VendorService(Supabase.instance.client);
});

final myBiometricVisitsProvider = StreamProvider<List<BiometricVisit>>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const Stream.empty();

  return Supabase.instance.client
      .from('biometric_visits')
      .stream(primaryKey: ['id'])
      .eq('vendor_id', user.id)
      .map((data) => data.map((e) => BiometricVisit.fromMap(e)).toList());
});

class VendorService {
  final SupabaseClient _client;

  VendorService(this._client);

  /// Update the status of a biometric visit
  Future<void> updateVisitStatus(String visitId, String status, String? remarks) async {
    final updates = {
      'status': status,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    };
    await _client.from('biometric_visits').update(updates).eq('id', visitId);
  }
}

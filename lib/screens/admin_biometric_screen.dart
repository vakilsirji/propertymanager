import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';

class AdminBiometricScreen extends ConsumerWidget {
  const AdminBiometricScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsyncValue = ref.watch(biometricVisitsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Visits'),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: visitsAsyncValue.when(
        data: (visits) {
          if (visits.isEmpty) {
            return const Center(child: Text('No biometric visits found'));
          }
          return ListView.separated(
            itemCount: visits.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final visit = visits[index];
              return ListTile(
                leading: const Icon(Icons.fingerprint, color: Colors.blue),
                title: Text('Agreement: ${visit.agreementId}'),
                subtitle: Text('Vendor: ${visit.vendorName}\nDate: ${visit.visitDate.toLocal().toString().split(' ')[0]}'),
                trailing: Text(visit.status, style: TextStyle(color: visit.status == 'Completed' ? Colors.green : Colors.orange)),
                isThreeLine: true,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

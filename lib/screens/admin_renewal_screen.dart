import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';

class AdminRenewalScreen extends ConsumerWidget {
  const AdminRenewalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final renewalsAsyncValue = ref.watch(renewalLeadsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Renewals'),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: renewalsAsyncValue.when(
        data: (renewals) {
          if (renewals.isEmpty) {
            return const Center(child: Text('No renewals found'));
          }
          return ListView.separated(
            itemCount: renewals.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final renewal = renewals[index];
              return ListTile(
                leading: const Icon(Icons.autorenew, color: Colors.purple),
                title: Text('Agreement: ${renewal.agreementId}'),
                subtitle: Text('Expires in ${renewal.daysUntilExpiry} days\nExpiry: ${renewal.expiryDate.toLocal().toString().split(' ')[0]}'),
                trailing: Text(renewal.status, style: TextStyle(color: renewal.status == 'New' ? Colors.red : Colors.blue)),
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

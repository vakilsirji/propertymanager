import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';

class AdminPaymentsScreen extends ConsumerWidget {
  const AdminPaymentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsyncValue = ref.watch(paymentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: paymentsAsyncValue.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No payments found'));
          }
          return ListView.separated(
            itemCount: payments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return ListTile(
                leading: const Icon(Icons.payment, color: Colors.green),
                title: Text('Agreement: ${payment.agreementId}'),
                subtitle: Text('Date: ${payment.paymentDate.toLocal().toString().split(' ')[0]}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${payment.amount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(payment.status, style: TextStyle(color: payment.status == 'Paid' ? Colors.green : Colors.orange)),
                  ],
                ),
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

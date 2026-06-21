import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';
import '../models/models.dart'; // import the models for UserModel

class AdminCustomersScreen extends ConsumerWidget {
  const AdminCustomersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsyncValue = ref.watch(customersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers (Owners & Tenants)'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: customersAsyncValue.when(
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(child: Text('No customers found.'));
          }
          return ListView.separated(
            itemCount: customers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = customers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.role == 'owner' ? Colors.blue : Colors.green,
                  child: Icon(user.role == 'owner' ? Icons.real_estate_agent : Icons.person, color: Colors.white),
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Mobile: ${user.mobile}\nEmail: ${user.email ?? "N/A"}'),
                trailing: Chip(
                  label: Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: user.role == 'owner' ? Colors.blue : Colors.green,
                ),
                isThreeLine: true,
                onTap: () {
                  // Placeholder for detail view
                },
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

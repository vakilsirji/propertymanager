import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';

class AdminLeadsScreen extends ConsumerWidget {
  const AdminLeadsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsyncValue = ref.watch(leadsStreamProvider);
    final adminService = ref.watch(adminServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: leadsAsyncValue.when(
        data: (leads) {
          if (leads.isEmpty) {
            return const Center(child: Text('No leads for today'));
          }
          return ListView.separated(
            itemCount: leads.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final lead = leads[index];
              return ListTile(
                title: Text(lead.customerName),
                subtitle: Text('${lead.serviceRequired}\n${lead.mobile}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    await adminService.updateLeadStatus(lead.id, value);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'In Progress', child: Text('Mark In Progress')),
                    const PopupMenuItem(value: 'Converted', child: Text('Convert to Agreement')),
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

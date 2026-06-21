import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';
import 'admin_lead_details_screen.dart';

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
                title: Text(lead.clientName),
                subtitle: Text('${lead.propertyAddress}\n${lead.phone}'),
                trailing: Text(lead.status, style: TextStyle(color: lead.status == 'New' ? Colors.orange : Colors.green)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AdminLeadDetailsScreen(lead: lead)));
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLeadDialog(context, ref),
        backgroundColor: const Color(0xFF6A1B9A),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLeadDialog(BuildContext context, WidgetRef ref) {
    String clientName = '';
    String phone = '';
    String address = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Enquiry (Lead)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Client Name'),
                onChanged: (val) => clientName = val,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Phone'),
                onChanged: (val) => phone = val,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Property Address'),
                onChanged: (val) => address = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A)),
              onPressed: () async {
                if (clientName.isEmpty || phone.isEmpty) return;
                await ref.read(adminServiceProvider).createLead(clientName, phone, address);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Lead'),
            ),
          ],
        );
      },
    );
  }
}

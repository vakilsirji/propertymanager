import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/vendor_service.dart';

class VendorDashboard extends ConsumerWidget {
  const VendorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsyncValue = ref.watch(myBiometricVisitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: visitsAsyncValue.when(
        data: (visits) {
          if (visits.isEmpty) {
            return const Center(child: Text('No biometric visits assigned.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final visit = visits[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Visit Date: ${visit.visitDate.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Status: ${visit.status}',
                          style: TextStyle(color: visit.status == 'Completed' ? Colors.green : Colors.orange)),
                      if (visit.remarks != null && visit.remarks!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Remarks: ${visit.remarks}'),
                      ],
                      const SizedBox(height: 16),
                      if (visit.status != 'Completed')
                        ElevatedButton.icon(
                          onPressed: () => _showUpdateDialog(context, ref, visit.id),
                          icon: const Icon(Icons.edit),
                          label: const Text('Update Status'),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, WidgetRef ref, String visitId) {
    String selectedStatus = 'Completed';
    String remarks = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Visit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'Assigned', child: Text('Assigned')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'Failed', child: Text('Failed')),
                    ],
                    onChanged: (val) => setState(() => selectedStatus = val!),
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Remarks'),
                    onChanged: (val) => remarks = val,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(vendorServiceProvider).updateVisitStatus(visitId, selectedStatus, remarks);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

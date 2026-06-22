import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';

/// Screen to display documents (e.g., agreement PDFs) for admins.
class AdminDocumentsScreen extends ConsumerWidget {
  const AdminDocumentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreementsAsyncValue = ref.watch(agreementsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: agreementsAsyncValue.when(
        data: (agreements) {
          if (agreements.isEmpty) {
            return const Center(child: Text('No documents found'));
          }
          return ListView.separated(
            itemCount: agreements.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final agr = agreements[index];
              return ListTile(
                leading: const Icon(Icons.description),
                title: Text('Agreement #${agr.agreementNumber}'),
                subtitle: Text('Property: ${agr.propertyId}\nTenant: ${agr.tenantId}'),
                trailing: IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () {
                    // In a full implementation this would open the PDF.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Open PDF for ${agr.agreementNumber}')),
                    );
                  },
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';

/// Stub screen for Draft Agreements (admin).
class AdminDraftScreen extends ConsumerWidget {
  const AdminDraftScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsyncValue = ref.watch(draftAgreementsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft Agreements'),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: draftsAsyncValue.when(
        data: (drafts) {
          if (drafts.isEmpty) {
            return const Center(child: Text('No draft agreements'));
          }
          return ListView.separated(
            itemCount: drafts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final a = drafts[index];
              return ListTile(
                leading: const Icon(Icons.description),
                title: Text('Agreement #${a.agreementNumber}'),
                subtitle: Text('Property: ${a.propertyId}\nTenant: ${a.tenantId}'),
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

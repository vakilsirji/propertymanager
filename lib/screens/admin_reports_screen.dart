import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreementsAsyncValue = ref.watch(agreementsStreamProvider);
    final paymentsAsyncValue = ref.watch(paymentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF6A1B9A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard(
              'Total Agreements',
              agreementsAsyncValue.when(
                data: (data) => data.length.toString(),
                loading: () => '...',
                error: (_, __) => 'Error',
              ),
              Icons.description,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Total Revenue',
              paymentsAsyncValue.when(
                data: (data) {
                  final total = data.where((p) => p.status == 'Paid').fold(0.0, (sum, item) => sum + item.amount);
                  return '₹$total';
                },
                loading: () => '...',
                error: (_, __) => 'Error',
              ),
              Icons.attach_money,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Pending Payments',
              paymentsAsyncValue.when(
                data: (data) {
                  final total = data.where((p) => p.status != 'Paid').fold(0.0, (sum, item) => sum + item.amount);
                  return '₹$total';
                },
                loading: () => '...',
                error: (_, __) => 'Error',
              ),
              Icons.warning,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

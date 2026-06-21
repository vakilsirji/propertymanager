import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'login_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  // Sample data – replace with real values from your backend
  final Map<String, String> _stats = const {
    "Today's Leads": '15',
    'Pending Drafts': '8',
    'Pending Payments': '5',
    'Pending Biometrics': '4',
    'Pending Registration': '3',
    'Completed Agreements': '12',
    'Expiring Agreements': '27',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Vakil Sirji Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6A1B9A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vakil Sirji LegalTech Services",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1.5),
            const SizedBox(height: 16),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard, 'route': '/admin/dashboard'},
      {'title': 'Leads', 'icon': Icons.leaderboard, 'route': '/admin/leads'},
      {'title': 'Customers', 'icon': Icons.people, 'route': '/admin/customers'},
      {'title': 'Draft Agreements', 'icon': Icons.description, 'route': '/admin/draft'},
      {'title': 'Biometric Visits', 'icon': Icons.fingerprint, 'route': '/admin/biometric'},
      {'title': 'Payments', 'icon': Icons.payment, 'route': '/admin/payments'},
      {'title': 'Registration/IGR', 'icon': Icons.account_balance, 'route': '/admin/igr'},
      {'title': 'Vendors', 'icon': Icons.business_center, 'route': '/admin/vendor-assign'},
      {'title': 'Renewals', 'icon': Icons.refresh, 'route': '/admin/renewal'},
      {'title': 'Reports', 'icon': Icons.bar_chart, 'route': '/admin/reports'},
    ];
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF6A1B9A)),
            child: Text('Admin Menu', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          ...menuItems.map((item) => ListTile(
                leading: Icon(item['icon'] as IconData, color: const Color(0xFF6A1B9A)),
                title: Text(item['title'] as String),
                onTap: () {
                  Navigator.pop(context);
                  GoRouter.of(context).go(item['route'] as String);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
      ),
      itemCount: _stats.length,
      itemBuilder: (context, index) {
        final keys = _stats.keys.toList();
        final title = keys[index];
        final value = _stats[title] ?? '-';
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade100, Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.insights, size: 32, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      const SizedBox(height: 4),
                      Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {'label': 'New Agreement', 'icon': Icons.add_business, 'color': Colors.indigo, 'route': '/admin/agreement/new'},
      {'label': 'Renewal Requests', 'icon': Icons.refresh, 'color': Colors.teal, 'route': '/admin/renewal'},
      {'label': 'Schedule Biometric', 'icon': Icons.fingerprint, 'color': Colors.orange, 'route': '/admin/biometric'},
      {'label': 'Reports', 'icon': Icons.bar_chart, 'color': Colors.deepOrange, 'route': '/admin/reports'},
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((a) => ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: a['color'] as Color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => context.push(a['route'] as String),
        icon: Icon(a['icon'] as IconData, color: Colors.white),
        label: Text(a['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      )).toList(),
    );
  }
}

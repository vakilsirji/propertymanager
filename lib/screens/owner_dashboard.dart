import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_provider.dart';
import 'add_property_screen.dart';
import 'view_properties_screen.dart';
import 'rent_tracker_screen.dart';
import 'agreements_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final _supabase = Supabase.instance.client;
  bool _isLoadingStats = true;
  int _totalProperties = 0;
  int _activeTenants = 0;
  double _pendingRent = 0;
  int _expiringSoon = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  /// Pulls live counts for this owner's properties, active tenants,
  /// pending rent total, and agreements expiring within 30 days —
  /// replacing the previously hardcoded stat values.
  Future<void> _fetchStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      setState(() => _isLoadingStats = true);

      // Total properties owned by this user.
      final properties = await _supabase
          .from('properties')
          .select('id, status, tenants(id)')
          .eq('owner_id', user.id);

      final propertyIds = (properties as List).map((p) => p['id']).toList();
      final activeTenantCount = properties
          .where((p) => p['tenants'] != null && (p['tenants'] as List).isNotEmpty)
          .length;

      // Pending rent total across this owner's properties.
      double pendingTotal = 0;
      if (propertyIds.isNotEmpty) {
        final pendingPayments = await _supabase
            .from('rent_payments')
            .select('amount, property_id')
            .inFilter('property_id', propertyIds)
            .eq('status', 'pending');
        for (final p in pendingPayments) {
          pendingTotal += (p['amount'] as num).toDouble();
        }
      }

      // Agreements expiring within the next 30 days.
      int expiringCount = 0;
      if (propertyIds.isNotEmpty) {
        final now = DateTime.now();
        final in30Days = now.add(const Duration(days: 30));
        final expiringAgreements = await _supabase
            .from('agreements')
            .select('id, expiry_date, property_id')
            .inFilter('property_id', propertyIds)
            .gte('expiry_date', now.toIso8601String().split('T')[0])
            .lte('expiry_date', in30Days.toIso8601String().split('T')[0]);
        expiringCount = (expiringAgreements as List).length;
      }

      if (mounted) {
        setState(() {
          _totalProperties = properties.length;
          _activeTenants = activeTenantCount;
          _pendingRent = pendingTotal;
          _expiringSoon = expiringCount;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching owner dashboard stats: $e');
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final ownerName = auth.userProfile?.name ?? 'Loading...';

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('Vakil Sirji Property Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(ownerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async {
                  await auth.signOut();
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _fetchStats,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 800;

                int statCrossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
                int actionCrossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);
                double statAspectRatio = isDesktop ? 1.8 : (isTablet ? 1.5 : 1.1);
                double actionAspectRatio = isDesktop ? 3.0 : (isTablet ? 4.0 : 6.0);

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48.0 : 16.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GridView.count(
                        crossAxisCount: statCrossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        childAspectRatio: statAspectRatio,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard(
                            'Total Properties',
                            _isLoadingStats ? '—' : '$_totalProperties',
                            Icons.home,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Active Tenants',
                            _isLoadingStats ? '—' : '$_activeTenants',
                            Icons.people,
                            Colors.green,
                          ),
                          _buildStatCard(
                            'Pending Rent',
                            _isLoadingStats ? '—' : 'Rs. ${_pendingRent.toStringAsFixed(0)}',
                            Icons.currency_rupee,
                            Colors.orange,
                          ),
                          _buildStatCard(
                            'Expiring Soon',
                            _isLoadingStats ? '—' : '$_expiringSoon',
                            Icons.warning_amber_rounded,
                            Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: actionCrossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        childAspectRatio: actionAspectRatio,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildActionButton(context, 'Add Property', Icons.add_business, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPropertyScreen()))
                                .then((_) => _fetchStats());
                          }),
                          _buildActionButton(context, 'View Properties', Icons.list_alt, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewPropertiesScreen()));
                          }),
                          _buildActionButton(context, 'Rent Tracker', Icons.receipt_long, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RentTrackerScreen()))
                                .then((_) => _fetchStats());
                          }),
                          _buildActionButton(context, 'Agreements', Icons.description, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AgreementsScreen()));
                          }),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color[700]),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color[900]),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[900],
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade100),
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

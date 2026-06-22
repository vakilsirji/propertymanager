import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'owner_agreement_details_screen.dart';

class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({Key? key}) : super(key: key);

  @override
  State<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // 1. Fetch properties to find leads
      final propertiesRes = await _supabase.from('properties').select('id, property_name, address').eq('owner_id', user.id);
      
      List<String> addresses = [];
      Map<String, String> addressToName = {};
      for (var prop in propertiesRes) {
        final address = prop['address']?.toString();
        if (address != null && address.isNotEmpty) {
          addresses.add(address);
          addressToName[address] = prop['property_name']?.toString() ?? 'Unknown';
        }
      }

      // 2. Fetch leads matching those properties
      List<dynamic> leads = [];
      if (addresses.isNotEmpty) {
        leads = await _supabase.from('leads').select().filter('property_address', 'in', addresses);
      }

      // 3. Fetch agreements
      final agreementsRes = await _supabase
          .from('agreements')
          .select('*, properties!inner(property_name, owner_id)')
          .eq('properties.owner_id', user.id);

      List<Map<String, dynamic>> combined = [];
      for (var lead in leads) {
        combined.add({
          'isLead': true,
          'data': lead,
          'property_name': addressToName[lead['property_address']] ?? lead['property_address'] ?? 'Unknown Property'
        });
      }
      for (var agg in agreementsRes) {
        combined.add({
          'isLead': false,
          'data': agg,
          'property_name': agg['properties']?['property_name'] ?? 'Unknown Property'
        });
      }

      // Sort by latest created_at
      combined.sort((a, b) {
        final dateA = DateTime.parse((a['data']['created_at'] ?? DateTime.now().toIso8601String()).toString());
        final dateB = DateTime.parse((b['data']['created_at'] ?? DateTime.now().toIso8601String()).toString());
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _items = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching agreements/leads: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Agreements'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No requests or agreements found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final itemMap = _items[index];
                    final isLead = itemMap['isLead'] as bool;
                    final item = itemMap['data'] as dynamic;
                    final propertyName = itemMap['property_name'] as String;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OwnerAgreementDetailsScreen(
                              item: item,
                              isLead: isLead,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isLead ? 'Agreement Request' : 'Agreement #${item['agreement_number']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (item['status'] == 'active' || item['status'] == 'New')
                                        ? Colors.green[100]
                                        : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (item['status'] ?? 'Unknown').toUpperCase(),
                                    style: TextStyle(
                                      color: (item['status'] == 'active' || item['status'] == 'New')
                                          ? Colors.green[900]
                                          : Colors.orange[900],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.home, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    propertyName,
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (!isLead)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Start Date',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12)),
                                      Text(item['start_date'] ?? 'N/A',
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Expiry Date',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12)),
                                      Text(item['expiry_date'] ?? 'N/A',
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            if (isLead)
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tenant: ${item['client_name']}',
                                    style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ), // closes Card
                  ); // closes GestureDetector
                },
                ),
    );
  }
}

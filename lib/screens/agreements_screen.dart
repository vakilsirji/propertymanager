import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({Key? key}) : super(key: key);

  @override
  State<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _agreements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAgreements();
  }

  Future<void> _fetchAgreements() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Fetch agreements where the property's owner_id matches the current user
      final response = await _supabase
          .from('agreements')
          .select('*, properties!inner(property_name, owner_id)')
          .eq('properties.owner_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _agreements = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching agreements: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading agreements: $e')),
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
          : _agreements.isEmpty
              ? const Center(child: Text('No agreements found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _agreements.length,
                  itemBuilder: (context, index) {
                    final agreement = _agreements[index];
                    final property = agreement['properties'];
                    return Card(
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
                                  'Agreement #${agreement['agreement_number']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: agreement['status'] == 'active'
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (agreement['status'] ?? 'Unknown').toUpperCase(),
                                    style: TextStyle(
                                      color: agreement['status'] == 'active'
                                          ? Colors.green[900]
                                          : Colors.red[900],
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
                                    property != null ? property['property_name'] : 'Unknown Property',
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                                    Text(agreement['start_date'] ?? 'N/A',
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
                                    Text(agreement['expiry_date'] ?? 'N/A',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  UserModel? _userProfile;
  bool _isLoading = true;

  User? get user => _user;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      _user = session?.user;
      
      if (_user != null) {
         await _fetchUserProfile(_user!.id);
      } else {
         _userProfile = null;
      }
      
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final data = await _supabase.from('users').select().eq('id', uid).maybeSingle();
      if (data != null) {
        _userProfile = UserModel(
          id: data['id'],
          name: data['name'],
          mobile: data['mobile'] ?? '',
          email: data['email'],
          role: data['role'],
          createdAt: DateTime.parse(data['created_at']),
        );
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

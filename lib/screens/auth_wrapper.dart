import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/admin_dashboard.dart';
import '../screens/tenant_dashboard.dart';
import '../screens/owner_dashboard.dart';
import '../screens/vendor_dashboard.dart';

/// Separate file for the AuthWrapper used by routing.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.user == null) {
          return const LoginScreen();
        }
        if (auth.userProfile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = auth.userProfile!.role;
        if (role == 'admin') {
          return const AdminDashboard();
        } else if (role == 'tenant') {
          return const TenantDashboard();
        } else if (role == 'vendor') {
          return const VendorDashboard();
        } else {
          return const OwnerDashboard();
        }
      },
    );
  }
}

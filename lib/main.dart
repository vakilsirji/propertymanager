import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'screens/owner_dashboard.dart';
import 'screens/tenant_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'services/auth_provider.dart';
import 'screens/auth_wrapper.dart';
import 'screens/login_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider, Consumer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "config.env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const PropertyManagerApp(),
      ),
    ),
  );
}

class PropertyManagerApp extends StatelessWidget {
  const PropertyManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vakil Sirji Property Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      routerDelegate: appRouter.routerDelegate,
      routeInformationParser: appRouter.routeInformationParser,
      routeInformationProvider: appRouter.routeInformationProvider,
    );
  }
}

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
          return LoginScreen();
        }

        if (auth.userProfile == null) {
          // Profile is not yet loaded or doesn't exist
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Route based on role
        final role = auth.userProfile!.role;
        if (role == 'admin') {
          return const AdminDashboard();
        } else if (role == 'tenant') {
          return const TenantDashboard();
        } else {
          return const OwnerDashboard();
        }
      },
    );
  }
}

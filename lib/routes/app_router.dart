import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth_wrapper.dart';
import '../screens/admin_dashboard.dart';
import '../screens/admin_customers_screen.dart';
import '../screens/admin_leads_screen.dart';
import '../screens/admin_documents_screen.dart';
import '../screens/admin_draft_screen.dart';
import '../screens/admin_create_agreement_screen.dart';
import '../screens/admin_payments_screen.dart';
import '../screens/admin_igr_screen.dart';
import '../screens/admin_vendor_assign_screen.dart';
import '../screens/admin_biometric_screen.dart';
import '../screens/admin_registration_screen.dart';
import '../screens/admin_renewal_screen.dart';
import '../screens/admin_reports_screen.dart';

/// Central router for the entire application.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Auth wrapper – decides where to send the user based on auth status.
    GoRoute(
      path: '/',
      name: 'authWrapper',
      builder: (context, state) => const AuthWrapper(),
    ),
    // Admin section routes.
    GoRoute(
      path: '/admin/dashboard',
      name: 'adminDashboard',
      builder: (context, state) => const AdminDashboard(),
    ),
    GoRoute(
      path: '/admin/leads',
      name: 'adminLeads',
      builder: (context, state) => const AdminLeadsScreen(),
    ),
    GoRoute(
      path: '/admin/documents',
      name: 'adminDocuments',
      builder: (context, state) => const AdminDocumentsScreen(),
    ),
    GoRoute(
      path: '/admin/draft',
      name: 'adminDraft',
      builder: (context, state) => const AdminDraftScreen(),
    ),
    GoRoute(
      path: '/admin/agreement/new',
      name: 'adminCreateAgreement',
      builder: (context, state) => const AdminCreateAgreementScreen(),
    ),
    GoRoute(
      path: '/admin/payments',
      name: 'adminPayments',
      builder: (context, state) => const AdminPaymentsScreen(),
    ),
    GoRoute(
      path: '/admin/igr',
      name: 'adminIGR',
      builder: (context, state) => const AdminIgrScreen(),
    ),
    GoRoute(
      path: '/admin/vendor-assign',
      name: 'adminVendorAssign',
      builder: (context, state) => const AdminVendorAssignScreen(),
    ),
    GoRoute(
      path: '/admin/biometric',
      name: 'adminBiometric',
      builder: (context, state) => const AdminBiometricScreen(),
    ),
    GoRoute(
      path: '/admin/registration',
      name: 'adminRegistration',
      builder: (context, state) => const AdminRegistrationScreen(),
    ),
    GoRoute(
      path: '/admin/renewal',
      name: 'adminRenewal',
      builder: (context, state) => const AdminRenewalScreen(),
    ),
    GoRoute(
      path: '/admin/reports',
      name: 'adminReports',
      builder: (context, state) => const AdminReportsScreen(),
    ),
    // Customers screen route
    GoRoute(
      path: '/admin/customers',
      name: 'adminCustomers',
      builder: (context, state) => const AdminCustomersScreen(),
    ),
  ],
);

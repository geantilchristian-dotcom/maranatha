import 'package:flutter/material.dart';

import '../services/admin_session.dart';
import 'admin_dashboard_page.dart';
import 'admin_login_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (AdminSession.instance.authenticated) {
      return const AdminDashboardPage();
    }
    return const AdminLoginPage();
  }
}

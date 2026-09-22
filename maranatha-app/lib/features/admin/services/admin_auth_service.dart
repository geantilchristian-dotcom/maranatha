import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'admin_session.dart';

class AdminAuthResult {
  const AdminAuthResult({required this.success, required this.message});
  final bool success;
  final String message;
}

class AdminAuthService {
  const AdminAuthService();
  static const String _baseUrl = 'https://maranatha-1-k6ro.onrender.com';
  Future<AdminAuthResult> login(String password) async {
    final clean = password.trim();
    if (clean.isEmpty) {
      return const AdminAuthResult(
        success: false,
        message: 'Saisissez le mot de passe administrateur.',
      );
    }
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/admin/verify'),
            headers: <String, String>{
              'Accept': 'application/json',
              'x-admin-password': clean,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        AdminSession.instance.authenticate(clean);
        return const AdminAuthResult(success: true, message: '');
      }
      var serverMessage = '';
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['error'] != null) {
          serverMessage = decoded['error'].toString();
        }
      } catch (_) {}
      if (response.statusCode == 401) {
        return const AdminAuthResult(
          success: false,
          message: 'Mot de passe administrateur incorrect.',
        );
      }
      if (response.statusCode == 429) {
        return const AdminAuthResult(
          success: false,
          message: 'Trop de tentatives. Reessayez plus tard.',
        );
      }
      if (response.statusCode == 503) {
        return const AdminAuthResult(
          success: false,
          message: 'Administration non configuree sur le serveur.',
        );
      }
      return AdminAuthResult(
        success: false,
        message: serverMessage.isNotEmpty
            ? serverMessage
            : 'Connexion administrateur impossible.',
      );
    } on TimeoutException {
      return const AdminAuthResult(
        success: false,
        message: 'Le serveur met trop de temps a repondre.',
      );
    } catch (_) {
      return const AdminAuthResult(
        success: false,
        message: 'Impossible de contacter le serveur MARANATHA.',
      );
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

class MaranathaPublicConfig {
  const MaranathaPublicConfig({
    this.churchName = 'CEMM MARANATHA',
    this.ministryName = 'Communaute des Eglises Missionnaires Maranatha',
    this.version = '',
    this.description = '',
    this.about = '',
    this.privacy = '',
    this.terms = '',
    this.help = '',
    this.apkUrl = '',
    this.supportEmail = '',
    this.supportWhatsapp = '',
    this.phone = '',
    this.email = '',
    this.address = '',
  });
  final String churchName;
  final String ministryName;
  final String version;
  final String description;
  final String about;
  final String privacy;
  final String terms;
  final String help;
  final String apkUrl;
  final String supportEmail;
  final String supportWhatsapp;
  final String phone;
  final String email;
  final String address;
}

class PublicConfigRepository {
  PublicConfigRepository._();
  static final PublicConfigRepository instance = PublicConfigRepository._();
  static const String baseUrl = 'https://maranatha-1-k6ro.onrender.com';
  Future<MaranathaPublicConfig> load() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/settings/app-config'),
        headers: const <String, String>{'Accept': 'application/json'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const MaranathaPublicConfig();
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        return const MaranathaPublicConfig();
      }
      final identity = _map(decoded['identity']);
      final documents = _map(decoded['documents']);
      final application = _map(decoded['application']);
      final contact = _map(decoded['contact']);
      return MaranathaPublicConfig(
        churchName: _text(identity['churchName'], fallback: 'CEMM MARANATHA'),
        ministryName: _text(
          identity['ministryName'],
          fallback: 'Communaute des Eglises Missionnaires Maranatha',
        ),
        version: _text(identity['version']),
        description: _text(identity['description']),
        about: _text(documents['about']),
        privacy: _text(documents['privacy']),
        terms: _text(documents['terms']),
        help: _text(documents['help']),
        apkUrl: _text(application['apkUrl']),
        supportEmail: _text(application['supportEmail']),
        supportWhatsapp: _text(application['supportWhatsapp']),
        phone: _text(contact['phone']),
        email: _text(contact['email']),
        address: _text(contact['address']),
      );
    } catch (_) {
      return const MaranathaPublicConfig();
    }
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class MaranathaProfileData {
  const MaranathaProfileData({
    this.nom = '',
    this.postNom = '',
    this.prenom = '',
    this.telephone = '',
    this.email = '',
    this.adresse = '',
    this.eglise = '',
    this.statut = 'Fidele',
    this.photoBase64 = '',
  });
  final String nom;
  final String postNom;
  final String prenom;
  final String telephone;
  final String email;
  final String adresse;
  final String eglise;
  final String statut;
  final String photoBase64;
  String get fullName {
    return <String>[
      prenom,
      postNom,
      nom,
    ].where((value) => value.trim().isNotEmpty).join(' ');
  }

  MaranathaProfileData copyWith({
    String? nom,
    String? postNom,
    String? prenom,
    String? telephone,
    String? email,
    String? adresse,
    String? eglise,
    String? statut,
    String? photoBase64,
  }) {
    return MaranathaProfileData(
      nom: nom ?? this.nom,
      postNom: postNom ?? this.postNom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      eglise: eglise ?? this.eglise,
      statut: statut ?? this.statut,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }
}

class ProfileRepository {
  ProfileRepository._();
  static final ProfileRepository instance = ProfileRepository._();
  static const String _nom = 'maranatha_nom';
  static const String _postNom = 'maranatha_postnom';
  static const String _prenom = 'maranatha_prenom';
  static const String _telephone = 'maranatha_tel';
  static const String _email = 'maranatha_email';
  static const String _adresse = 'maranatha_adresse';
  static const String _eglise = 'maranatha_eglise';
  static const String _statut = 'maranatha_statut';
  static const String _photo = 'maranatha_photo_flutter';
  static const String notificationsKey = 'maranatha_notifications_enabled';
  static const String reducedMotionKey = 'maranatha_reduce_motion_flutter';
  Future<MaranathaProfileData> load() async {
    final prefs = await SharedPreferences.getInstance();
    return MaranathaProfileData(
      nom: prefs.getString(_nom) ?? '',
      postNom: prefs.getString(_postNom) ?? '',
      prenom: prefs.getString(_prenom) ?? '',
      telephone: prefs.getString(_telephone) ?? '',
      email: prefs.getString(_email) ?? '',
      adresse: prefs.getString(_adresse) ?? '',
      eglise: prefs.getString(_eglise) ?? '',
      statut: prefs.getString(_statut) ?? 'Fidele',
      photoBase64: prefs.getString(_photo) ?? '',
    );
  }

  Future<void> save(MaranathaProfileData profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nom, profile.nom.trim());
    await prefs.setString(_postNom, profile.postNom.trim());
    await prefs.setString(_prenom, profile.prenom.trim());
    await prefs.setString(_telephone, profile.telephone.trim());
    await prefs.setString(_email, profile.email.trim());
    await prefs.setString(_adresse, profile.adresse.trim());
    await prefs.setString(_eglise, profile.eglise.trim());
    await prefs.setString(
      _statut,
      profile.statut.trim().isEmpty ? 'Fidele' : profile.statut.trim(),
    );
    await prefs.setString(_photo, profile.photoBase64);
  }

  Future<bool> notificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(notificationsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsKey, value);
  }

  Future<bool> reducedMotion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(reducedMotionKey) ?? false;
  }

  Future<void> setReducedMotion(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(reducedMotionKey, value);
  }

  Future<void> clearAccount() async {
    final prefs = await SharedPreferences.getInstance();
    const keys = <String>[
      _nom,
      _postNom,
      _prenom,
      _telephone,
      _email,
      _adresse,
      _eglise,
      _statut,
      _photo,
      'maranatha_user',
      'maranatha_membre_id',
      'maranatha_auth_done',
    ];
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

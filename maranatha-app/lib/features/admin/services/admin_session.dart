class AdminSession {
  AdminSession._();
  static final AdminSession instance = AdminSession._();
  String _password = '';
  bool get authenticated => _password.isNotEmpty;
  String get password => _password;
  void authenticate(String password) {
    _password = password;
  }

  void logout() {
    _password = '';
  }

  Map<String, String> get headers {
    if (_password.isEmpty) {
      return const <String, String>{'Accept': 'application/json'};
    }
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'x-admin-password': _password,
    };
  }
}

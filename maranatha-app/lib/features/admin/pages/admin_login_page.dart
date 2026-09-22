import 'package:flutter/material.dart';

import '../services/admin_auth_service.dart';
import 'admin_dashboard_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  static const Color _blue = Color(0xFF003DF0);
  static const Color _navy = Color(0xFF10284A);
  static const Color _page = Color(0xFFF4F7FC);
  static const Color _border = Color(0xFFE2E8F0);
  final TextEditingController _passwordController = TextEditingController();
  final AdminAuthService _auth = const AdminAuthService();
  bool _loading = false;
  bool _visible = false;
  String _error = '';
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    final result = await _auth.login(_passwordController.text);
    if (!mounted) {
      return;
    }
    if (!result.success) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AdminDashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.fromLTRB(34, 38, 34, 34),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D0F172A),
                      blurRadius: 34,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: _AdminLogo(),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Administration',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _navy,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'CEMM MARANATHA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Mot de passe',
                      style: TextStyle(
                        color: Color(0xFF43536A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_visible,
                      onSubmitted: (_) {
                        _login();
                      },
                      decoration: InputDecoration(
                        hintText: 'Mot de passe administrateur',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFD),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF65758B),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _visible = !_visible;
                            });
                          },
                          icon: Icon(
                            _visible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: _border),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: _blue, width: 1.4),
                        ),
                      ),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error,
                        style: const TextStyle(
                          color: Color(0xFFC6283D),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _loading ? null : _login,
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Acces reserve aux responsables autorises.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8995A7), fontSize: 9.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminLogo extends StatelessWidget {
  const _AdminLogo();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFF003DF0)),
      child: const Icon(
        Icons.admin_panel_settings_outlined,
        color: Colors.white,
        size: 31,
      ),
    );
  }
}

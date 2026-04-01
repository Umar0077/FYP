import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/admin/admin_auth_service.dart';
import '../../services/admin/admin_data_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();
  final AdminDataService _adminDataService = AdminDataService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginAsAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await _adminAuthService.signInAdmin(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _adminDataService.addLog(
        action: 'admin_login',
        details: 'Admin signed in from AdminLoginScreen',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      Get.offAllNamed('/admin/dashboard');
    } catch (e) {
      final errorText = e.toString().toLowerCase();
      final message = errorText.contains('invalid-admin-credentials')
        ? 'Invalid admin email or password.'
        : errorText.contains('admin-not-registered')
          ? 'This account is not registered in admin collection.'
          : 'Admin sign in failed. Please check your credentials.';

      setState(() {
        _loading = false;
        _error = message;
      });

      Get.snackbar(
        'Login Failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? const Color(0xFF00002E) : Colors.white;
    final Color primaryTextColor = isDark ? Colors.white : const Color(0xFF0A0F2E);
    final Color secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF27308A);
    final Color inputFillColor = isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF5F6FA);
    final Color inputBorderColor = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
    final Color hintColor = isDark ? Colors.white38 : const Color(0xFF8A93B2);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: primaryTextColor),
                        onPressed: Get.back,
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'AI Interview Assistant Coach',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Admin Sign In',
                        style: TextStyle(color: secondaryTextColor, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      if (_error.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Email',
                        style: TextStyle(color: secondaryTextColor, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: primaryTextColor),
                        decoration: InputDecoration(
                          hintText: 'Enter email',
                          hintStyle: TextStyle(color: hintColor),
                          filled: true,
                          fillColor: inputFillColor,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: inputBorderColor),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryTextColor),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Password',
                        style: TextStyle(color: secondaryTextColor, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        style: TextStyle(color: primaryTextColor),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: hintColor),
                          filled: true,
                          fillColor: inputFillColor,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: inputBorderColor),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryTextColor),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off : Icons.visibility,
                              color: secondaryTextColor,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDark ? Colors.white : const Color(0xFF00002E),
                            foregroundColor:
                                isDark ? const Color(0xFF00002E) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _loading ? null : _loginAsAdmin,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Log In as Admin',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../onboarding/onboarding_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../widgets/glass/glass_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneOrEmailController = TextEditingController();
  bool _notifyOrders = true;
  bool _subscribeNewsletter = false;

  @override
  void dispose() {
    _phoneOrEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement phone/email login flow
      // For now, navigate to home
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return GlassScaffold(
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFF5F5F0),
          const Color(0xFFFFFFFF),
          const Color(0xFFF0F0E8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Close button
            Positioned(
              top: 16,
              left: 16,
              child: GlassIconButton(
                icon: Icons.close,
                size: 44,
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
              ),
            ),

            // Skip button
            Positioned(
              top: 16,
              right: 16,
              child: GlassButton(
                text: 'SKIP',
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                height: 44,
                blur: GlassConfig.mediumBlur,
                child: const Text(
                  'SKIP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlassCard(
                  width: 500,
                  padding: const EdgeInsets.all(32),
                  blur: GlassConfig.mediumBlur,
                  borderRadius: BorderRadius.circular(24),
                  elevation: 4,
                  showGlow: true,
                  tintColor: const Color(0xFFD4AF37).withOpacity(0.1),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF3D1F1F), width: 2),
                          ),
                          child: Center(
                            child: CustomPaint(
                              size: const Size(70, 70),
                              painter: ThyneLogoPainter(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Title
                        const Text(
                          'Welcome to Thyne',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        const Text(
                          'Sign up or log in to continue',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Phone or Email input
                        TextFormField(
                          controller: _phoneOrEmailController,
                          decoration: InputDecoration(
                            hintText: 'Phone or Email',
                            hintStyle: const TextStyle(
                              color: Colors.black26,
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone or email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Notify checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _notifyOrders,
                              onChanged: (value) {
                                setState(() {
                                  _notifyOrders = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF3D5A3D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Notify me of orders, updates and offers',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Newsletter checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _subscribeNewsletter,
                              onChanged: (value) {
                                setState(() {
                                  _subscribeNewsletter = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF3D5A3D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Subscribe to email newsletter',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Continue button
                        GlassPrimaryButton(
                          text: 'CONTINUE',
                          icon: Icons.arrow_forward,
                          onPressed: _handleContinue,
                          isLoading: authProvider.isLoading,
                          enabled: !authProvider.isLoading,
                          width: double.infinity,
                        ),

                        const SizedBox(height: 32),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.black12)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: Colors.black12)),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Social login buttons
                        Row(
                          children: [
                            Expanded(
                              child: _socialLoginButton(
                                icon: 'G',
                                label: '',
                                onTap: () {
                                  // Google login
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _socialLoginButton(
                                icon: 'f',
                                label: '',
                                isFacebook: true,
                                onTap: () {
                                  // Facebook login
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _socialLoginButton(
                                icon: '',
                                label: '',
                                isApple: true,
                                onTap: () {
                                  // Apple login
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Terms and conditions
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'By continuing, you agree to our '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ', '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ', '),
                              TextSpan(
                                text: 'Wallet Policy',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ', and '),
                              TextSpan(
                                text: 'Data Policy',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialLoginButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool isFacebook = false,
    bool isApple = false,
  }) {
    return GlassButton(
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      blur: GlassConfig.softBlur,
      borderRadius: BorderRadius.circular(12),
      child: Center(
        child: isApple
            ? const Icon(Icons.apple, size: 28, color: Colors.black87)
            : isFacebook
                ? const Icon(Icons.facebook, size: 28, color: Color(0xFF1877F2))
                : Text(
                    icon,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
      ),
    );
  }
}

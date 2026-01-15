import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../../utils/theme.dart';
import '../onboarding/onboarding_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'admin_login_screen.dart';
import 'otp_verification_screen.dart';
import '../../widgets/glass/glass_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _notifyOrders = true;
  bool _subscribeNewsletter = false;

  // Country code data - India only
  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Country',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _countryCodes.length,
                itemBuilder: (context, index) {
                  final country = _countryCodes[index];
                  final isSelected = country['code'] == _selectedCountryCode;
                  return ListTile(
                    leading: Text(
                      country['flag']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(country['name']!),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          country['code']!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check, color: Color(0xFF3D5A3D)),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF3D5A3D).withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        _selectedCountryCode = country['code']!;
                        _selectedCountryFlag = country['flag']!;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      final phoneNumber = _phoneController.text.trim();
      final authProvider = context.read<AuthProvider>();

      // Validate phone number (should be digits only)
      if (!RegExp(r'^[0-9]{6,15}$').hasMatch(phoneNumber.replaceAll(' ', ''))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid phone number'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Format phone number with country code
      final fullPhoneNumber = '$_selectedCountryCode${phoneNumber.replaceAll(' ', '')}';

      // Send OTP
      final success = await authProvider.sendPhoneOTP(fullPhoneNumber);

      if (success && mounted) {
        // Navigate to OTP verification screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(
              phoneNumber: fullPhoneNumber,
              notifyOrders: _notifyOrders,
              subscribeNewsletter: _subscribeNewsletter,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to send OTP'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
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
            // Skip button at top right
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
                        SvgPicture.asset(
                          'assets/thyne.svg',
                          width: 100,
                          height: 100,
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

                        // Phone input with country code
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Country code display (India only - no dropdown)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCountryFlag,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedCountryCode,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Phone number input
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Phone Number',
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
                                    return 'Enter phone number';
                                  }
                                  if (!RegExp(r'^[0-9]{6,15}$').hasMatch(value.replaceAll(' ', ''))) {
                                    return 'Invalid phone number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
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

                        const SizedBox(height: 24),

                        // Admin login link
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.admin_panel_settings_outlined, size: 16, color: Colors.black45),
                              SizedBox(width: 6),
                              Text(
                                'Admin Login',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w500,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_provider.dart';
import '../../../core/core.dart';
import 'otp_verification_screen.dart';
import 'admin_login_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = CountryData.defaultDialCode;
  bool _notifyOrders = true;
  bool _subscribeNewsletter = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authProvider = context.read<AuthProvider>();
        final phoneNumber = '$_selectedCountryCode${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';

        // Send OTP to phone number
        final success = await authProvider.sendPhoneOTP(phoneNumber);

        if (success && mounted) {
          // Navigate to OTP verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OTPVerificationScreen(
                phoneNumber: phoneNumber,
                notifyOrders: _notifyOrders,
                subscribeNewsletter: _subscribeNewsletter,
              ),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send OTP. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      body: SafeArea(
        child: Stack(
          children: [
            // Skip button
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: Text(
                  'SKIP',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            // Admin login button (for staff)
            Positioned(
              top: 16,
              left: 16,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: Text(
                  'Admin',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF666666),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF666666),
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.diamond_outlined,
                              size: 40,
                              color: Color(0xFF094010),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Welcome to THYNE',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Sign up or log in to continue',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: const Color(0xFF666666),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Phone number input with country code
                        Row(
                          children: [
                            // Country code dropdown
                            Container(
                              padding: AppDimensions.paddingHorizontal12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: AppDimensions.borderRadius12,
                                border: Border.all(
                                  color: const Color(0xFFE5E5E5),
                                  width: 1,
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedCountryCode,
                                underline: const SizedBox(),
                                icon: const Icon(Icons.arrow_drop_down, size: AppDimensions.iconSizeMedium),
                                items: CountryData.countryCodes.map((country) {
                                  return DropdownMenuItem<String>(
                                    value: country.dialCode,
                                    child: Row(
                                      children: [
                                        Text(
                                          country.flag,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        AppDimensions.horizontalSpace8,
                                        Text(
                                          country.dialCode,
                                          style: GoogleFonts.inter(
                                            fontSize: AppDimensions.fontSizeMedium,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCountryCode = value!;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Phone number field
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'Phone Number',
                                  hintStyle: GoogleFonts.inter(
                                    color: const Color(0xFF999999),
                                    fontSize: 15,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E5E5),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E5E5),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF094010),
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: FormValidators.phone,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Notify checkbox
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5E5E5),
                              width: 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: _notifyOrders,
                            onChanged: (value) {
                              setState(() {
                                _notifyOrders = value ?? false;
                              });
                            },
                            title: Text(
                              'Notify me of orders, updates and offers',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            activeColor: const Color(0xFF094010),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Newsletter checkbox
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5E5E5),
                              width: 1,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: _subscribeNewsletter,
                            onChanged: (value) {
                              setState(() {
                                _subscribeNewsletter = value ?? false;
                              });
                            },
                            title: Text(
                              'Subscribe to email newsletter',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            activeColor: const Color(0xFF094010),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF094010),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continue',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Terms and conditions
                        Text(
                          'By continuing, you agree to our',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF999999),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Terms of Service',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF094010),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Text(
                              ' and ',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF999999),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Privacy Policy',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF094010),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
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
}
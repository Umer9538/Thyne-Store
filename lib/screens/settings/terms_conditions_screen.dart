import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              'Acceptance of Terms',
              'By accessing and using the Thyne Jewels mobile application, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),

            _buildSection(
              context,
              'Description of Service',
              'Thyne Jewels provides an e-commerce platform for purchasing jewelry and accessories through our mobile application. Our services include:\n\n'
              '• Product catalog and browsing\n'
              '• Secure online purchasing\n'
              '• Order management and tracking\n'
              '• Customer support services\n'
              '• Loyalty rewards program\n'
              '• Wishlist and favorites management',
            ),

            _buildSection(
              context,
              'User Accounts',
              'To access certain features of our service, you must create an account. You agree to:\n\n'
              '• Provide accurate and complete information\n'
              '• Maintain the confidentiality of your account credentials\n'
              '• Notify us immediately of any unauthorized use\n'
              '• Accept responsibility for all activities under your account\n'
              '• Use the service only for lawful purposes',
            ),

            _buildSection(
              context,
              'Product Information and Pricing',
              'We strive to provide accurate product descriptions, images, and pricing. However:\n\n'
              '• Product colors may vary due to display settings\n'
              '• Prices are subject to change without notice\n'
              '• Product availability is not guaranteed\n'
              '• We reserve the right to correct pricing errors\n'
              '• Product descriptions are for general information only',
            ),

            _buildSection(
              context,
              'Orders and Payments',
              'When you place an order, you agree that:\n\n'
              '• All information provided is accurate and complete\n'
              '• You are authorized to use the payment method\n'
              '• Orders are subject to availability and acceptance\n'
              '• We may cancel orders for any reason\n'
              '• Payment is due at the time of purchase\n'
              '• Additional charges may apply for shipping and taxes',
            ),

            _buildSection(
              context,
              'Shipping and Delivery',
              'Shipping terms include:\n\n'
              '• Delivery times are estimates, not guarantees\n'
              '• Risk of loss transfers upon delivery to carrier\n'
              '• Additional customs fees may apply for international orders\n'
              '• We are not responsible for delays caused by carrier or customs\n'
              '• Signature confirmation may be required for high-value items',
            ),

            _buildSection(
              context,
              'Returns and Exchanges',
              'Our return policy includes:\n\n'
              '• Items must be returned within 30 days of delivery\n'
              '• Items must be in original condition with tags attached\n'
              '• Custom or personalized items are non-returnable\n'
              '• Return shipping costs are customer\'s responsibility\n'
              '• Refunds will be processed to original payment method\n'
              '• Processing time for refunds is 5-10 business days',
            ),

            _buildSection(
              context,
              'Intellectual Property',
              'All content on our platform is protected by intellectual property laws:\n\n'
              '• Trademarks, logos, and brand names are our property\n'
              '• Product images and descriptions are copyrighted\n'
              '• Users may not reproduce content without permission\n'
              '• App design and functionality are proprietary\n'
              '• Violations may result in legal action',
            ),

            _buildSection(
              context,
              'User Conduct',
              'Users agree not to:\n\n'
              '• Use the service for illegal activities\n'
              '• Violate any local, state, or federal laws\n'
              '• Infringe on intellectual property rights\n'
              '• Transmit harmful or malicious code\n'
              '• Attempt to gain unauthorized access\n'
              '• Interfere with service operation\n'
              '• Post false or misleading information',
            ),

            _buildSection(
              context,
              'Privacy and Data Protection',
              'Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your personal information. By using our service, you consent to our data practices as outlined in the Privacy Policy.',
            ),

            _buildSection(
              context,
              'Limitation of Liability',
              'To the maximum extent permitted by law:\n\n'
              '• Our liability is limited to the amount you paid for products\n'
              '• We are not liable for indirect or consequential damages\n'
              '• Service is provided "as is" without warranties\n'
              '• We do not guarantee uninterrupted service availability\n'
              '• Users assume risk for service use',
            ),

            _buildSection(
              context,
              'Indemnification',
              'You agree to indemnify and hold harmless Thyne Jewels, its officers, directors, employees, and agents from any claims, damages, or expenses arising from your use of the service or violation of these terms.',
            ),

            _buildSection(
              context,
              'Governing Law',
              'These terms are governed by the laws of [Your Jurisdiction] without regard to conflict of law principles. Any disputes will be resolved in the courts of [Your Jurisdiction].',
            ),

            _buildSection(
              context,
              'Termination',
              'We reserve the right to terminate or suspend your account and access to the service at our sole discretion, without notice, for any reason, including violation of these terms.',
            ),

            _buildSection(
              context,
              'Changes to Terms',
              'We reserve the right to modify these terms at any time. Changes will be effective immediately upon posting. Continued use of the service constitutes acceptance of modified terms. We encourage you to review these terms periodically.',
            ),

            _buildSection(
              context,
              'Contact Information',
              'If you have questions about these Terms and Conditions, please contact us:\n\n'
              'Email: legal@thynejewels.com\n'
              'Phone: +1 (555) 123-4567\n'
              'Address: 123 Jewelry Lane, Gem City, GC 12345\n\n'
              'Business Hours: Monday - Friday, 9:00 AM - 6:00 PM',
            ),

            _buildSection(
              context,
              'Severability',
              'If any provision of these terms is found to be unenforceable, the remaining provisions will continue in full force and effect. The unenforceable provision will be replaced with an enforceable provision that most closely reflects the original intent.',
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGold.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.gavel,
                        color: AppTheme.primaryGold,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Legal Agreement',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'By using our service, you agree to these terms and conditions. Please read them carefully and contact us if you have any questions.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
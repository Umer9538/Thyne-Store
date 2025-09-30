import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Thyne Jewels',
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
              'Introduction',
              'At Thyne Jewels, we are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
            ),

            _buildSection(
              context,
              'Information We Collect',
              'We collect information you provide directly to us, such as:\n\n'
              '• Personal Information: Name, email address, phone number, shipping address\n'
              '• Account Information: Username, password, preferences\n'
              '• Payment Information: Credit card details, billing address (processed securely)\n'
              '• Purchase History: Order details, transaction records\n'
              '• Device Information: Device type, operating system, unique device identifiers\n'
              '• Usage Data: App usage patterns, features accessed, time spent',
            ),

            _buildSection(
              context,
              'How We Use Your Information',
              'We use the information we collect to:\n\n'
              '• Process and fulfill your orders\n'
              '• Provide customer service and support\n'
              '• Send order confirmations and updates\n'
              '• Personalize your shopping experience\n'
              '• Improve our app and services\n'
              '• Send promotional communications (with your consent)\n'
              '• Prevent fraud and enhance security\n'
              '• Comply with legal obligations',
            ),

            _buildSection(
              context,
              'Information Sharing',
              'We do not sell, trade, or rent your personal information to third parties. We may share your information in the following circumstances:\n\n'
              '• Service Providers: With trusted third-party vendors who help us operate our business\n'
              '• Payment Processors: To process your transactions securely\n'
              '• Shipping Partners: To deliver your orders\n'
              '• Legal Requirements: When required by law or to protect our rights\n'
              '• Business Transfers: In connection with a merger, sale, or acquisition',
            ),

            _buildSection(
              context,
              'Data Security',
              'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. This includes:\n\n'
              '• Encryption of sensitive data\n'
              '• Secure data transmission protocols\n'
              '• Regular security assessments\n'
              '• Limited access to personal information\n'
              '• Employee training on data protection',
            ),

            _buildSection(
              context,
              'Your Rights and Choices',
              'You have the following rights regarding your personal information:\n\n'
              '• Access: Request access to your personal information\n'
              '• Correction: Request correction of inaccurate information\n'
              '• Deletion: Request deletion of your personal information\n'
              '• Portability: Request a copy of your data in a portable format\n'
              '• Opt-out: Unsubscribe from marketing communications\n'
              '• Account Deletion: Delete your account and associated data',
            ),

            _buildSection(
              context,
              'Cookies and Tracking',
              'Our app may use cookies and similar tracking technologies to enhance your experience. These technologies help us:\n\n'
              '• Remember your preferences\n'
              '• Analyze app usage patterns\n'
              '• Provide personalized content\n'
              '• Improve app performance\n\n'
              'You can manage your cookie preferences through your device settings.',
            ),

            _buildSection(
              context,
              'Third-Party Services',
              'Our app may integrate with third-party services such as:\n\n'
              '• Payment processors (Razorpay, etc.)\n'
              '• Analytics services\n'
              '• Social media platforms\n'
              '• Customer support tools\n\n'
              'These third parties have their own privacy policies, and we encourage you to review them.',
            ),

            _buildSection(
              context,
              'Children\'s Privacy',
              'Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we become aware that we have collected personal information from a child under 13, we will take steps to delete such information.',
            ),

            _buildSection(
              context,
              'International Data Transfers',
              'Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your personal information in accordance with applicable data protection laws.',
            ),

            _buildSection(
              context,
              'Changes to Privacy Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new Privacy Policy on this page and updating the "Last updated" date. We encourage you to review this Privacy Policy periodically.',
            ),

            _buildSection(
              context,
              'Contact Us',
              'If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us at:\n\n'
              'Email: privacy@thynejewels.com\n'
              'Phone: +1 (555) 123-4567\n'
              'Address: 123 Jewelry Lane, Gem City, GC 12345\n\n'
              'We will respond to your inquiries within 30 days.',
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
                        Icons.security,
                        color: AppTheme.primaryGold,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Your Privacy Matters',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We are committed to protecting your privacy and maintaining the confidentiality of your personal information. Your trust is important to us.',
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
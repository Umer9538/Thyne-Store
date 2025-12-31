import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/thyne_theme.dart';

class AiCreateSection extends StatefulWidget {
  const AiCreateSection({Key? key}) : super(key: key);

  @override
  State<AiCreateSection> createState() => _AiCreateSectionState();
}

class _AiCreateSectionState extends State<AiCreateSection> {
  String selectedSubTab = 'chat';
  final TextEditingController _promptController = TextEditingController();
  final List<Map<String, dynamic>> _creations = [];
  final List<Map<String, dynamic>> _history = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5), // Light gray background matching Figma
      child: Column(
        children: [
          // Sub Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildSubTab('chat', 'AI Chat'),
                const SizedBox(width: 8),
                _buildSubTab('creations', 'My Creations'),
                const SizedBox(width: 8),
                _buildSubTab('history', 'History'),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildSubContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTab(String tab, String label) {
    final isActive = selectedSubTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedSubTab = tab),
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFE8E8F0) // Light purple/gray for active
                : const Color(0xFFFFFFFF), // White for inactive
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFD0D0D0),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2D2D2D),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubContent() {
    switch (selectedSubTab) {
      case 'chat':
        return _buildChatInterface();
      case 'creations':
        return _buildCreationsGrid();
      case 'history':
        return _buildHistory();
      default:
        return _buildChatInterface();
    }
  }

  Widget _buildChatInterface() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Welcome Message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThyneTheme.createBlue.withOpacity(0.1),
                  ThyneTheme.createBlue.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ThyneTheme.createBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  CupertinoIcons.sparkles,
                  size: 48,
                  color: ThyneTheme.createBlue,
                ),
                const SizedBox(height: 16),
                Text(
                  'AI Jewelry Designer',
                  style: GoogleFonts.inter(
                    fontSize: ThyneTheme.textHeadingMd,
                    fontWeight: FontWeight.w600,
                    color: ThyneTheme.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Describe your dream jewelry piece and let AI bring it to life',
                  style: GoogleFonts.inter(
                    fontSize: ThyneTheme.textBody,
                    color: ThyneTheme.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sample Prompts
          Text(
            'Try these prompts:',
            style: GoogleFonts.inter(
              fontSize: ThyneTheme.textBodySm,
              fontWeight: FontWeight.w500,
              color: ThyneTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPromptChip('Minimalist gold ring'),
              _buildPromptChip('Diamond tennis bracelet'),
              _buildPromptChip('Vintage pearl necklace'),
              _buildPromptChip('Modern engagement ring'),
            ],
          ),

          const Spacer(),

          // Input Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: ThyneTheme.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      hintText: 'Describe your dream jewelry...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: ThyneTheme.textBody,
                        color: ThyneTheme.mutedForeground.withOpacity(0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: ThyneTheme.textBody,
                      color: ThyneTheme.foreground,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  child: IconButton(
                    onPressed: _handleGenerate,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ThyneTheme.createBlue,
                            ThyneTheme.createBlue.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.sparkles,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return GestureDetector(
      onTap: () {
        _promptController.text = prompt;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ThyneTheme.createBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ThyneTheme.createBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          prompt,
          style: GoogleFonts.inter(
            fontSize: ThyneTheme.textFootnote,
            color: ThyneTheme.createBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildCreationsGrid() {
    if (_creations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.cube_box,
              size: 64,
              color: ThyneTheme.mutedForeground.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No creations yet',
              style: GoogleFonts.inter(
                fontSize: ThyneTheme.textHeadingSm,
                fontWeight: FontWeight.w500,
                color: ThyneTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start creating with AI to see your designs here',
              style: GoogleFonts.inter(
                fontSize: ThyneTheme.textBody,
                color: ThyneTheme.mutedForeground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _creations.length,
      itemBuilder: (context, index) {
        final creation = _creations[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ThyneTheme.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: ThyneTheme.muted,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.photo,
                    size: 48,
                    color: ThyneTheme.mutedForeground.withOpacity(0.3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creation['title'] ?? 'AI Creation',
                      style: GoogleFonts.inter(
                        fontSize: ThyneTheme.textBodySm,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      creation['prompt'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: ThyneTheme.textFootnote,
                        color: ThyneTheme.mutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.clock,
              size: 64,
              color: ThyneTheme.mutedForeground.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No history yet',
              style: GoogleFonts.inter(
                fontSize: ThyneTheme.textHeadingSm,
                fontWeight: FontWeight.w500,
                color: ThyneTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your AI generation history will appear here',
              style: GoogleFonts.inter(
                fontSize: ThyneTheme.textBody,
                color: ThyneTheme.mutedForeground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ThyneTheme.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.sparkles,
                size: 24,
                color: ThyneTheme.createBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['prompt'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: ThyneTheme.textBody,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['timestamp'] ?? 'Just now',
                      style: GoogleFonts.inter(
                        fontSize: ThyneTheme.textFootnote,
                        color: ThyneTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: ThyneTheme.mutedForeground,
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleGenerate() {
    if (_promptController.text.isNotEmpty) {
      // TODO: Implement AI generation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI generation coming soon!'),
          backgroundColor: ThyneTheme.createBlue,
        ),
      );

      // Add to history
      setState(() {
        _history.insert(0, {
          'prompt': _promptController.text,
          'timestamp': 'Just now',
        });
      });

      _promptController.clear();
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
}
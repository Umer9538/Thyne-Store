import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

// Import theme and providers
import '../../../theme/thyne_theme.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/ai_provider.dart';
import '../../../data/models/ai_creation.dart';
import '../../../utils/prompt_validator.dart';

class CreateSection extends StatefulWidget {
  const CreateSection({Key? key}) : super(key: key);

  @override
  State<CreateSection> createState() => _CreateSectionState();
}

class _CreateSectionState extends State<CreateSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final FocusNode _promptFocusNode = FocusNode();

  // State variables
  int _selectedTab = 1; // Start with "My Creations" tab
  String _selectedCategory = 'all';
  bool _isInputVisible = false; // Control input visibility

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiProvider = Provider.of<AIProvider>(context, listen: false);
      aiProvider.loadCreations();
      aiProvider.loadSuggestions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    _chatScrollController.dispose();
    _promptFocusNode.dispose();
    super.dispose();
  }

  void _showValidationDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(CupertinoIcons.info_circle, color: ThyneTheme.primaryRed),
            const SizedBox(width: 12),
            const Text('Jewelry Design Only'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _generateImage() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a jewelry description'),
          backgroundColor: ThyneTheme.primaryRed,
        ),
      );
      return;
    }

    // Validate prompt
    final validation = PromptValidator.validatePrompt(prompt);
    if (!validation.isValid) {
      _showValidationDialog(validation.message!);
      return;
    }

    // Generate image using AI provider
    final aiProvider = Provider.of<AIProvider>(context, listen: false);
    final success = await aiProvider.generateJewelryImage(prompt);

    if (success) {
      _promptController.clear();
      _promptFocusNode.unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Your jewelry design has been created!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (aiProvider.errorMessage != null &&
               !aiProvider.errorMessage!.contains('jewelry')) {
      // Show other errors as snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aiProvider.errorMessage!),
          backgroundColor: ThyneTheme.primaryRed,
        ),
      );
    }
  }

  Widget _buildCreationsTab() {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, _) {
        return Column(
          children: [
            // Input Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThyneTheme.cardBackground,
                border: Border(
                  bottom: BorderSide(color: ThyneTheme.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'AI Jewelry Designer',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Describe your dream jewelry piece and let AI bring it to life',
                    style: TextStyle(
                      color: ThyneTheme.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ThyneTheme.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promptController,
                            focusNode: _promptFocusNode,
                            decoration: const InputDecoration(
                              hintText: 'Describe your jewelry design...',
                              hintStyle: TextStyle(color: ThyneTheme.mutedForeground),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _generateImage(),
                          ),
                        ),
                        if (aiProvider.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            onPressed: _generateImage,
                            icon: const Icon(
                              CupertinoIcons.sparkles,
                              color: ThyneTheme.createBlue,
                            ),
                            tooltip: 'Generate',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Suggestion Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text(
                          'Try these:',
                          style: TextStyle(
                            fontSize: 12,
                            color: ThyneTheme.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...PromptValidator.getPromptSuggestions()
                            .take(4)
                            .map((suggestion) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    label: Text(
                                      suggestion.length > 30
                                          ? '${suggestion.substring(0, 30)}...'
                                          : suggestion,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: ThyneTheme.cardBackground,
                                    onPressed: () {
                                      _promptController.text = suggestion;
                                      _generateImage();
                                    },
                                  ),
                                )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Creations Grid
            Expanded(
              child: aiProvider.creations.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: aiProvider.creations.length,
                      itemBuilder: (context, index) {
                        final creation = aiProvider.creations[index];
                        return _buildCreationCard(creation);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreationCard(AICreation creation) {
    return GestureDetector(
      onTap: () => _showCreationDetails(creation),
      child: Container(
        decoration: BoxDecoration(
          color: ThyneTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _buildCreationImage(creation),
                ),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    creation.prompt,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(creation.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: ThyneTheme.mutedForeground,
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

  Widget _buildCreationImage(AICreation creation) {
    if (creation.imageUrl.startsWith('data:image')) {
      // Base64 image
      final base64String = creation.imageUrl.split(',').last;
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    } else if (creation.imageUrl.startsWith('http')) {
      // Network image
      return CachedNetworkImage(
        imageUrl: creation.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildImagePlaceholder(),
        errorWidget: (context, url, error) => _buildImagePlaceholder(),
      );
    } else {
      return _buildImagePlaceholder();
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, _) {
        if (aiProvider.history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.clock,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No history yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your generation history will appear here',
                  style: TextStyle(
                    color: ThyneTheme.mutedForeground,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: aiProvider.history.length,
          itemBuilder: (context, index) {
            final item = aiProvider.history[index];
            return _buildHistoryItem(item);
          },
        );
      },
    );
  }

  Widget _buildHistoryItem(AICreation creation) {
    final isSuccess = creation.isSuccessful;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ThyneTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? ThyneTheme.border : Colors.red.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSuccess ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isSuccess ? CupertinoIcons.checkmark_circle : CupertinoIcons.xmark_circle,
            color: isSuccess ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          creation.prompt,
          style: const TextStyle(fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          isSuccess
              ? _formatDate(creation.createdAt)
              : creation.errorMessage ?? 'Failed to generate',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(CupertinoIcons.ellipsis_vertical, size: 18),
          onSelected: (value) async {
            if (value == 'delete') {
              final aiProvider = Provider.of<AIProvider>(context, listen: false);
              await aiProvider.deleteCreation(creation.id);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item deleted from history'),
                ),
              );
            } else if (value == 'retry' && !isSuccess) {
              _promptController.text = creation.prompt;
              _tabController.animateTo(1); // Switch to creations tab
              _generateImage();
            }
          },
          itemBuilder: (context) => [
            if (!isSuccess)
              const PopupMenuItem(
                value: 'retry',
                child: Text('Retry'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
        onTap: isSuccess ? () => _showCreationDetails(creation) : null,
      ),
    );
  }

  Widget _buildChatTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_2,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'AI Chat Coming Soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Chat with our AI assistant to get personalized jewelry recommendations and design advice',
              style: TextStyle(
                color: ThyneTheme.mutedForeground,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.sparkles,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No creations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start by describing your dream jewelry piece',
            style: TextStyle(
              color: ThyneTheme.mutedForeground,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _promptFocusNode.requestFocus();
            },
            icon: const Icon(CupertinoIcons.add),
            label: const Text('Create Your First Design'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThyneTheme.createBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreationDetails(AICreation creation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildCreationImage(creation),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Prompt
                    const Text(
                      'Your Design Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      creation.prompt,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    // Design Description (if available)
                    if (creation.metadata?['designDescription'] != null) ...[
                      const Text(
                        'AI Design Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        creation.metadata!['designDescription'],
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Created Date
                    Text(
                      'Created on ${_formatDate(creation.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ThyneTheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement save to gallery
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Saving to gallery...'),
                                ),
                              );
                            },
                            icon: const Icon(CupertinoIcons.download_circle),
                            label: const Text('Save'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement share
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sharing...'),
                                ),
                              );
                            },
                            icon: const Icon(CupertinoIcons.share),
                            label: const Text('Share'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final aiProvider = Provider.of<AIProvider>(context, listen: false);
                          await aiProvider.deleteCreation(creation.id);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Creation deleted'),
                            ),
                          );
                        },
                        icon: const Icon(CupertinoIcons.trash),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return _buildAuthPrompt();
    }

    return Scaffold(
      backgroundColor: ThyneTheme.background,
      body: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: ThyneTheme.cardBackground,
              border: Border(
                bottom: BorderSide(color: ThyneTheme.border),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: ThyneTheme.createBlue,
              labelColor: ThyneTheme.createBlue,
              unselectedLabelColor: ThyneTheme.mutedForeground,
              tabs: const [
                Tab(text: 'AI Chat'),
                Tab(text: 'My Creations'),
                Tab(text: 'History'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatTab(),
                _buildCreationsTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthPrompt() {
    return Container(
      color: ThyneTheme.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.lock_shield,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign in to Create',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Create AI-powered jewelry designs and save your creations',
                style: TextStyle(
                  color: ThyneTheme.mutedForeground,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThyneTheme.primaryGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
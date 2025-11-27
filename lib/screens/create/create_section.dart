import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

// Import theme and providers
import '../../theme/thyne_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ai_provider.dart';
import '../../models/ai_creation.dart';
import '../../utils/prompt_validator.dart';

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
  bool _showInputField = false;

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
      setState(() {
        _showInputField = false;
      });

      // Force reload creations to ensure they're displayed
      await aiProvider.loadCreations();

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

  Widget _buildCreationsTab() {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, _) {
        return Stack(
          children: [
            Column(
              children: [
                // Header with title and generate button
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'AI Jewelry Designer',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Describe your dream jewelry piece and let AI bring it to life',
                                style: TextStyle(
                                  color: ThyneTheme.mutedForeground,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                                          suggestion.length > 25
                                              ? '${suggestion.substring(0, 25)}...'
                                              : suggestion,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: ThyneTheme.cardBackground,
                                        side: BorderSide(color: ThyneTheme.border),
                                        onPressed: () {
                                          _promptController.text = suggestion;
                                          setState(() {
                                            _showInputField = true;
                                          });
                                          Future.delayed(const Duration(milliseconds: 300), () {
                                            _promptFocusNode.requestFocus();
                                          });
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
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 160), // Add more padding for button and input field
                          child: GridView.builder(
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
                ),
              ],
            ),

            // Floating Input Field (positioned above bottom nav)
            Positioned(
              bottom: 80, // Move up to avoid being hidden by bottom nav
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showInputField ? 80 : 70,
                decoration: BoxDecoration(
                  color: ThyneTheme.cardBackground,
                  border: Border(
                    top: BorderSide(color: ThyneTheme.border),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _showInputField
                    ? Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showInputField = false;
                                _promptController.clear();
                              });
                            },
                            icon: const Icon(CupertinoIcons.xmark),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _promptController,
                              focusNode: _promptFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Describe your jewelry design...',
                                hintStyle: const TextStyle(color: ThyneTheme.mutedForeground),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: ThyneTheme.border),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _generateImage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (aiProvider.isLoading)
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: Padding(
                                padding: EdgeInsets.all(8),
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
                      )
                    : Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showInputField = true;
                            });
                            Future.delayed(const Duration(milliseconds: 300), () {
                              _promptFocusNode.requestFocus();
                            });
                          },
                          icon: const Icon(CupertinoIcons.sparkles),
                          label: const Text('Generate New Design'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThyneTheme.createBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThyneTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: _buildCreationImage(creation),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      creation.prompt,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
    if (creation.imageUrl.isEmpty) {
      return _buildImagePlaceholder();
    }

    // For any URL (including DiceBear API), show it directly
    return CachedNetworkImage(
      imageUrl: creation.imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.withOpacity(0.3),
              Colors.blue.withOpacity(0.3),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) {
        // If network image fails, show a colored gradient
        final hashCode = creation.prompt.hashCode.abs();
        final hue = (hashCode % 360).toDouble();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor(),
                HSLColor.fromAHSL(1.0, (hue + 60) % 360, 0.7, 0.4).toColor(),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                CupertinoIcons.sparkles,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              Positioned(
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AI Generated',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
              ? 'Created ${_formatDate(creation.createdAt)}'
              : creation.errorMessage ?? 'Generation failed',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isSuccess
            ? IconButton(
                icon: const Icon(CupertinoIcons.arrow_right),
                onPressed: () => _showCreationDetails(creation),
              )
            : IconButton(
                icon: const Icon(CupertinoIcons.refresh),
                onPressed: () {
                  _promptController.text = creation.prompt;
                  _generateImage();
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80), // Add padding to avoid overlap
      child: Center(
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
              setState(() {
                _showInputField = true;
              });
              Future.delayed(const Duration(milliseconds: 300), () {
                _promptFocusNode.requestFocus();
              });
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ThyneTheme.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: _buildCreationImage(creation),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Prompt
                    const Text(
                      'Design Prompt',
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

                    // Description (if available)
                    if (creation.metadata?['designDescription'] != null) ...[
                      const Text(
                        'Design Description',
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

                    // Metadata
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Created ${_formatDate(creation.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement save to gallery
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Saving to gallery...'),
                                ),
                              );
                            },
                            icon: const Icon(CupertinoIcons.square_arrow_down),
                            label: const Text('Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ThyneTheme.primaryGold,
                              foregroundColor: Colors.white,
                            ),
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
    // Temporarily disabled auth check for testing
    // final authProvider = Provider.of<AuthProvider>(context);
    // if (!authProvider.isAuthenticated) {
    //   return _buildAuthPrompt();
    // }

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
                'Create amazing jewelry designs with AI',
                style: TextStyle(
                  color: ThyneTheme.mutedForeground,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              icon: const Icon(CupertinoIcons.person),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThyneTheme.primaryGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Import theme and providers
import '../../../theme/thyne_theme.dart';
import '../viewmodels/auth_provider.dart';
import '../viewmodels/ai_provider.dart';
import '../../data/models/ai_creation.dart';
import '../../data/models/product.dart';
import '../../data/models/conversation.dart';
import '../../../utils/prompt_validator.dart';
import '../../data/services/api_service.dart';
import '../product/product_detail_screen.dart';

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

  // State for price estimation
  PriceEstimate? _currentPriceEstimate;
  bool _isLoadingPrice = false;

  // Track last image generation prompt for context
  String? _lastImagePrompt;

  @override
  void initState() {
    super.initState();
    // 3 tabs: Create (conversation), History, My Creations
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiProvider = Provider.of<AIProvider>(context, listen: false);

      // Start a new conversation when entering Create section
      if (!aiProvider.hasActiveConversation) {
        aiProvider.startNewConversation();
      }

      // Load conversations and token usage
      aiProvider.loadConversations();
      aiProvider.loadTokenUsage();
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

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// Send message using conversation-style
  void _sendMessage(AIProvider aiProvider, {String? contextPrompt}) async {
    final message = _promptController.text.trim();
    if (message.isEmpty) return;

    // Check token limit before generation
    final canGenerate = await aiProvider.checkCanGenerateImage();
    if (!canGenerate) {
      _showTokenLimitDialog();
      return;
    }

    _promptController.clear();
    _promptFocusNode.unfocus();

    // Reset price estimate for new request
    setState(() {
      _currentPriceEstimate = null;
    });

    // Build message with context from previous image generation if available
    String finalMessage = message;
    final effectiveContext = contextPrompt ?? _lastImagePrompt;

    if (effectiveContext != null && _isModificationRequest(message)) {
      // If user is making a modification request, include context
      finalMessage = 'Based on the previous design "$effectiveContext", $message';
    }

    final result = await aiProvider.sendConversationMessage(finalMessage);

    if (result != null && result.isSuccessful) {
      _scrollToBottom();

      if (result.isImageResult) {
        // Track this prompt for future context
        setState(() {
          _lastImagePrompt = message;
        });

        // Reload token usage after image generation
        aiProvider.loadTokenUsage();

        // Auto-fetch price estimate using the actual prompt
        _fetchPriceEstimate(aiProvider, specificPrompt: finalMessage);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Design generated!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Check if the message is a modification request (not a new design)
  bool _isModificationRequest(String message) {
    final lowerMessage = message.toLowerCase();
    final modificationKeywords = [
      'add', 'remove', 'change', 'make it', 'more', 'less', 'bigger', 'smaller',
      'different', 'another', 'also', 'instead', 'replace', 'modify', 'update',
      'same but', 'similar', 'like that', 'keep', 'with', 'without', 'lighter',
      'darker', 'brighter', 'thinner', 'thicker', 'taller', 'shorter'
    ];

    return modificationKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Send message with explicit context (for edit feature)
  void _sendMessageWithContext(AIProvider aiProvider, String message, String originalPrompt) async {
    // Check token limit before generation
    final canGenerate = await aiProvider.checkCanGenerateImage();
    if (!canGenerate) {
      _showTokenLimitDialog();
      return;
    }

    // Reset price estimate for new request
    setState(() {
      _currentPriceEstimate = null;
    });

    final result = await aiProvider.sendConversationMessage(message);

    if (result != null && result.isSuccessful) {
      _scrollToBottom();

      if (result.isImageResult) {
        // Update last image prompt to the new edited version
        setState(() {
          _lastImagePrompt = message;
        });

        // Reload token usage after image generation
        aiProvider.loadTokenUsage();

        // Auto-fetch price estimate using the edited prompt
        _fetchPriceEstimate(aiProvider, specificPrompt: message);

        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
              content: Text('Design regenerated!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThyneTheme.background,
      body: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: ThyneTheme.cardBackground,
              border: Border(bottom: BorderSide(color: ThyneTheme.border)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: ThyneTheme.createBlue,
              labelColor: ThyneTheme.createBlue,
              unselectedLabelColor: ThyneTheme.mutedForeground,
              tabs: const [
                Tab(text: 'Create'),
                Tab(text: 'History'),
                Tab(text: 'My Creations'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConversationTab(),
                _buildHistoryTab(),
                _buildCreationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Conversation-style Create tab
  Widget _buildConversationTab() {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, _) {
        final messages = aiProvider.currentMessages;

        return Stack(
          children: [
            Column(
              children: [
                // Header with new conversation button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: ThyneTheme.cardBackground,
                    border: Border(bottom: BorderSide(color: ThyneTheme.border)),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.sparkles, color: ThyneTheme.createBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiProvider.currentConversation?.title ?? 'New Conversation',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Token usage indicator
                      if (aiProvider.tokenUsage != null)
                        _buildCompactTokenIndicator(aiProvider.tokenUsage!),
                      const SizedBox(width: 8),
                      // New conversation button
                      IconButton(
                        onPressed: () {
                          aiProvider.startNewConversation();
                          // Clear context when starting new conversation
                          setState(() {
                            _lastImagePrompt = null;
                          });
                        },
                        icon: const Icon(CupertinoIcons.plus_circle),
                        tooltip: 'New Conversation',
                        color: ThyneTheme.createBlue,
                      ),
                    ],
                  ),
                ),

                // Conversation messages
                Expanded(
                  child: messages.isEmpty
                      ? _buildWelcomeScreen()
                      : ListView.builder(
                          controller: _chatScrollController,
                          padding: EdgeInsets.only(
                            left: 20, right: 20, top: 16,
                            bottom: 160 + MediaQuery.of(context).padding.bottom,
                          ),
                          itemCount: messages.length + (aiProvider.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length && aiProvider.isLoading) {
                              return _buildTypingIndicator();
                            }
                            return _buildConversationMessage(messages[index], aiProvider);
                          },
                        ),
                ),
              ],
            ),

            // Floating input bar - matching Store/Community search bar position
            Positioned(
              bottom: 80 + MediaQuery.of(context).padding.bottom,
              left: 20,
              right: 20,
              child: _buildFloatingInputBar(aiProvider),
            ),
          ],
        );
      },
    );
  }

  /// Compact token usage indicator - shows remaining tokens
  Widget _buildCompactTokenIndicator(TokenUsage usage) {
    Color usageColor = usage.isUsageHigh ? Colors.red :
                       usage.isUsageMedium ? Colors.orange : Colors.green;

    return GestureDetector(
      onTap: () => _showTokenDetailsDialog(usage),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: usageColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: usageColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              usage.isUsageHigh ? CupertinoIcons.exclamationmark_triangle :
              CupertinoIcons.sparkles,
              size: 14,
              color: usageColor,
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usage.tokensRemainingFormatted,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: usageColor,
                  ),
                ),
                Text(
                  'remaining',
                  style: TextStyle(
                    fontSize: 8,
                    color: usageColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show detailed token usage dialog
  void _showTokenDetailsDialog(TokenUsage usage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ThyneTheme.createBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(CupertinoIcons.sparkles, color: ThyneTheme.createBlue, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('AI Token Usage', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (usage.usagePercent / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: usage.isUsageHigh ? Colors.red :
                           usage.isUsageMedium ? Colors.orange : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Token stats
            _buildTokenStatRow('Used', usage.tokensUsedFormatted, Colors.grey[700]!),
            _buildTokenStatRow('Remaining', usage.tokensRemainingFormatted, Colors.green),
            _buildTokenStatRow('Monthly Limit', usage.tokenLimitFormatted, Colors.blue),
            const Divider(height: 24),
            _buildTokenStatRow('Images Generated', '${usage.imageCount}', ThyneTheme.primaryGold),
            _buildTokenStatRow('Resets On', usage.resetDate, Colors.grey[600]!),
            const SizedBox(height: 12),
            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThyneTheme.createBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.info_circle, size: 16, color: ThyneTheme.createBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Each user gets 1M free tokens monthly for AI design generation.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildTokenStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  /// Build a single conversation message
  Widget _buildConversationMessage(ConversationMessage message, AIProvider aiProvider) {
    if (message.type == MessageType.system) {
      return _buildSystemMessage(message);
    }

    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 16,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? ThyneTheme.createBlue : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser ? null : Border.all(color: ThyneTheme.border),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),

          // Image result (simplified - only shows image, cost, and order button)
          if (message.hasImage) ...[
            const SizedBox(height: 12),
            _buildImageResult(message, aiProvider),
          ],

          // Product results
          if (message.hasProducts) ...[
            const SizedBox(height: 12),
            _buildProductsCarousel(message.products!),
          ],
        ],
      ),
    );
  }

  /// System message (welcome, etc.)
  Widget _buildSystemMessage(ConversationMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThyneTheme.createBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThyneTheme.createBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.sparkles, color: ThyneTheme.createBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Simplified image result - shows only image, expected cost, edit and order button
  Widget _buildImageResult(ConversationMessage message, AIProvider aiProvider) {
    final priceEstimate = message.priceEstimate ?? aiProvider.lastPriceEstimate ?? _currentPriceEstimate;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThyneTheme.border),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image with edit overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: _buildImage(message.imageUrl!),
              ),
              // Edit button overlay
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showEditPromptDialog(message, aiProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(CupertinoIcons.pencil, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Simplified footer: Only price and order button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Show the prompt used (tappable to edit)
                GestureDetector(
                  onTap: () => _showEditPromptDialog(message, aiProvider),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.text_quote, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(CupertinoIcons.pencil, size: 14, color: ThyneTheme.createBlue),
                      ],
                    ),
                  ),
                ),

                // Expected cost
                if (_isLoadingPrice)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (priceEstimate != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.tag, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Expected: ${priceEstimate.priceRange}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        // Show jewelry type and metal detected
                        const SizedBox(height: 4),
                        Text(
                          '${priceEstimate.jewelryTypeDisplay} • ${priceEstimate.metalTypeDisplay}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _fetchPriceEstimate(aiProvider, specificPrompt: message.text),
                    icon: const Icon(CupertinoIcons.tag, size: 16),
                    label: const Text('Get Price Estimate'),
                    style: TextButton.styleFrom(
                      foregroundColor: ThyneTheme.primaryGold,
                    ),
                  ),

                // Order Now button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleOrderNow(message, priceEstimate),
                    icon: const Icon(CupertinoIcons.cart_badge_plus),
                    label: const Text('Order Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThyneTheme.primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  /// Show dialog to edit the prompt and regenerate image
  void _showEditPromptDialog(ConversationMessage message, AIProvider aiProvider) {
    final editController = TextEditingController(text: message.text);
    bool isRegenerating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ThyneTheme.createBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.pencil, color: ThyneTheme.createBlue),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Design Prompt',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Modify and regenerate your design',
                            style: TextStyle(fontSize: 12, color: ThyneTheme.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Edit area
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Original prompt (read-only reference)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.clock, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Original: ${message.text}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Editable prompt
                    TextField(
                      controller: editController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Your Design Prompt',
                        hintText: 'Describe your jewelry design...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ThyneTheme.createBlue, width: 2),
                        ),
                      ),
                      autofocus: true,
                    ),

                    const SizedBox(height: 12),

                    // Quick modification suggestions
                    const Text(
                      'Quick modifications:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickModChip('Add more diamonds', editController),
                        _buildQuickModChip('Make it gold', editController),
                        _buildQuickModChip('Add gemstones', editController),
                        _buildQuickModChip('Make it vintage', editController),
                        _buildQuickModChip('More elegant', editController),
                        _buildQuickModChip('Simpler design', editController),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Regenerate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isRegenerating
                            ? null
                            : () async {
                                final newPrompt = editController.text.trim();
                                if (newPrompt.isEmpty) return;

                                setSheetState(() => isRegenerating = true);

                                Navigator.pop(context);

                                // Set the last image prompt for context
                                setState(() {
                                  _lastImagePrompt = message.text;
                                });

                                // Send the edited prompt with context
                                _sendMessageWithContext(aiProvider, newPrompt, message.text);
                              },
                        icon: isRegenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(CupertinoIcons.sparkles),
                        label: Text(isRegenerating ? 'Generating...' : 'Regenerate Design'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThyneTheme.createBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quick modification chip
  Widget _buildQuickModChip(String text, TextEditingController controller) {
    return GestureDetector(
      onTap: () {
        final currentText = controller.text.trim();
        if (currentText.isNotEmpty && !currentText.endsWith('.') && !currentText.endsWith(',')) {
          controller.text = '$currentText, ${text.toLowerCase()}';
        } else if (currentText.isEmpty) {
          controller.text = text;
        } else {
          controller.text = '$currentText ${text.toLowerCase()}';
        }
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ThyneTheme.createBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThyneTheme.createBlue.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: ThyneTheme.createBlue,
          ),
        ),
      ),
    );
  }

  /// Build image from URL (handles base64 and network images)
  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',').last;
        final imageBytes = base64Decode(base64Data);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 250,
        );
      } catch (e) {
        return _buildImagePlaceholder();
      }
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 250,
      placeholder: (context, url) => Container(
        height: 250,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 250,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(CupertinoIcons.photo, size: 48, color: Colors.grey),
      ),
    );
  }

  /// Products carousel
  Widget _buildProductsCarousel(List<Product> products) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) => _buildProductCard(products[index]),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThyneTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: Container(
                height: 100,
                width: double.infinity,
                color: Colors.grey[100],
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          CupertinoIcons.photo,
                          color: Colors.grey[400],
                        ),
                      )
                    : Icon(CupertinoIcons.photo, color: Colors.grey[400]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: ThyneTheme.primaryGold,
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

  /// Typing indicator
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThyneTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: ThyneTheme.mutedForeground.withOpacity(0.3 + (0.7 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  /// Welcome screen when conversation is empty
  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ThyneTheme.createBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.sparkles,
              size: 48,
              color: ThyneTheme.createBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'What would you like to create?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Describe your dream jewelry or ask me to find products',
            style: TextStyle(color: ThyneTheme.mutedForeground, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Quick suggestions
          _buildSuggestionChip('Design a vintage ruby ring'),
          _buildSuggestionChip('Show me gold necklaces under ₹50,000'),
          _buildSuggestionChip('Create a modern diamond bracelet'),
          _buildSuggestionChip('Find pearl earrings for wedding'),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          _promptController.text = text;
          _promptFocusNode.requestFocus();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ThyneTheme.border),
          ),
          child: Row(
            children: [
              Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
              Icon(CupertinoIcons.arrow_right, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  /// Floating input bar - matching Store/Community search bar design
  Widget _buildFloatingInputBar(AIProvider aiProvider) {
    // Green color matching the Store/Community section button
    const Color primaryGreen = Color(0xFF094010);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Context indicator - shows when previous design context is available
          if (_lastImagePrompt != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.link, size: 12, color: primaryGreen),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Context: "${_lastImagePrompt!.length > 30 ? '${_lastImagePrompt!.substring(0, 30)}...' : _lastImagePrompt}"',
                      style: TextStyle(
                        fontSize: 10,
                        color: primaryGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _lastImagePrompt = null),
                    child: Icon(CupertinoIcons.xmark_circle_fill, size: 14, color: primaryGreen.withOpacity(0.5)),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              // Sparkles button - matching Store/Community green circular button design
              GestureDetector(
                onTap: aiProvider.isLoading ? null : () => _sendMessage(aiProvider),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: aiProvider.isLoading ? Colors.grey : primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: aiProvider.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(CupertinoIcons.sparkles, size: 28, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              // Input field - matching Store/Community search bar design
              Expanded(
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.search,
                        size: 20,
                        color: const Color(0xFF666666),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _promptController,
                          focusNode: _promptFocusNode,
                          decoration: InputDecoration(
                            hintText: 'ask me anything',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF999999),
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 14),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(aiProvider),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.mic,
                        size: 20,
                        color: const Color(0xFF666666),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// History tab - shows past conversations
  Widget _buildHistoryTab() {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, _) {
        final conversations = aiProvider.activeConversations;

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.clock, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No Conversations Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your chat history will appear here',
                  style: TextStyle(color: ThyneTheme.mutedForeground, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    aiProvider.startNewConversation();
                    _tabController.animateTo(0);
                  },
                  icon: const Icon(CupertinoIcons.plus),
                  label: const Text('Start Conversation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThyneTheme.createBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _buildConversationCard(conversation, aiProvider);
          },
        );
      },
    );
  }

  Widget _buildConversationCard(Conversation conversation, AIProvider aiProvider) {
    final hasImages = conversation.hasGeneratedImages;

    return GestureDetector(
      onTap: () async {
        await aiProvider.resumeConversation(conversation.id);
        _tabController.animateTo(0);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThyneTheme.border),
        ),
        child: Row(
          children: [
            // Thumbnail or icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: hasImages
                    ? ThyneTheme.createBlue.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasImages ? CupertinoIcons.photo : CupertinoIcons.chat_bubble_2,
                color: hasImages ? ThyneTheme.createBlue : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.previewText,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(conversation.updatedAt),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            IconButton(
              onPressed: () => _showDeleteConversationDialog(conversation.id, aiProvider),
              icon: Icon(CupertinoIcons.trash, size: 18, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConversationDialog(String conversationId, AIProvider aiProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation?'),
        content: const Text('This will permanently delete this conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              aiProvider.deleteConversation(conversationId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// My Creations tab - shows all generated images
  Widget _buildCreationsTab() {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, _) {
        final creations = aiProvider.library;

        if (creations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo_on_rectangle, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No Creations Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your AI-generated designs will appear here',
                  style: TextStyle(color: ThyneTheme.mutedForeground, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(0),
                  icon: const Icon(CupertinoIcons.sparkles),
                  label: const Text('Create Your First Design'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThyneTheme.createBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThyneTheme.cardBackground,
                border: Border(bottom: BorderSide(color: ThyneTheme.border)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.photo_on_rectangle, color: ThyneTheme.createBlue),
                  const SizedBox(width: 8),
                  const Text(
                    'Your Designs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${creations.length} items',
                    style: const TextStyle(color: ThyneTheme.mutedForeground, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: creations.length,
                itemBuilder: (context, index) => _buildCreationCard(creations[index]),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThyneTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: SizedBox(
                  width: double.infinity,
                  child: _buildCreationImage(creation),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    creation.prompt,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(creation.createdAt),
                    style: const TextStyle(fontSize: 10, color: ThyneTheme.mutedForeground),
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

    if (creation.imageUrl.startsWith('data:image')) {
      try {
        final base64Data = creation.imageUrl.split(',').last;
        final imageBytes = base64Decode(base64Data);
        return Image.memory(imageBytes, fit: BoxFit.cover);
      } catch (e) {
        return _buildImagePlaceholder();
      }
    }

    return CachedNetworkImage(
      imageUrl: creation.imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => _buildImagePlaceholder(),
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
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                    const Text('Design Prompt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(creation.prompt, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 20),
                    // Date
                    Row(
                      children: [
                        Icon(CupertinoIcons.time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Created ${_formatDate(creation.createdAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Order button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleOrderFromCreation(creation);
                        },
                        icon: const Icon(CupertinoIcons.cart_badge_plus),
                        label: const Text('Order This Design'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThyneTheme.primaryGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Delete button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final aiProvider = Provider.of<AIProvider>(context, listen: false);
                          await aiProvider.deleteCreation(creation.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Creation deleted')),
                          );
                        },
                        icon: const Icon(CupertinoIcons.trash),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
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

  /// Fetch price estimate based on the actual prompt used
  Future<void> _fetchPriceEstimate(AIProvider aiProvider, {String? specificPrompt}) async {
    setState(() => _isLoadingPrice = true);

    try {
      // Use specific prompt if provided, otherwise try to get from current message or last image prompt
      String prompt = specificPrompt ??
                      _lastImagePrompt ??
                      aiProvider.currentGeneratingPrompt ??
                      'jewelry design';

      // Extract jewelry type and metal from the prompt for better estimation
      final jewelryType = _detectJewelryTypeFromPrompt(prompt);
      final metalType = _detectMetalTypeFromPrompt(prompt);

      final estimate = await aiProvider.estimatePrice(
        prompt,
        jewelryType: jewelryType,
        metalType: metalType,
      );
      setState(() {
        _currentPriceEstimate = estimate;
        _isLoadingPrice = false;
      });
    } catch (e) {
      print('Error fetching price estimate: $e');
      setState(() => _isLoadingPrice = false);
    }
  }

  /// Detect jewelry type from prompt for price estimation
  String? _detectJewelryTypeFromPrompt(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('ring') || lower.contains('engagement') || lower.contains('band') || lower.contains('solitaire')) {
      return 'ring';
    }
    if (lower.contains('necklace') || lower.contains('chain') || lower.contains('choker')) {
      return 'necklace';
    }
    if (lower.contains('bracelet') || lower.contains('tennis') || lower.contains('cuff')) {
      return 'bracelet';
    }
    if (lower.contains('earring') || lower.contains('stud') || lower.contains('hoop') || lower.contains('drop')) {
      return 'earring';
    }
    if (lower.contains('pendant') || lower.contains('locket')) {
      return 'pendant';
    }
    if (lower.contains('bangle') || lower.contains('kada')) {
      return 'bangle';
    }

    return null;
  }

  /// Detect metal type from prompt for price estimation
  String? _detectMetalTypeFromPrompt(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('platinum')) return 'platinum';
    if (lower.contains('silver') || lower.contains('sterling')) return 'silver';
    if (lower.contains('rose gold') || lower.contains('rosegold')) return 'rose_gold';
    if (lower.contains('white gold') || lower.contains('whitegold')) return 'white_gold';
    if (lower.contains('22k') || lower.contains('22 karat') || lower.contains('22-karat')) return 'gold_22k';
    if (lower.contains('14k') || lower.contains('14 karat') || lower.contains('14-karat')) return 'gold_14k';
    if (lower.contains('gold') || lower.contains('18k') || lower.contains('18 karat')) return 'gold_18k';

    return null;
  }

  /// Handle order now from conversation
  void _handleOrderNow(ConversationMessage message, PriceEstimate? priceEstimate) {
    // Get current user info if available
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    final nameController = TextEditingController(text: user?.name ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
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

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ThyneTheme.primaryGold.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.sparkles, color: ThyneTheme.primaryGold),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Jewelry Order',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Our team will contact you to finalize',
                            style: TextStyle(fontSize: 12, color: ThyneTheme.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price estimate
                        if (priceEstimate != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.tag, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Estimated Price',
                                        style: TextStyle(fontSize: 12, color: Colors.green),
                                      ),
                                      Text(
                                        priceEstimate.priceRange,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Design prompt (read-only)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Design Description',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.text,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Contact Information
                        const Text(
                          'Contact Information',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Name
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: const Icon(CupertinoIcons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number *',
                            prefixIcon: const Icon(CupertinoIcons.phone),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            hintText: '+91 XXXXX XXXXX',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Phone is required';
                            if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
                              return 'Enter valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email (optional)
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email (Optional)',
                            prefixIcon: const Icon(CupertinoIcons.mail),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Additional notes
                        TextFormField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Additional Notes (Optional)',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 50),
                              child: Icon(CupertinoIcons.text_bubble),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            hintText: 'Any specific requirements...',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Info text
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ThyneTheme.createBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ThyneTheme.createBlue.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.info_circle, size: 20, color: ThyneTheme.createBlue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Our team will contact you within 24 hours to discuss design details and confirm the final price.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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

              // Submit button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: ThyneTheme.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            setSheetState(() => isSubmitting = true);

                            try {
                              final result = await ApiService.submitCustomOrder(
                                prompt: message.text,
                                imageUrl: message.imageUrl,
                                imageDescription: message.imageDescription,
                                estimatedMinPrice: priceEstimate?.minPrice,
                                estimatedMaxPrice: priceEstimate?.maxPrice,
                                conversationId: Provider.of<AIProvider>(context, listen: false)
                                    .currentConversation
                                    ?.id,
                                customerName: nameController.text.trim(),
                                customerPhone: phoneController.text.trim(),
                                customerEmail: emailController.text.trim().isEmpty
                                    ? null
                                    : emailController.text.trim(),
                                customerNotes: notesController.text.trim().isEmpty
                                    ? null
                                    : notesController.text.trim(),
                              );

                              if (context.mounted) {
                                Navigator.pop(context);

                                if (result['success'] == true) {
                                  _showOrderSuccessDialog();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['error'] ?? 'Failed to submit order'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                setSheetState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThyneTheme.primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Custom Order',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show order success dialog
  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.checkmark_circle, size: 48, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order Submitted!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Our team will contact you within 24 hours to discuss your custom jewelry design and finalize the pricing.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThyneTheme.primaryGold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle order from creation detail
  void _handleOrderFromCreation(AICreation creation) {
    _handleOrderNow(
      ConversationMessage(
        id: creation.id,
        text: creation.prompt,
        isUser: false,
        timestamp: creation.createdAt,
        imageUrl: creation.imageUrl,
        type: MessageType.image,
      ),
      null,
    );
  }

  /// Show token limit dialog
  void _showTokenLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.red),
            const SizedBox(width: 12),
            const Text('Monthly Limit Reached'),
          ],
        ),
        content: Consumer<AIProvider>(
          builder: (context, aiProvider, _) {
            final tokenUsage = aiProvider.tokenUsage;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('You\'ve reached your monthly AI generation limit.'),
                if (tokenUsage != null) ...[
                  const SizedBox(height: 12),
                  Text('Used: ${tokenUsage.tokensUsedFormatted} / ${tokenUsage.tokenLimitFormatted}'),
                  Text('Resets: ${tokenUsage.resetDate}'),
                ],
              ],
            );
          },
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return 'Just now';
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}

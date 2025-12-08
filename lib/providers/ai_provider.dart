import 'package:flutter/material.dart';
import '../models/ai_creation.dart';
import '../models/product.dart';
import '../models/conversation.dart';
import '../services/image_generation_service.dart';
import '../services/ai_chat_service.dart';
import '../services/api_service.dart';
import '../utils/storage_service_web.dart';
import '../utils/prompt_validator.dart';

/// Unified AI result that can contain either text/products or image
class UnifiedAIResult {
  final AIIntentType intent;
  final double textConfidence;
  final double imageConfidence;
  final String? reason;

  // Text results (product search)
  final List<Product>? products;
  final String? textResponse;

  // Image generation result
  final String? imageUrl;
  final String? imageDescription;
  final bool isProfileView;

  // Common
  final bool isSuccessful;
  final String? errorMessage;

  UnifiedAIResult({
    required this.intent,
    required this.textConfidence,
    required this.imageConfidence,
    this.reason,
    this.products,
    this.textResponse,
    this.imageUrl,
    this.imageDescription,
    this.isProfileView = true,
    this.isSuccessful = true,
    this.errorMessage,
  });

  bool get hasProducts => products != null && products!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isTextResult => intent == AIIntentType.text;
  bool get isImageResult => intent == AIIntentType.image;
}

class AIProvider extends ChangeNotifier {
  final ImageGenerationService _imageService = ImageGenerationService();
  final AIChatService _chatService = AIChatService();
  final dynamic _storage = StorageServiceWeb();

  // User state - when set, data syncs to backend
  String? _userId;
  String? _currentSessionId;

  // State variables
  List<AICreation> _creations = [];
  List<AICreation> _history = [];
  List<String> _recentSearches = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _currentGeneratingPrompt;

  // Unified results for merged tab
  List<UnifiedAIResult> _unifiedResults = [];
  UnifiedAIResult? _lastResult;

  // Token tracking
  TokenUsage? _tokenUsage;
  bool _isLoadingTokens = false;

  // Price estimation
  PriceEstimate? _lastPriceEstimate;

  // Chat-related state
  List<ChatMessage> _chatMessages = [];
  bool _isChatLoading = false;
  List<Product> _recommendedProducts = [];

  // Conversation management
  Conversation? _currentConversation;
  List<Conversation> _conversations = [];
  bool _isConversationsLoaded = false;

  // Check if user is logged in
  bool get isLoggedIn => _userId != null;

  // Getters
  // NOTE: Removed isSuccessful filter - was causing items to not show
  // History shows items fine, but creations was empty due to this filter
  List<AICreation> get creations => List<AICreation>.from(_creations);
  List<AICreation> get history => _history;
  List<String> get recentSearches => _recentSearches;
  List<String> get suggestions => _suggestions;
  List<ChatMessage> get chatMessages => _chatMessages;
  bool get isLoading => _isLoading;
  bool get isChatLoading => _isChatLoading;
  List<Product> get recommendedProducts => _recommendedProducts;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String? get currentGeneratingPrompt => _currentGeneratingPrompt;

  // Library getters (renamed from My Creations)
  List<AICreation> get library => _creations.where((c) => c.isSuccessful && c.imageUrl.isNotEmpty).toList();

  // Unified results getters
  List<UnifiedAIResult> get unifiedResults => _unifiedResults;
  UnifiedAIResult? get lastResult => _lastResult;

  // Token tracking getters
  TokenUsage? get tokenUsage => _tokenUsage;
  bool get isLoadingTokens => _isLoadingTokens;
  bool get canGenerate => _tokenUsage?.canGenerate ?? true;

  // Price estimation getters
  PriceEstimate? get lastPriceEstimate => _lastPriceEstimate;

  // Conversation getters
  Conversation? get currentConversation => _currentConversation;
  List<Conversation> get conversations => _conversations;
  bool get hasActiveConversation => _currentConversation != null;
  List<ConversationMessage> get currentMessages => _currentConversation?.messages ?? [];

  // Statistics
  int get totalCreations => _creations.length;
  int get successfulCreations => _creations.where((c) => c.isSuccessful).length;

  AIProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      print('🚀 AI: Initializing AIProvider...');

      // First, clean up any duplicate entries in storage
      await _storage.deduplicateCreations();

      // Load initial data from database
      await loadCreations();
      await loadRecentSearches();
      await loadSuggestions();

      _isInitialized = true;
      print('✅ AI: Initialization complete. Creations: ${_creations.length}, Successful: ${_creations.where((c) => c.isSuccessful).length}');
      notifyListeners();
    } catch (e) {
      print('❌ AI: Error initializing AI Provider: $e');
      _errorMessage = 'Failed to initialize AI service';
      notifyListeners();
    }
  }

  /// Generates a jewelry image from user prompt using Gemini 2.5 Flash Image API
  Future<bool> generateJewelryImage(String prompt) async {
    // Prevent double submission
    if (_isLoading) {
      print('⚠️ AI: Already generating, ignoring duplicate request');
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      _currentGeneratingPrompt = prompt;
      notifyListeners();

      // Validate prompt first
      final validation = PromptValidator.validatePrompt(prompt);
      if (!validation.isValid) {
        _errorMessage = validation.message;
        _isLoading = false;
        _currentGeneratingPrompt = null;
        notifyListeners();
        _showValidationDialog(validation.message!);
        return false;
      }

      // Add to search history
      await _storage.addSearchHistory(prompt);

      print('🚀 AI: Starting image generation with Gemini 2.5 Flash Image...');

      // Generate image directly using Gemini 2.5 Flash Image API
      // This handles both image generation AND text description
      final imageResult = await _imageService.generateJewelryImage(prompt);

      if (imageResult.success && imageResult.hasImage) {
        // Get the image URL (base64 data URL)
        final imageUrl = imageResult.imageUrl ??
                        'data:${imageResult.mimeType ?? 'image/png'};base64,${imageResult.base64Image ?? ''}';

        print('🖼️ AI: Image generated successfully!');
        print('🖼️ AI: Image URL length: ${imageUrl.length} chars');

        // Create AICreation object with all metadata
        final creation = AICreation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          prompt: prompt,
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
          isSuccessful: true,
          metadata: {
            'aiDescription': imageResult.aiDescription,
            'enhancedPrompt': imageResult.enhancedPrompt,
            'mimeType': imageResult.mimeType,
            'generatedBy': 'gemini-2.5-flash-image',
          },
        );

        // Save to database (local storage + backend if logged in)
        await _storage.insertCreation(creation);
        await _saveCreationToBackend(creation);
        print('✅ AI: Saved creation to storage, id: ${creation.id}');

        // Add to local list (insert at beginning for newest first)
        _creations.insert(0, creation);
        _history.insert(0, creation);
        print('✅ AI: Added to in-memory list, total creations: ${_creations.length}');

        // Add chat messages for conversation history
        _addChatMessage(prompt, true);
        if (imageResult.aiDescription != null && imageResult.aiDescription!.isNotEmpty) {
          _addChatMessage(
            'Here\'s your jewelry design: ${imageResult.aiDescription}',
            false,
          );
        }

        _isLoading = false;
        _currentGeneratingPrompt = null;
        notifyListeners();
        return true;
      } else {
        // Save failed attempt to history
        final failedCreation = AICreation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          prompt: prompt,
          imageUrl: '',
          createdAt: DateTime.now(),
          isSuccessful: false,
          errorMessage: imageResult.errorMessage ?? 'Image generation failed',
        );

        await _storage.insertCreation(failedCreation);
        _history.insert(0, failedCreation);

        _errorMessage = imageResult.errorMessage ?? 'Failed to generate image';
        _isLoading = false;
        _currentGeneratingPrompt = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ AI: Error generating jewelry image: $e');
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      _currentGeneratingPrompt = null;
      notifyListeners();
      return false;
    }
  }

  /// Unified processing: Analyzes intent and routes to text search or image generation
  /// This is the main entry point for the merged results tab
  Future<UnifiedAIResult?> processUnifiedRequest(String prompt) async {
    if (_isLoading) {
      print('⚠️ AI: Already processing, ignoring duplicate request');
      return null;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      _currentGeneratingPrompt = prompt;
      notifyListeners();

      // Validate prompt first
      final validation = PromptValidator.validatePrompt(prompt);
      if (!validation.isValid) {
        _errorMessage = validation.message;
        _isLoading = false;
        _currentGeneratingPrompt = null;
        notifyListeners();
        return UnifiedAIResult(
          intent: AIIntentType.text,
          textConfidence: 0,
          imageConfidence: 0,
          isSuccessful: false,
          errorMessage: validation.message,
        );
      }

      // Step 1: Analyze intent using backend API
      print('🔍 AI: Analyzing intent for prompt: $prompt');
      IntentAnalysisResult? intentResult;

      try {
        final intentResponse = await ApiService.analyzeAIIntent(prompt);
        if (intentResponse['success'] == true && intentResponse['data'] != null) {
          intentResult = IntentAnalysisResult.fromJson(intentResponse['data']);
          print('🎯 AI: Intent: ${intentResult.intent.name}, Text: ${intentResult.textConfidence.toStringAsFixed(1)}%, Image: ${intentResult.imageConfidence.toStringAsFixed(1)}%');
        }
      } catch (e) {
        print('⚠️ AI: Intent analysis failed, defaulting to image: $e');
        // Default to image generation if intent analysis fails
      }

      // Step 2: Route based on intent
      if (intentResult != null && intentResult.isTextIntent) {
        // Text intent - search for products
        print('📝 AI: Routing to text/product search');
        return await _processTextIntent(prompt, intentResult);
      } else {
        // Image intent - generate image (default)
        print('🖼️ AI: Routing to image generation');
        return await _processImageIntent(prompt, intentResult);
      }
    } catch (e) {
      print('❌ AI: Error in unified processing: $e');
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      _currentGeneratingPrompt = null;
      notifyListeners();
      return UnifiedAIResult(
        intent: AIIntentType.text,
        textConfidence: 0,
        imageConfidence: 0,
        isSuccessful: false,
        errorMessage: _errorMessage,
      );
    }
  }

  /// Process text intent - search for products
  Future<UnifiedAIResult> _processTextIntent(String prompt, IntentAnalysisResult? intent) async {
    try {
      // Use chat service to get product recommendations
      final response = await _chatService.chat(prompt);

      final result = UnifiedAIResult(
        intent: AIIntentType.text,
        textConfidence: intent?.textConfidence ?? 60,
        imageConfidence: intent?.imageConfidence ?? 40,
        reason: intent?.reason ?? 'Text search based on prompt',
        products: response.products,
        textResponse: response.message,
        isSuccessful: true,
      );

      // Add to chat history
      _addChatMessage(prompt, true);
      _addChatMessage(response.message, false, products: response.products);

      // Update unified results
      _unifiedResults.insert(0, result);
      _lastResult = result;

      // Save search history
      await _storage.addSearchHistory(prompt);

      _isLoading = false;
      _currentGeneratingPrompt = null;
      notifyListeners();
      return result;
    } catch (e) {
      print('❌ AI: Text processing error: $e');
      _isLoading = false;
      _currentGeneratingPrompt = null;
      notifyListeners();
      return UnifiedAIResult(
        intent: AIIntentType.text,
        textConfidence: 60,
        imageConfidence: 40,
        isSuccessful: false,
        errorMessage: 'Failed to search products: $e',
      );
    }
  }

  /// Process image intent - generate jewelry image
  Future<UnifiedAIResult> _processImageIntent(String prompt, IntentAnalysisResult? intent) async {
    try {
      // Add to search history
      await _storage.addSearchHistory(prompt);

      print('🚀 AI: Starting image generation with Gemini 2.5 Flash Image...');

      // Generate image (already enforces profile view in the service)
      final imageResult = await _imageService.generateJewelryImage(prompt);

      if (imageResult.success && imageResult.hasImage) {
        final imageUrl = imageResult.imageUrl ??
            'data:${imageResult.mimeType ?? 'image/png'};base64,${imageResult.base64Image ?? ''}';

        print('🖼️ AI: Image generated successfully!');

        // Create AICreation with profile view metadata
        final creation = AICreation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          prompt: prompt,
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
          isSuccessful: true,
          intentType: AIIntentType.image,
          viewType: ImageViewType.profile,
          isProfileView: true,
          textConfidence: intent?.textConfidence,
          imageConfidence: intent?.imageConfidence,
          metadata: {
            'aiDescription': imageResult.aiDescription,
            'enhancedPrompt': imageResult.enhancedPrompt,
            'mimeType': imageResult.mimeType,
            'generatedBy': 'gemini-2.5-flash-image',
            'viewType': 'profile',
            'isProfileView': true,
          },
        );

        // Save to library
        await _storage.insertCreation(creation);
        await _saveCreationToBackend(creation);
        _creations.insert(0, creation);
        _history.insert(0, creation);

        // Create unified result
        final result = UnifiedAIResult(
          intent: AIIntentType.image,
          textConfidence: intent?.textConfidence ?? 40,
          imageConfidence: intent?.imageConfidence ?? 60,
          reason: intent?.reason ?? 'Image generated based on creative prompt',
          imageUrl: imageUrl,
          imageDescription: imageResult.aiDescription,
          isProfileView: true,
          isSuccessful: true,
        );

        // Add to chat history
        _addChatMessage(prompt, true);
        if (imageResult.aiDescription != null && imageResult.aiDescription!.isNotEmpty) {
          _addChatMessage(
            'Here\'s your jewelry design (profile view for CAD): ${imageResult.aiDescription}',
            false,
          );
        }

        // Update unified results
        _unifiedResults.insert(0, result);
        _lastResult = result;

        _isLoading = false;
        _currentGeneratingPrompt = null;
        notifyListeners();
        return result;
      } else {
        // Failed to generate image
        final failedCreation = AICreation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          prompt: prompt,
          imageUrl: '',
          createdAt: DateTime.now(),
          isSuccessful: false,
          errorMessage: imageResult.errorMessage ?? 'Image generation failed',
        );

        await _storage.insertCreation(failedCreation);
        _history.insert(0, failedCreation);

        _isLoading = false;
        _currentGeneratingPrompt = null;
        notifyListeners();

        return UnifiedAIResult(
          intent: AIIntentType.image,
          textConfidence: intent?.textConfidence ?? 40,
          imageConfidence: intent?.imageConfidence ?? 60,
          isSuccessful: false,
          errorMessage: imageResult.errorMessage ?? 'Failed to generate image',
        );
      }
    } catch (e) {
      print('❌ AI: Image processing error: $e');
      _isLoading = false;
      _currentGeneratingPrompt = null;
      notifyListeners();
      return UnifiedAIResult(
        intent: AIIntentType.image,
        textConfidence: 40,
        imageConfidence: 60,
        isSuccessful: false,
        errorMessage: 'Failed to generate image: $e',
      );
    }
  }

  // ==================== Token Tracking ====================

  /// Load current token usage from backend
  Future<void> loadTokenUsage() async {
    if (!isLoggedIn) return;

    try {
      _isLoadingTokens = true;
      notifyListeners();

      final response = await ApiService.getTokenUsage();
      if (response['success'] == true && response['data'] != null) {
        _tokenUsage = TokenUsage.fromJson(response['data']);
        print('📊 AI: Token usage loaded - ${_tokenUsage!.tokensUsedFormatted}/${_tokenUsage!.tokenLimitFormatted}');
      }
    } catch (e) {
      print('⚠️ AI: Failed to load token usage: $e');
    } finally {
      _isLoadingTokens = false;
      notifyListeners();
    }
  }

  /// Check if user can generate (based on token limits)
  Future<bool> checkCanGenerateImage() async {
    if (!isLoggedIn) return true; // Allow for non-logged-in users

    try {
      final response = await ApiService.checkCanGenerate();
      if (response['success'] == true) {
        final canGen = response['canGenerate'] ?? true;
        if (!canGen) {
          _errorMessage = response['message'] ?? 'Monthly token limit reached';
        }
        return canGen;
      }
    } catch (e) {
      print('⚠️ AI: Failed to check generation limit: $e');
    }
    return true; // Default to allowing if check fails
  }

  // ==================== Price Estimation ====================

  /// Estimate price for a prompt
  Future<PriceEstimate?> estimatePrice(String prompt, {String? jewelryType, String? metalType}) async {
    try {
      final response = await ApiService.estimateAIPrice(
        prompt: prompt,
        jewelryType: jewelryType,
        metalType: metalType,
      );

      if (response['success'] == true && response['data'] != null) {
        _lastPriceEstimate = PriceEstimate.fromJson(response['data']);
        notifyListeners();
        return _lastPriceEstimate;
      }
    } catch (e) {
      print('⚠️ AI: Failed to estimate price: $e');
    }
    return null;
  }

  // ==================== Creations ====================

  /// Loads creations from database
  Future<void> loadCreations() async {
    try {
      print('🔄 AI: Loading creations from storage...');
      final allCreations = await _storage.getAllCreations();
      print('📦 AI: Loaded ${allCreations.length} creations from storage');

      // Debug: print each creation's isSuccessful status
      for (var i = 0; i < allCreations.length && i < 5; i++) {
        final c = allCreations[i];
        final promptPreview = c.prompt.length > 30 ? c.prompt.substring(0, 30) : c.prompt;
        print('   📋 Creation $i: id=${c.id}, isSuccessful=${c.isSuccessful}, hasImage=${c.imageUrl.isNotEmpty}, prompt="$promptPreview..."');
      }

      // Count successful items
      final successfulCount = allCreations.where((c) => c.isSuccessful).length;
      print('📊 AI: Total: ${allCreations.length}, Successful: $successfulCount, Failed: ${allCreations.length - successfulCount}');

      // Only replace if storage has data OR memory is empty
      // This prevents clearing in-memory data when storage fails on web
      if (allCreations.isNotEmpty || _creations.isEmpty) {
        // Create separate list copies to avoid reference issues
        _creations = List<AICreation>.from(allCreations);
        _history = List<AICreation>.from(allCreations);
        print('✅ AI: Updated in-memory list with ${allCreations.length} creations');
        print('✅ AI: Creations getter will return: ${creations.length} items');
      } else {
        print('⚠️ AI: Storage returned empty but memory has ${_creations.length} items - keeping memory data');
      }

      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ AI: Error loading creations: $e');
      print('   Stack trace: $stackTrace');
      // Don't clear existing data on error
    }
  }

  /// Loads recent searches from database
  Future<void> loadRecentSearches() async {
    try {
      _recentSearches = await _storage.getRecentSearches();
      notifyListeners();
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  /// Loads design suggestions
  Future<void> loadSuggestions({String? category}) async {
    // Use predefined jewelry design suggestions
    _suggestions = PromptValidator.getPromptSuggestions(category: category);
    notifyListeners();
  }

  /// Deletes a creation
  Future<void> deleteCreation(String id) async {
    try {
      await _storage.deleteCreation(id);
      _creations.removeWhere((c) => c.id == id);
      _history.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting creation: $e');
      _errorMessage = 'Failed to delete creation';
      notifyListeners();
    }
  }

  /// Clears all creations
  Future<void> clearAllCreations() async {
    try {
      await _storage.clearAllCreations();
      _creations.clear();
      _history.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing creations: $e');
    }
  }

  /// Clears search history
  Future<void> clearSearchHistory() async {
    try {
      await _storage.clearSearchHistory();
      _recentSearches.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }

  /// Adds a chat message
  void _addChatMessage(String message, bool isUser, {List<Product>? products}) {
    _chatMessages.add(ChatMessage(
      text: message,
      isUser: isUser,
      timestamp: DateTime.now(),
      products: products,
    ));

    // Save to database (local storage + backend if logged in)
    _storage.addChatMessage(message: message, isUser: isUser);
    _saveChatMessageToBackend(message, isUser, products: products);
    notifyListeners();
  }

  /// Send a chat message and get AI response
  Future<void> sendChatMessage(String message) async {
    if (message.trim().isEmpty || _isChatLoading) return;

    try {
      // Add user message
      _addChatMessage(message, true);

      _isChatLoading = true;
      _recommendedProducts = [];
      notifyListeners();

      // Get AI response
      final response = await _chatService.chat(message);

      // Add AI response with products if any
      _addChatMessage(response.message, false, products: response.products);

      if (response.hasProducts) {
        _recommendedProducts = response.products;
      }

      _isChatLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Chat error: $e');
      _addChatMessage(
        'Sorry, I encountered an error. Please try again.',
        false,
      );
      _isChatLoading = false;
      notifyListeners();
    }
  }

  /// Clear chat history
  Future<void> clearChat() async {
    _chatMessages.clear();
    _recommendedProducts = [];
    await _storage.clearChatHistory();
    notifyListeners();
  }

  /// Load chat history from storage
  Future<void> loadChatHistory() async {
    try {
      final history = await _storage.getChatHistory();
      _chatMessages = history.map((msg) => ChatMessage(
        text: msg['message'] as String,
        isUser: msg['isUser'] == 1,
        timestamp: DateTime.parse(msg['timestamp'] as String),
      )).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  /// Clears error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Shows validation dialog (to be called from UI)
  void _showValidationDialog(String message) {
    // This will be handled in the UI layer
    // The UI will check for error messages and show appropriate dialogs
  }

  /// Gets statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await _storage.getStatistics();
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'totalCreations': 0,
        'successfulCreations': 0,
        'failedCreations': 0,
        'totalSearches': 0,
        'successRate': '0.0',
      };
    }
  }

  /// Sets the user ID for syncing data to backend
  /// Call this when user logs in
  Future<void> setUser(String? userId) async {
    final wasLoggedIn = _userId != null;
    _userId = userId;

    if (userId != null) {
      print('🔐 AI: User logged in, loading data from backend...');
      // Reload data from backend when user logs in
      await loadCreationsFromBackend();
      await loadChatHistoryFromBackend();
    } else if (wasLoggedIn) {
      print('🔓 AI: User logged out, clearing data...');
      // Clear data when user logs out
      _creations.clear();
      _history.clear();
      _chatMessages.clear();
      _currentSessionId = null;
      notifyListeners();
    }
  }

  /// Loads creations from backend API
  Future<void> loadCreationsFromBackend() async {
    if (_userId == null) return;

    try {
      print('🔄 AI: Loading creations from backend...');
      final result = await ApiService.getAICreations(page: 1, limit: 50);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final creationsData = data['creations'] as List<dynamic>? ?? [];

        _creations = creationsData.map((json) {
          final jsonMap = json as Map<String, dynamic>;
          return AICreation(
            id: jsonMap['id'] ?? '',
            prompt: jsonMap['prompt'] ?? '',
            imageUrl: jsonMap['imageUrl'] ?? '',
            createdAt: DateTime.tryParse(jsonMap['createdAt'] ?? '') ?? DateTime.now(),
            isSuccessful: jsonMap['isSuccessful'] ?? false,
            errorMessage: jsonMap['errorMessage'],
            metadata: jsonMap['metadata'] as Map<String, dynamic>?,
          );
        }).toList();

        _history = List<AICreation>.from(_creations);
        print('✅ AI: Loaded ${_creations.length} creations from backend');
        notifyListeners();
      }
    } catch (e) {
      print('❌ AI: Error loading creations from backend: $e');
    }
  }

  /// Loads chat history from backend API
  Future<void> loadChatHistoryFromBackend() async {
    if (_userId == null) return;

    try {
      print('🔄 AI: Loading chat history from backend...');
      final result = await ApiService.getAIChatHistory(page: 1, limit: 100);

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final messagesData = data['messages'] as List<dynamic>? ?? [];

        _chatMessages = messagesData.map((json) {
          final jsonMap = json as Map<String, dynamic>;
          return ChatMessage(
            text: jsonMap['text'] ?? '',
            isUser: jsonMap['isUser'] ?? false,
            timestamp: DateTime.tryParse(jsonMap['createdAt'] ?? '') ?? DateTime.now(),
          );
        }).toList();

        print('✅ AI: Loaded ${_chatMessages.length} chat messages from backend');
        notifyListeners();
      }
    } catch (e) {
      print('❌ AI: Error loading chat history from backend: $e');
    }
  }

  /// Saves creation to backend if logged in
  Future<void> _saveCreationToBackend(AICreation creation) async {
    if (_userId == null) return;

    try {
      await ApiService.saveAICreation(
        prompt: creation.prompt,
        imageUrl: creation.imageUrl,
        isSuccessful: creation.isSuccessful,
        errorMessage: creation.errorMessage,
        metadata: creation.metadata,
      );
      print('✅ AI: Creation saved to backend');
    } catch (e) {
      print('❌ AI: Error saving creation to backend: $e');
    }
  }

  /// Saves chat message to backend if logged in
  Future<void> _saveChatMessageToBackend(String message, bool isUser, {List<Product>? products}) async {
    if (_userId == null) return;

    try {
      final productRefs = products?.map((p) => {
        'productId': p.id,
        'name': p.name,
        'price': p.price,
        'imageUrl': p.images.isNotEmpty ? p.images.first : '',
      }).toList();

      final result = await ApiService.sendAIChatMessage(
        sessionId: _currentSessionId,
        text: message,
        isUser: isUser,
        products: productRefs,
      );

      // Store session ID for continuation
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        _currentSessionId = data['sessionId'] as String?;
      }
    } catch (e) {
      print('❌ AI: Error saving chat message to backend: $e');
    }
  }

  // ==================== Conversation Management ====================

  /// Start a new conversation session
  Future<void> startNewConversation() async {
    print('🆕 AI: Starting new conversation...');

    // Save current conversation if it has messages
    if (_currentConversation != null && _currentConversation!.messageCount > 0) {
      await saveCurrentConversation();
    }

    // Create new conversation
    _currentConversation = Conversation.newConversation(userId: _userId);

    // Clear legacy chat messages
    _chatMessages.clear();
    _recommendedProducts = [];
    _lastResult = null;
    _unifiedResults.clear();

    print('✅ AI: New conversation started: ${_currentConversation!.id}');
    notifyListeners();
  }

  /// Resume an existing conversation
  Future<void> resumeConversation(String conversationId) async {
    print('🔄 AI: Resuming conversation: $conversationId');

    // Save current conversation first
    if (_currentConversation != null && _currentConversation!.id != conversationId) {
      await saveCurrentConversation();
    }

    // Find conversation
    final conversation = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => Conversation.newConversation(userId: _userId),
    );

    _currentConversation = conversation;

    // Clear unified results to show conversation messages
    _lastResult = null;
    _unifiedResults.clear();

    print('✅ AI: Resumed conversation with ${conversation.messages.length} messages');
    notifyListeners();
  }

  /// Add a user message to current conversation and get AI response
  Future<UnifiedAIResult?> sendConversationMessage(String message) async {
    if (message.trim().isEmpty) return null;

    // Ensure we have a conversation
    if (_currentConversation == null) {
      await startNewConversation();
    }

    // Add user message
    final userMessage = ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    _currentConversation = _currentConversation!.addMessage(userMessage);
    notifyListeners();

    // Process with unified request (image or text)
    final result = await processUnifiedRequest(message);

    if (result != null && result.isSuccessful) {
      // Add AI response message
      final aiMessage = ConversationMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        text: result.isImageResult
            ? result.imageDescription ?? 'Here\'s your jewelry design!'
            : result.textResponse ?? 'Here are some products for you.',
        isUser: false,
        timestamp: DateTime.now(),
        type: result.isImageResult ? MessageType.image : MessageType.products,
        imageUrl: result.imageUrl,
        imageDescription: result.imageDescription,
        products: result.products,
        priceEstimate: _lastPriceEstimate,
      );

      _currentConversation = _currentConversation!.addMessage(aiMessage);

      // Auto-save conversation
      await saveCurrentConversation();
    }

    notifyListeners();
    return result;
  }

  /// Save current conversation to storage
  Future<void> saveCurrentConversation() async {
    if (_currentConversation == null) return;

    try {
      // Update in list
      final existingIndex = _conversations.indexWhere(
        (c) => c.id == _currentConversation!.id,
      );

      if (existingIndex >= 0) {
        _conversations[existingIndex] = _currentConversation!;
      } else {
        _conversations.insert(0, _currentConversation!);
      }

      // Save to storage
      await _storage.saveConversation(_currentConversation!.toJson());

      // Save to backend if logged in
      if (_userId != null) {
        await _saveConversationToBackend(_currentConversation!);
      }

      print('✅ AI: Conversation saved: ${_currentConversation!.id}');
    } catch (e) {
      print('❌ AI: Error saving conversation: $e');
    }
  }

  /// Load all conversations from storage
  Future<void> loadConversations() async {
    if (_isConversationsLoaded) return;

    try {
      print('🔄 AI: Loading conversations from storage...');

      final conversationsJson = await _storage.getAllConversations();
      _conversations = conversationsJson
          .map<Conversation>((json) => Conversation.fromJson(json))
          .toList();

      // Sort by updatedAt (newest first)
      _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      _isConversationsLoaded = true;
      print('✅ AI: Loaded ${_conversations.length} conversations');
      notifyListeners();
    } catch (e) {
      print('❌ AI: Error loading conversations: $e');
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      _conversations.removeWhere((c) => c.id == conversationId);

      // If deleting current conversation, clear it
      if (_currentConversation?.id == conversationId) {
        _currentConversation = null;
      }

      await _storage.deleteConversation(conversationId);
      print('✅ AI: Conversation deleted: $conversationId');
      notifyListeners();
    } catch (e) {
      print('❌ AI: Error deleting conversation: $e');
    }
  }

  /// Archive a conversation
  Future<void> archiveConversation(String conversationId) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index >= 0) {
      _conversations[index] = _conversations[index].copyWith(
        status: ConversationStatus.archived,
      );
      await _storage.saveConversation(_conversations[index].toJson());
      notifyListeners();
    }
  }

  /// Get active conversations (not archived)
  List<Conversation> get activeConversations =>
      _conversations.where((c) => c.status != ConversationStatus.archived).toList();

  /// Get archived conversations
  List<Conversation> get archivedConversations =>
      _conversations.where((c) => c.status == ConversationStatus.archived).toList();

  /// Save conversation to backend
  Future<void> _saveConversationToBackend(Conversation conversation) async {
    if (_userId == null) return;

    try {
      // Use existing chat message API to sync conversation
      for (final message in conversation.messages) {
        if (message.type != MessageType.system) {
          await _saveChatMessageToBackend(
            message.text,
            message.isUser,
            products: message.products,
          );
        }
      }
    } catch (e) {
      print('❌ AI: Error saving conversation to backend: $e');
    }
  }

  @override
  void dispose() {
    // Storage close is optional for web
    _storage?.close();
    super.dispose();
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Product>? products;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.products,
  });

  bool get hasProducts => products != null && products!.isNotEmpty;
}
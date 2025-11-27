import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/ai_creation.dart';
import '../services/gemini_service.dart';
import '../services/image_generation_service.dart';
import '../utils/storage_service_web.dart';
import '../utils/prompt_validator.dart';

class AIProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final ImageGenerationService _imageService = ImageGenerationService();
  final dynamic _storage = StorageServiceWeb();

  // State variables
  List<AICreation> _creations = [];
  List<AICreation> _history = [];
  List<String> _recentSearches = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _currentGeneratingPrompt;

  // Chat-related state
  List<ChatMessage> _chatMessages = [];

  // Getters
  List<AICreation> get creations => _creations.where((c) => c.isSuccessful).toList();
  List<AICreation> get history => _history;
  List<String> get recentSearches => _recentSearches;
  List<String> get suggestions => _suggestions;
  List<ChatMessage> get chatMessages => _chatMessages;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String? get currentGeneratingPrompt => _currentGeneratingPrompt;

  // Statistics
  int get totalCreations => _creations.length;
  int get successfulCreations => _creations.where((c) => c.isSuccessful).length;

  AIProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Load initial data from database
      await loadCreations();
      await loadRecentSearches();
      await loadSuggestions();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing AI Provider: $e');
      _errorMessage = 'Failed to initialize AI service';
      notifyListeners();
    }
  }

  /// Generates a jewelry image from user prompt
  Future<bool> generateJewelryImage(String prompt) async {
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
        notifyListeners();
        _showValidationDialog(validation.message!);
        return false;
      }

      // Add to search history
      await _storage.addSearchHistory(prompt);

      // First, get design description from Gemini
      final geminiResult = await _geminiService.generateJewelryDesign(prompt);

      if (!geminiResult.success) {
        _errorMessage = geminiResult.errorMessage;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Generate image using the image service
      // Using placeholder for now as Hugging Face requires token
      final imageResult = await _imageService.generatePlaceholderImage(prompt);

      if (imageResult.success) {
        // Create AICreation object
        final creation = AICreation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          prompt: prompt,
          imageUrl: imageResult.imageUrl ??
                   'data:image/jpeg;base64,${imageResult.base64Image ?? ''}',
          createdAt: DateTime.now(),
          isSuccessful: true,
          metadata: {
            'designDescription': geminiResult.designDescription,
            'enhancedPrompt': geminiResult.enhancedPrompt,
          },
        );

        // Save to database
        await _storage.insertCreation(creation);

        // Add to local list
        _creations.insert(0, creation);
        _history.insert(0, creation);

        // Add chat messages
        _addChatMessage(prompt, true);
        if (geminiResult.designDescription != null) {
          _addChatMessage(
            'Here\'s your jewelry design: ${geminiResult.designDescription}',
            false,
          );
        }

        _isLoading = false;
        _currentGeneratingPrompt = null;
        notifyListeners();
        return true;
      } else {
        // Save failed attempt
        final failedCreation = AICreation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          prompt: prompt,
          imageUrl: '',
          createdAt: DateTime.now(),
          isSuccessful: false,
          errorMessage: imageResult.errorMessage,
        );

        await _storage.insertCreation(failedCreation);
        _history.insert(0, failedCreation);

        _errorMessage = imageResult.errorMessage;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error generating jewelry image: $e');
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _isLoading = false;
      _currentGeneratingPrompt = null;
      notifyListeners();
      return false;
    }
  }

  /// Loads creations from database
  Future<void> loadCreations() async {
    try {
      final allCreations = await _storage.getAllCreations();
      _creations = allCreations;
      _history = allCreations;
      notifyListeners();
    } catch (e) {
      print('Error loading creations: $e');
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

  /// Loads AI suggestions
  Future<void> loadSuggestions({String? category}) async {
    try {
      // Try to get AI-generated suggestions
      final aiSuggestions = await _geminiService.getDesignSuggestions(
        occasion: category,
      );

      _suggestions = aiSuggestions;

      // If AI suggestions fail, use default ones
      if (_suggestions.isEmpty) {
        _suggestions = PromptValidator.getPromptSuggestions(category: category);
      }

      notifyListeners();
    } catch (e) {
      print('Error loading suggestions: $e');
      // Fallback to default suggestions
      _suggestions = PromptValidator.getPromptSuggestions(category: category);
      notifyListeners();
    }
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
  void _addChatMessage(String message, bool isUser) {
    _chatMessages.add(ChatMessage(
      text: message,
      isUser: isUser,
      timestamp: DateTime.now(),
    ));

    // Save to database
    _storage.addChatMessage(message: message, isUser: isUser);
    notifyListeners();
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

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
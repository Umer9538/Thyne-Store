class SearchUtils {
  // Levenshtein distance algorithm for spell tolerance
  static int levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  // Check if two strings are similar within a threshold
  static bool isSimilar(String word1, String word2, {double threshold = 0.7}) {
    if (word1.isEmpty || word2.isEmpty) return false;

    word1 = word1.toLowerCase();
    word2 = word2.toLowerCase();

    if (word1 == word2) return true;

    int distance = levenshteinDistance(word1, word2);
    int maxLength = word1.length > word2.length ? word1.length : word2.length;

    double similarity = 1.0 - (distance / maxLength);
    return similarity >= threshold;
  }

  // Get search suggestions with fuzzy matching
  static List<String> getSearchSuggestions(
    String query,
    List<String> suggestions, {
    int maxSuggestions = 5,
    double fuzzyThreshold = 0.6,
  }) {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final List<MapEntry<String, double>> scoredSuggestions = [];

    for (String suggestion in suggestions) {
      final suggestionLower = suggestion.toLowerCase();
      double score = 0.0;

      // Exact match gets highest score
      if (suggestionLower == queryLower) {
        score = 1.0;
      }
      // Starts with query gets high score
      else if (suggestionLower.startsWith(queryLower)) {
        score = 0.9;
      }
      // Contains query gets medium score
      else if (suggestionLower.contains(queryLower)) {
        score = 0.7;
      }
      // Fuzzy match gets lower score
      else if (isSimilar(query, suggestion, threshold: fuzzyThreshold)) {
        int distance = levenshteinDistance(queryLower, suggestionLower);
        int maxLength = queryLower.length > suggestionLower.length
            ? queryLower.length : suggestionLower.length;
        score = 1.0 - (distance / maxLength);
      }

      if (score > 0) {
        scoredSuggestions.add(MapEntry(suggestion, score));
      }
    }

    // Sort by score descending
    scoredSuggestions.sort((a, b) => b.value.compareTo(a.value));

    return scoredSuggestions
        .take(maxSuggestions)
        .map((entry) => entry.key)
        .toList();
  }

  // Generate search terms from products for autocomplete
  static List<String> generateSearchTerms(List<dynamic> products) {
    final Set<String> terms = {};

    for (var product in products) {
      // Add product name
      terms.add(product.name);

      // Add category and subcategory
      terms.add(product.category);
      terms.add(product.subcategory);

      // Add metal type
      terms.add(product.metalType);

      // Add stone type if available
      if (product.stoneType != null) {
        terms.add(product.stoneType!);
      }

      // Add tags
      terms.addAll(product.tags);

      // Add individual words from product name
      final nameWords = product.name.toLowerCase().split(' ');
      for (String word in nameWords) {
        if (word.length > 2) { // Only add words longer than 2 characters
          terms.add(word.toLowerCase());
        }
      }
    }

    return terms.toList()..sort();
  }

  // Common jewelry search terms for fallback suggestions
  static const List<String> commonJewelryTerms = [
    'rings',
    'necklaces',
    'earrings',
    'bracelets',
    'pendants',
    'chains',
    'diamonds',
    'gold',
    'silver',
    'platinum',
    'rose gold',
    'white gold',
    'emerald',
    'ruby',
    'sapphire',
    'pearl',
    'engagement',
    'wedding',
    'anniversary',
    'gift',
    'luxury',
    'elegant',
    'classic',
    'modern',
    'vintage',
    'statement',
    'delicate',
    'bold',
    'sparkle',
    'shine',
  ];
}
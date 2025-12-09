/// Style options for jewelry products
/// These are used for "Shop By Style" filtering and product tagging

class StyleOption {
  final String name;
  final String slug;
  final String? description;
  final String? icon;

  const StyleOption({
    required this.name,
    required this.slug,
    this.description,
    this.icon,
  });
}

/// Predefined style options for products
class ProductStyles {
  static const List<StyleOption> all = [
    StyleOption(
      name: 'Traditional',
      slug: 'traditional',
      description: 'Classic designs with cultural heritage',
    ),
    StyleOption(
      name: 'Contemporary',
      slug: 'contemporary',
      description: 'Modern designs with current trends',
    ),
    StyleOption(
      name: 'Minimalist',
      slug: 'minimalist',
      description: 'Simple, elegant, understated pieces',
    ),
    StyleOption(
      name: 'Statement',
      slug: 'statement',
      description: 'Bold, eye-catching pieces',
    ),
    StyleOption(
      name: 'Vintage',
      slug: 'vintage',
      description: 'Retro-inspired classic designs',
    ),
    StyleOption(
      name: 'Everyday',
      slug: 'everyday',
      description: 'Casual wear for daily use',
    ),
    StyleOption(
      name: 'Bridal',
      slug: 'bridal',
      description: 'Wedding and bridal collections',
    ),
    StyleOption(
      name: 'Festive',
      slug: 'festive',
      description: 'Perfect for celebrations and festivals',
    ),
  ];

  /// Get all style names
  static List<String> get names => all.map((s) => s.name).toList();

  /// Get all style slugs
  static List<String> get slugs => all.map((s) => s.slug).toList();

  /// Get style by slug
  static StyleOption? getBySlug(String slug) {
    try {
      return all.firstWhere((s) => s.slug == slug);
    } catch (_) {
      return null;
    }
  }

  /// Get style by name
  static StyleOption? getByName(String name) {
    try {
      return all.firstWhere((s) => s.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  /// Check if a tag is a style tag
  static bool isStyleTag(String tag) {
    return slugs.contains(tag.toLowerCase());
  }

  /// Extract style tags from a list of tags
  static List<String> extractStyleTags(List<String> tags) {
    return tags.where((tag) => isStyleTag(tag)).toList();
  }

  /// Get non-style tags from a list of tags
  static List<String> extractNonStyleTags(List<String> tags) {
    return tags.where((tag) => !isStyleTag(tag)).toList();
  }
}

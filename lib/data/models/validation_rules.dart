import 'store_settings.dart';
import 'product.dart';

/// Types of validation rules for product customization
enum ValidationRuleType {
  /// Metal requires specific plating options
  metalRequiresPlating,

  /// Metal excludes certain plating options
  metalExcludesPlating,

  /// Stone requires specific metal type
  stoneRequiresMetal,

  /// Quality tier requires specific stone type
  qualityRequiresStone,

  /// Stone shape requires specific metal
  shapeRequiresMetal,

  /// Diamond grading only available for diamonds
  gradingRequiresStoneType,

  /// Carat weight requires specific shape
  caratRequiresShape,

  /// Size availability depends on metal
  sizeRequiresMetal,
}

/// A validation rule for product customization
class ValidationRule {
  final String id;
  final ValidationRuleType type;
  final String? sourceMetal; // For metal-based rules
  final String? sourceStone; // For stone-based rules
  final String? sourceShape; // For shape-based rules
  final String? sourceQuality; // For quality-based rules
  final List<String>? requiredValues; // Values that must be selected
  final List<String>? excludedValues; // Values that cannot be selected
  final String errorMessage;
  final bool isActive;

  const ValidationRule({
    required this.id,
    required this.type,
    this.sourceMetal,
    this.sourceStone,
    this.sourceShape,
    this.sourceQuality,
    this.requiredValues,
    this.excludedValues,
    required this.errorMessage,
    this.isActive = true,
  });

  factory ValidationRule.fromJson(Map<String, dynamic> json) {
    return ValidationRule(
      id: json['id']?.toString() ?? '',
      type: ValidationRuleType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ValidationRuleType.metalRequiresPlating,
      ),
      sourceMetal: json['sourceMetal']?.toString(),
      sourceStone: json['sourceStone']?.toString(),
      sourceShape: json['sourceShape']?.toString(),
      sourceQuality: json['sourceQuality']?.toString(),
      requiredValues: json['requiredValues'] != null
          ? List<String>.from(json['requiredValues'])
          : null,
      excludedValues: json['excludedValues'] != null
          ? List<String>.from(json['excludedValues'])
          : null,
      errorMessage: json['errorMessage']?.toString() ?? 'Invalid selection',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      if (sourceMetal != null) 'sourceMetal': sourceMetal,
      if (sourceStone != null) 'sourceStone': sourceStone,
      if (sourceShape != null) 'sourceShape': sourceShape,
      if (sourceQuality != null) 'sourceQuality': sourceQuality,
      if (requiredValues != null) 'requiredValues': requiredValues,
      if (excludedValues != null) 'excludedValues': excludedValues,
      'errorMessage': errorMessage,
      'isActive': isActive,
    };
  }

  /// Check if this rule applies to the given customization state
  bool appliesTo({
    String? selectedMetal,
    String? selectedStone,
    String? selectedShape,
    String? selectedQuality,
  }) {
    if (!isActive) return false;

    switch (type) {
      case ValidationRuleType.metalRequiresPlating:
      case ValidationRuleType.metalExcludesPlating:
        return sourceMetal != null && selectedMetal == sourceMetal;

      case ValidationRuleType.stoneRequiresMetal:
        return sourceStone != null && selectedStone == sourceStone;

      case ValidationRuleType.qualityRequiresStone:
        return sourceQuality != null && selectedQuality == sourceQuality;

      case ValidationRuleType.shapeRequiresMetal:
        return sourceShape != null && selectedShape == sourceShape;

      case ValidationRuleType.gradingRequiresStoneType:
        return sourceStone != null && selectedStone != null;

      case ValidationRuleType.caratRequiresShape:
        return sourceShape != null && selectedShape == sourceShape;

      case ValidationRuleType.sizeRequiresMetal:
        return sourceMetal != null && selectedMetal == sourceMetal;
    }
  }
}

/// Result of validation
class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory ValidationResult.valid() => const ValidationResult(isValid: true);

  factory ValidationResult.invalid(List<ValidationError> errors) =>
      ValidationResult(isValid: false, errors: errors);
}

/// A validation error
class ValidationError {
  final String field;
  final String message;
  final String? ruleId;

  const ValidationError({
    required this.field,
    required this.message,
    this.ruleId,
  });
}

/// A validation warning (non-blocking)
class ValidationWarning {
  final String field;
  final String message;

  const ValidationWarning({
    required this.field,
    required this.message,
  });
}

/// Validator for product customization
class CustomizationValidator {
  final List<ValidationRule> rules;

  const CustomizationValidator({this.rules = const []});

  /// Validate a customization against all rules
  ValidationResult validate(Product product, ProductCustomization? customization) {
    if (customization == null) {
      return ValidationResult.valid();
    }

    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    // Validate metal + plating combinations
    if (customization.metalType != null) {
      _validateMetalPlating(
        customization.metalType!,
        customization.platingColor,
        product,
        errors,
      );
    }

    // Validate stone selections
    if (customization.stoneColorSelections != null) {
      for (final entry in customization.stoneColorSelections!.entries) {
        _validateStoneSelection(
          entry.key,
          entry.value,
          customization,
          product,
          errors,
          warnings,
        );
      }
    }

    // Validate diamond grading (only for diamonds)
    if (customization.stoneDiamondGrading != null) {
      for (final entry in customization.stoneDiamondGrading!.entries) {
        final stoneName = entry.key;
        final stoneColor = customization.stoneColorSelections?[stoneName];

        if (stoneColor != null && !_isDiamond(stoneColor)) {
          errors.add(ValidationError(
            field: 'stoneDiamondGrading.$stoneName',
            message: 'Diamond grading is only available for diamond stones',
          ));
        }
      }
    }

    // Apply custom rules
    for (final rule in rules.where((r) => r.isActive)) {
      _applyRule(rule, customization, product, errors, warnings);
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Get valid options for a field given current customization state
  List<String> getValidOptions({
    required String fieldName,
    required Product product,
    required ProductCustomization? current,
  }) {
    switch (fieldName) {
      case 'platingColor':
        return _getValidPlatingOptions(product, current);
      case 'metal':
        return _getValidMetalOptions(product, current);
      default:
        return [];
    }
  }

  /// Check if a specific option is valid
  bool isOptionValid({
    required String fieldName,
    required String value,
    required Product product,
    required ProductCustomization? current,
  }) {
    final validOptions = getValidOptions(
      fieldName: fieldName,
      product: product,
      current: current,
    );
    return validOptions.isEmpty || validOptions.contains(value);
  }

  /// Get reason why an option is disabled
  String? getDisabledReason({
    required String fieldName,
    required String value,
    required Product product,
    required ProductCustomization? current,
  }) {
    if (isOptionValid(
      fieldName: fieldName,
      value: value,
      product: product,
      current: current,
    )) {
      return null;
    }

    // Find the rule that's causing the option to be disabled
    for (final rule in rules.where((r) => r.isActive)) {
      if (rule.excludedValues?.contains(value) == true) {
        return rule.errorMessage;
      }
    }

    return 'This option is not available with your current selections';
  }

  void _validateMetalPlating(
    String metal,
    String? plating,
    Product product,
    List<ValidationError> errors,
  ) {
    // Check rules for this metal
    for (final rule in rules.where((r) =>
        r.isActive &&
        r.type == ValidationRuleType.metalRequiresPlating &&
        r.sourceMetal == metal)) {
      if (plating == null && rule.requiredValues?.isNotEmpty == true) {
        errors.add(ValidationError(
          field: 'platingColor',
          message: rule.errorMessage,
          ruleId: rule.id,
        ));
      }
    }

    for (final rule in rules.where((r) =>
        r.isActive &&
        r.type == ValidationRuleType.metalExcludesPlating &&
        r.sourceMetal == metal)) {
      if (plating != null && rule.excludedValues?.contains(plating) == true) {
        errors.add(ValidationError(
          field: 'platingColor',
          message: rule.errorMessage,
          ruleId: rule.id,
        ));
      }
    }
  }

  void _validateStoneSelection(
    String stoneName,
    String stoneColor,
    ProductCustomization customization,
    Product product,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    // Check if selected quality is valid for this stone type
    final qualityName = customization.stoneQualitySelections?[stoneName];
    if (qualityName != null) {
      for (final rule in rules.where((r) =>
          r.isActive &&
          r.type == ValidationRuleType.qualityRequiresStone &&
          r.sourceQuality == qualityName)) {
        if (rule.requiredValues?.contains(stoneColor) == false) {
          errors.add(ValidationError(
            field: 'stoneQuality.$stoneName',
            message: rule.errorMessage,
            ruleId: rule.id,
          ));
        }
      }
    }

    // Check shape requirements
    final shape = customization.stoneShapeSelections?[stoneName];
    if (shape != null) {
      for (final rule in rules.where((r) =>
          r.isActive &&
          r.type == ValidationRuleType.shapeRequiresMetal &&
          r.sourceShape == shape)) {
        if (customization.metalType != null &&
            rule.requiredValues?.contains(customization.metalType) == false) {
          warnings.add(ValidationWarning(
            field: 'stoneShape.$stoneName',
            message: rule.errorMessage,
          ));
        }
      }
    }
  }

  void _applyRule(
    ValidationRule rule,
    ProductCustomization customization,
    Product product,
    List<ValidationError> errors,
    List<ValidationWarning> warnings,
  ) {
    // Generic rule application based on type
    switch (rule.type) {
      case ValidationRuleType.stoneRequiresMetal:
        if (customization.stoneColorSelections?.values.contains(rule.sourceStone) ==
            true) {
          if (customization.metalType != null &&
              rule.requiredValues?.contains(customization.metalType) == false) {
            errors.add(ValidationError(
              field: 'metalType',
              message: rule.errorMessage,
              ruleId: rule.id,
            ));
          }
        }
        break;

      default:
        // Other rules handled specifically above
        break;
    }
  }

  List<String> _getValidPlatingOptions(
    Product product,
    ProductCustomization? current,
  ) {
    if (current?.metalType == null) {
      return product.availablePlatingColors;
    }

    final excludedOptions = <String>{};

    for (final rule in rules.where((r) =>
        r.isActive &&
        r.type == ValidationRuleType.metalExcludesPlating &&
        r.sourceMetal == current!.metalType)) {
      if (rule.excludedValues != null) {
        excludedOptions.addAll(rule.excludedValues!);
      }
    }

    return product.availablePlatingColors
        .where((p) => !excludedOptions.contains(p))
        .toList();
  }

  List<String> _getValidMetalOptions(
    Product product,
    ProductCustomization? current,
  ) {
    // By default, all metals are valid
    // Apply stone-requires-metal rules if stones are selected
    if (current?.stoneColorSelections == null ||
        current!.stoneColorSelections!.isEmpty) {
      return product.availableMetals;
    }

    final requiredMetals = <String>{};

    for (final stoneColor in current.stoneColorSelections!.values) {
      for (final rule in rules.where((r) =>
          r.isActive &&
          r.type == ValidationRuleType.stoneRequiresMetal &&
          r.sourceStone == stoneColor)) {
        if (rule.requiredValues != null) {
          if (requiredMetals.isEmpty) {
            requiredMetals.addAll(rule.requiredValues!);
          } else {
            requiredMetals.retainAll(rule.requiredValues!);
          }
        }
      }
    }

    if (requiredMetals.isEmpty) {
      return product.availableMetals;
    }

    return product.availableMetals
        .where((m) => requiredMetals.contains(m))
        .toList();
  }

  bool _isDiamond(String stoneColor) {
    final lower = stoneColor.toLowerCase();
    return lower.contains('diamond') ||
        lower == 'white' ||
        lower == 'clear' ||
        lower.contains('moissanite');
  }
}

/// Common validation rules for jewelry
class CommonValidationRules {
  /// Silver metals typically don't use gold plating
  static ValidationRule silverExcludesGoldPlating = const ValidationRule(
    id: 'silver_excludes_gold',
    type: ValidationRuleType.metalExcludesPlating,
    sourceMetal: 'Silver',
    excludedValues: ['Yellow Gold', 'Rose Gold'],
    errorMessage: 'Silver metal cannot have gold plating',
  );

  /// Platinum typically doesn't need plating
  static ValidationRule platinumNoPlating = const ValidationRule(
    id: 'platinum_no_plating',
    type: ValidationRuleType.metalExcludesPlating,
    sourceMetal: 'Platinum',
    excludedValues: ['Yellow Gold', 'Rose Gold', 'White Gold'],
    errorMessage: 'Platinum does not require plating',
  );

  /// Premium quality only for precious stones
  static ValidationRule premiumRequiresPrecious = const ValidationRule(
    id: 'premium_precious_only',
    type: ValidationRuleType.qualityRequiresStone,
    sourceQuality: 'Premium',
    requiredValues: ['Diamond', 'Ruby', 'Emerald', 'Sapphire'],
    errorMessage: 'Premium quality is only available for precious stones',
  );

  /// List of common default rules
  static List<ValidationRule> get defaults => [
        silverExcludesGoldPlating,
        platinumNoPlating,
        premiumRequiresPrecious,
      ];
}

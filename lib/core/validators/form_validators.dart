/// Centralized form validators for consistent validation across the app.
///
/// Usage:
/// ```dart
/// TextFormField(
///   validator: FormValidators.email,
/// )
/// ```
class FormValidators {
  FormValidators._(); // Private constructor to prevent instantiation

  // ============== Email Validation ==============

  /// Validates email format
  /// Returns error message or null if valid
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates email but allows empty (optional field)
  static String? emailOptional(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return email(value);
  }

  // ============== Phone Validation ==============

  /// Validates phone number (10+ digits)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Remove any non-digit characters
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validates phone number with exact digit count
  static String? phoneWithLength(String? value, {int length = 10}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length != length) {
      return 'Please enter a valid $length-digit phone number';
    }
    return null;
  }

  /// Validates phone with flexible format
  static String? phoneFlexible(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // ============== Password Validation ==============

  /// Validates password (minimum 6 characters)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates password with custom minimum length
  static String? passwordWithMinLength(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Creates a confirm password validator
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != password) {
        return 'Passwords do not match';
      }
      return null;
    };
  }

  /// Gets password strength
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 6) return PasswordStrength.weak;
    if (password.length < 10) return PasswordStrength.medium;
    if (RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]')
        .hasMatch(password)) {
      return PasswordStrength.strong;
    }
    return PasswordStrength.medium;
  }

  // ============== Name Validation ==============

  /// Validates name (required, non-empty)
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  /// Validates name with minimum length
  static String? nameWithMinLength(String? value, {int minLength = 2}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < minLength) {
      return 'Name must be at least $minLength characters';
    }
    return null;
  }

  // ============== Generic Validation ==============

  /// Validates required field
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates minimum length
  static String? Function(String?) minLength(int length, {String fieldName = 'Field'}) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return '$fieldName is required';
      }
      if (value.length < length) {
        return '$fieldName must be at least $length characters';
      }
      return null;
    };
  }

  /// Validates maximum length
  static String? Function(String?) maxLength(int length, {String fieldName = 'Field'}) {
    return (String? value) {
      if (value != null && value.length > length) {
        return '$fieldName must be at most $length characters';
      }
      return null;
    };
  }

  /// Validates numeric input
  static String? numeric(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    return null;
  }

  /// Validates positive number
  static String? positiveNumber(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      return '$fieldName must be a positive number';
    }
    return null;
  }

  // ============== OTP Validation ==============

  /// Validates OTP (4-10 alphanumeric characters)
  static String? otp(String? value, {int length = 6}) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP';
    }
    if (value.length != length) {
      return 'OTP must be $length digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  // ============== URL Validation ==============

  /// Validates URL format
  static String? url(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Please enter a URL' : null;
    }
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  // ============== Pincode Validation ==============

  /// Validates Indian pincode (6 digits)
  static String? pincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter pincode';
    }
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(value)) {
      return 'Please enter a valid 6-digit pincode';
    }
    return null;
  }

  // ============== Address Validation ==============

  /// Validates address (minimum 10 characters)
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your address';
    }
    if (value.trim().length < 10) {
      return 'Address must be at least 10 characters';
    }
    return null;
  }
}

/// Password strength levels
enum PasswordStrength {
  none,
  weak,
  medium,
  strong;

  String get label {
    switch (this) {
      case PasswordStrength.none:
        return '';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
}

/// Centralized country data for phone number selection.
///
/// Usage:
/// ```dart
/// DropdownButton<String>(
///   items: CountryData.countryCodes.map((country) {
///     return DropdownMenuItem(
///       value: country.dialCode,
///       child: Text('${country.flag} ${country.dialCode}'),
///     );
///   }).toList(),
/// )
/// ```
class CountryData {
  CountryData._(); // Private constructor to prevent instantiation

  /// Default country dial code
  static const String defaultDialCode = '+92'; // Pakistan

  /// List of country codes for phone number input
  static final List<Country> countryCodes = [
    const Country(
      name: 'Pakistan',
      dialCode: '+92',
      code: 'PK',
      flag: '\u{1F1F5}\u{1F1F0}', // Pakistani flag emoji
    ),
    const Country(
      name: 'India',
      dialCode: '+91',
      code: 'IN',
      flag: '\u{1F1EE}\u{1F1F3}', // Indian flag emoji
    ),
    const Country(
      name: 'United States',
      dialCode: '+1',
      code: 'US',
      flag: '\u{1F1FA}\u{1F1F8}', // US flag emoji
    ),
    const Country(
      name: 'United Kingdom',
      dialCode: '+44',
      code: 'GB',
      flag: '\u{1F1EC}\u{1F1E7}', // UK flag emoji
    ),
    const Country(
      name: 'United Arab Emirates',
      dialCode: '+971',
      code: 'AE',
      flag: '\u{1F1E6}\u{1F1EA}', // UAE flag emoji
    ),
    const Country(
      name: 'Saudi Arabia',
      dialCode: '+966',
      code: 'SA',
      flag: '\u{1F1F8}\u{1F1E6}', // Saudi flag emoji
    ),
    const Country(
      name: 'Kuwait',
      dialCode: '+965',
      code: 'KW',
      flag: '\u{1F1F0}\u{1F1FC}', // Kuwait flag emoji
    ),
    const Country(
      name: 'Oman',
      dialCode: '+968',
      code: 'OM',
      flag: '\u{1F1F4}\u{1F1F2}', // Oman flag emoji
    ),
    const Country(
      name: 'Bahrain',
      dialCode: '+973',
      code: 'BH',
      flag: '\u{1F1E7}\u{1F1ED}', // Bahrain flag emoji
    ),
    const Country(
      name: 'Qatar',
      dialCode: '+974',
      code: 'QA',
      flag: '\u{1F1F6}\u{1F1E6}', // Qatar flag emoji
    ),
    const Country(
      name: 'Canada',
      dialCode: '+1',
      code: 'CA',
      flag: '\u{1F1E8}\u{1F1E6}', // Canada flag emoji
    ),
    const Country(
      name: 'Australia',
      dialCode: '+61',
      code: 'AU',
      flag: '\u{1F1E6}\u{1F1FA}', // Australia flag emoji
    ),
    const Country(
      name: 'Germany',
      dialCode: '+49',
      code: 'DE',
      flag: '\u{1F1E9}\u{1F1EA}', // Germany flag emoji
    ),
    const Country(
      name: 'France',
      dialCode: '+33',
      code: 'FR',
      flag: '\u{1F1EB}\u{1F1F7}', // France flag emoji
    ),
    const Country(
      name: 'Singapore',
      dialCode: '+65',
      code: 'SG',
      flag: '\u{1F1F8}\u{1F1EC}', // Singapore flag emoji
    ),
    const Country(
      name: 'Malaysia',
      dialCode: '+60',
      code: 'MY',
      flag: '\u{1F1F2}\u{1F1FE}', // Malaysia flag emoji
    ),
    const Country(
      name: 'Bangladesh',
      dialCode: '+880',
      code: 'BD',
      flag: '\u{1F1E7}\u{1F1E9}', // Bangladesh flag emoji
    ),
    const Country(
      name: 'Sri Lanka',
      dialCode: '+94',
      code: 'LK',
      flag: '\u{1F1F1}\u{1F1F0}', // Sri Lanka flag emoji
    ),
    const Country(
      name: 'Nepal',
      dialCode: '+977',
      code: 'NP',
      flag: '\u{1F1F3}\u{1F1F5}', // Nepal flag emoji
    ),
  ];

  /// Find country by dial code
  static Country? findByDialCode(String dialCode) {
    try {
      return countryCodes.firstWhere(
        (country) => country.dialCode == dialCode,
      );
    } catch (_) {
      return null;
    }
  }

  /// Find country by country code (e.g., 'US', 'IN')
  static Country? findByCode(String code) {
    try {
      return countryCodes.firstWhere(
        (country) => country.code == code.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get default country
  static Country get defaultCountry {
    return findByDialCode(defaultDialCode) ?? countryCodes.first;
  }

  /// Convert to legacy format (for backward compatibility)
  static List<Map<String, String>> get legacyFormat {
    return countryCodes.map((country) => {
      'code': country.dialCode,
      'country': country.name,
      'flag': country.flag,
    }).toList();
  }
}

/// Model class for country data
class Country {
  final String name;
  final String dialCode;
  final String code;
  final String flag;

  const Country({
    required this.name,
    required this.dialCode,
    required this.code,
    required this.flag,
  });

  /// Short display format (e.g., "+91")
  String get shortDisplay => dialCode;

  /// Full display format (e.g., "+91 India")
  String get fullDisplay => '$dialCode $name';

  /// Display with flag (e.g., "India +91")
  String get displayWithFlag => '$flag $dialCode';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Country($name, $dialCode)';
}

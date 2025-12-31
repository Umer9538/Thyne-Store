class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String? profilePicture; // Alias for profileImage
  final DateTime createdAt;
  final List<Address> addresses;
  final Address? defaultAddress;
  final bool isAdmin;
  final bool isActive;
  final bool isVerified;
  final String? role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.profilePicture,
    required this.createdAt,
    this.addresses = const [],
    this.defaultAddress,
    this.isAdmin = false,
    this.isActive = true,
    this.isVerified = false,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final addressesList = (json['addresses'] as List?)
            ?.map((a) => Address.fromJson(a))
            .toList() ??
        [];

    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      profilePicture: json['profilePicture']?.toString() ?? json['profileImage']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      addresses: addressesList,
      defaultAddress: addressesList.isNotEmpty ? addressesList.first : null,
      isAdmin: json['isAdmin'] ?? false,
      isActive: json['isActive'] ?? true,
      isVerified: json['isVerified'] ?? false,
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'addresses': addresses.map((a) => a.toJson()).toList(),
      'isAdmin': isAdmin,
      'isActive': isActive,
      'isVerified': isVerified,
      'role': role,
    };
  }
}

/// Address label options
enum AddressLabel { home, work, other }

extension AddressLabelExtension on AddressLabel {
  String get displayName {
    switch (this) {
      case AddressLabel.home:
        return 'Home';
      case AddressLabel.work:
        return 'Work';
      case AddressLabel.other:
        return 'Other';
    }
  }

  static AddressLabel fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'home':
        return AddressLabel.home;
      case 'work':
        return AddressLabel.work;
      default:
        return AddressLabel.other;
    }
  }
}

class Address {
  final String id;
  // New detailed address fields
  final String houseNoFloor;     // House no. & Floor
  final String buildingBlock;     // Building & Block number
  final String landmarkArea;      // Landmark & Area
  final String city;
  final String state;
  final String pincode;           // Pincode (was zipCode)
  final String country;
  final AddressLabel label;       // Address label (Home, Work, Other)
  final String? recipientName;    // Optional: Name of person at this address
  final String? recipientPhone;   // Optional: Phone number for this address
  final bool isDefault;

  // Legacy field for backward compatibility
  final String? street;

  Address({
    required this.id,
    required this.houseNoFloor,
    required this.buildingBlock,
    required this.landmarkArea,
    required this.city,
    required this.state,
    required this.pincode,
    this.country = 'India',
    this.label = AddressLabel.home,
    this.recipientName,
    this.recipientPhone,
    this.isDefault = false,
    this.street,
  });

  /// Get full formatted address string
  String get fullAddress {
    final parts = <String>[
      houseNoFloor,
      buildingBlock,
      landmarkArea,
      city,
      state,
      pincode,
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  /// Get short address (for display in lists)
  String get shortAddress {
    final parts = <String>[
      houseNoFloor,
      landmarkArea,
      city,
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility with old 'street' field
    final legacyStreet = json['street']?.toString() ?? '';

    return Address(
      id: json['id']?.toString() ?? '',
      houseNoFloor: json['houseNoFloor']?.toString() ?? json['houseNo']?.toString() ?? '',
      buildingBlock: json['buildingBlock']?.toString() ?? json['building']?.toString() ?? '',
      landmarkArea: json['landmarkArea']?.toString() ?? json['landmark']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? json['zipCode']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      label: AddressLabelExtension.fromString(json['label']?.toString()),
      recipientName: json['recipientName']?.toString(),
      recipientPhone: json['recipientPhone']?.toString(),
      isDefault: json['isDefault'] ?? false,
      street: legacyStreet.isNotEmpty ? legacyStreet : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'houseNoFloor': houseNoFloor,
      'buildingBlock': buildingBlock,
      'landmarkArea': landmarkArea,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'label': label.name,
      if (recipientName != null) 'recipientName': recipientName,
      if (recipientPhone != null) 'recipientPhone': recipientPhone,
      'isDefault': isDefault,
      // Include legacy field for backward compatibility with API
      'street': fullAddress,
      'zipCode': pincode,
    };
  }

  Address copyWith({
    String? id,
    String? houseNoFloor,
    String? buildingBlock,
    String? landmarkArea,
    String? city,
    String? state,
    String? pincode,
    String? country,
    AddressLabel? label,
    String? recipientName,
    String? recipientPhone,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      houseNoFloor: houseNoFloor ?? this.houseNoFloor,
      buildingBlock: buildingBlock ?? this.buildingBlock,
      landmarkArea: landmarkArea ?? this.landmarkArea,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
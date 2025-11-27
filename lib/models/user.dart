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
      'role': role,
    };
  }
}

class Address {
  final String id;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;

  Address({
    required this.id,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'isDefault': isDefault,
    };
  }
}
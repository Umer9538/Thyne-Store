class GuestUser {
  final String sessionId;
  final String? email;
  final String? phone;
  final String? name;
  final DateTime createdAt;
  final DateTime lastActivity;

  GuestUser({
    required this.sessionId,
    this.email,
    this.phone,
    this.name,
    required this.createdAt,
    required this.lastActivity,
  });

  factory GuestUser.create() {
    final now = DateTime.now();
    return GuestUser(
      sessionId: 'guest_${now.millisecondsSinceEpoch}',
      createdAt: now,
      lastActivity: now,
    );
  }

  GuestUser copyWith({
    String? sessionId,
    String? email,
    String? phone,
    String? name,
    DateTime? createdAt,
    DateTime? lastActivity,
  }) {
    return GuestUser(
      sessionId: sessionId ?? this.sessionId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  factory GuestUser.fromJson(Map<String, dynamic> json) {
    return GuestUser(
      sessionId: json['sessionId']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      name: json['name']?.toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      lastActivity: json['lastActivity'] != null 
          ? DateTime.parse(json['lastActivity']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'email': email,
      'phone': phone,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
    };
  }

  bool get hasContactInfo => email != null || phone != null;
  bool get hasName => name != null && name!.isNotEmpty;
}
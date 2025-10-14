import 'package:flutter/material.dart';

class ThemeConfig {
  final String id;
  final String name;
  final String type; // 'festival', 'seasonal', 'custom'
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String? logoUrl;
  final String? backgroundImage;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ThemeConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.logoUrl,
    this.backgroundImage,
    this.startDate,
    this.endDate,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'custom',
      primaryColor: json['primaryColor'] ?? '#1B5E20',
      secondaryColor: json['secondaryColor'] ?? '#2E7D32',
      accentColor: json['accentColor'] ?? '#4CAF50',
      logoUrl: json['logoUrl'],
      backgroundImage: json['backgroundImage'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
      'logoUrl': logoUrl,
      'backgroundImage': backgroundImage,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Color get primaryColorValue => Color(
    int.parse(primaryColor.replaceFirst('#', '0xFF'))
  );

  Color get secondaryColorValue => Color(
    int.parse(secondaryColor.replaceFirst('#', '0xFF'))
  );

  Color get accentColorValue => Color(
    int.parse(accentColor.replaceFirst('#', '0xFF'))
  );

  // Predefined festival themes
  static ThemeConfig diwaliTheme() {
    return ThemeConfig(
      id: 'diwali',
      name: 'Diwali',
      type: 'festival',
      primaryColor: '#FF6F00', // Deep Orange
      secondaryColor: '#FFA726', // Orange
      accentColor: '#FFD54F', // Amber
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static ThemeConfig christmasTheme() {
    return ThemeConfig(
      id: 'christmas',
      name: 'Christmas',
      type: 'festival',
      primaryColor: '#C62828', // Red
      secondaryColor: '#2E7D32', // Green
      accentColor: '#FFD700', // Gold
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static ThemeConfig valentineTheme() {
    return ThemeConfig(
      id: 'valentine',
      name: 'Valentine',
      type: 'festival',
      primaryColor: '#D81B60', // Pink
      secondaryColor: '#EC407A', // Light Pink
      accentColor: '#F8BBD0', // Pale Pink
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static ThemeConfig newYearTheme() {
    return ThemeConfig(
      id: 'newyear',
      name: 'New Year',
      type: 'festival',
      primaryColor: '#1565C0', // Blue
      secondaryColor: '#FFD700', // Gold
      accentColor: '#FFC107', // Amber
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static ThemeConfig defaultTheme() {
    return ThemeConfig(
      id: 'default',
      name: 'Default',
      type: 'custom',
      primaryColor: '#1B5E20', // Dark Green
      secondaryColor: '#2E7D32', // Medium Green
      accentColor: '#4CAF50', // Light Green
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

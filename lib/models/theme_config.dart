import 'package:flutter/material.dart';

class ThemeConfig {
  final String id;
  final String name;
  final String type; // 'festival', 'seasonal', 'custom'
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String backgroundColor;
  final String surfaceColor;
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
    required this.backgroundColor,
    required this.surfaceColor,
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
      primaryColor: json['primaryColor'] ?? '#FFD700',
      secondaryColor: json['secondaryColor'] ?? '#FFA500',
      accentColor: json['accentColor'] ?? '#FF8C00',
      backgroundColor: json['backgroundColor'] ?? '#FFFFFF',
      surfaceColor: json['surfaceColor'] ?? '#F5F5F5',
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
      'backgroundColor': backgroundColor,
      'surfaceColor': surfaceColor,
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

  Color get backgroundColorValue => Color(
    int.parse(backgroundColor.replaceFirst('#', '0xFF'))
  );

  Color get surfaceColorValue => Color(
    int.parse(surfaceColor.replaceFirst('#', '0xFF'))
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
      backgroundColor: '#FFF8E1', // Light Amber
      surfaceColor: '#FFECB3', // Pale Amber
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
      backgroundColor: '#FFEBEE', // Light Red
      surfaceColor: '#E8F5E9', // Light Green
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
      backgroundColor: '#FCE4EC', // Very Light Pink
      surfaceColor: '#F8BBD0', // Pink Surface
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
      backgroundColor: '#E3F2FD', // Light Blue
      surfaceColor: '#FFF9C4', // Light Yellow
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static ThemeConfig defaultTheme() {
    return ThemeConfig(
      id: 'default',
      name: 'Default',
      type: 'custom',
      primaryColor: '#FFD700', // Gold
      secondaryColor: '#FFA500', // Orange
      accentColor: '#FF8C00', // Dark Orange
      backgroundColor: '#FFFFFF', // White
      surfaceColor: '#F5F5F5', // Light Gray
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

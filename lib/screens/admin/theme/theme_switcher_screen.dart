import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/theme_config.dart';
import '../../../services/api_service.dart';
import '../../../utils/theme.dart';
import '../../../providers/theme_provider.dart';
import 'custom_theme_form_screen.dart';

class ThemeSwitcherScreen extends StatefulWidget {
  const ThemeSwitcherScreen({super.key});

  @override
  State<ThemeSwitcherScreen> createState() => _ThemeSwitcherScreenState();
}

class _ThemeSwitcherScreenState extends State<ThemeSwitcherScreen> {
  List<ThemeConfig> _themes = [];
  ThemeConfig? _activeTheme;
  bool _isLoading = false;

  final List<ThemeConfig> _predefinedThemes = [
    ThemeConfig.defaultTheme(),
    ThemeConfig.diwaliTheme(),
    ThemeConfig.christmasTheme(),
    ThemeConfig.valentineTheme(),
    ThemeConfig.newYearTheme(),
  ];

  @override
  void initState() {
    super.initState();
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    setState(() => _isLoading = true);
    try {
      // Load active theme
      final activeResponse = await ApiService.getActiveTheme();
      if (activeResponse['success'] == true && activeResponse['data'] != null) {
        setState(() {
          _activeTheme = ThemeConfig.fromJson(activeResponse['data']);
        });
      }

      // Load all custom themes from backend
      final themesResponse = await ApiService.getThemes();
      if (themesResponse['success'] == true && themesResponse['data'] != null) {
        final customThemes = (themesResponse['data'] as List)
            .map((json) => ThemeConfig.fromJson(json))
            .toList();
        setState(() {
          _themes = customThemes;
        });
      }
    } catch (e) {
      debugPrint('Error loading themes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _activateTheme(ThemeConfig theme) async {
    setState(() => _isLoading = true);
    try {
      // Create theme if it doesn't exist in backend (for predefined themes)
      try {
        await ApiService.createThemeConfig(themeData: theme.toJson());
      } catch (e) {
        // Ignore if theme already exists
        debugPrint('Theme may already exist: $e');
      }

      // Activate the theme
      await ApiService.activateTheme(themeId: theme.id);

      setState(() {
        _activeTheme = theme;
      });

      // Refresh the app theme globally
      if (mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        await themeProvider.refreshTheme();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${theme.name} theme activated!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error activating theme: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Theme Manager'),
            if (_activeTheme != null)
              Text(
                'Active: ${_activeTheme!.name}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomThemeFormScreen(),
            ),
          );
          if (result == true) {
            _loadThemes();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Custom'),
        backgroundColor: AppTheme.primaryGold,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Predefined Festival Themes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._predefinedThemes.map((theme) => _buildThemeCard(theme)),
                
                if (_themes.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Custom Themes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _loadThemes,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._themes.map((theme) => _buildThemeCard(theme, isCustom: true)),
                ],
                
                const SizedBox(height: 24),
                _buildColorLegend(),
              ],
            ),
    );
  }

  Widget _buildThemeCard(ThemeConfig theme, {bool isCustom = false}) {
    final isActive = _activeTheme?.id == theme.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isActive ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? AppTheme.primaryGold : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildColorPreview(theme),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            theme.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildColorSwatch(
                    'Primary',
                    theme.primaryColorValue,
                    theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildColorSwatch(
                    'Secondary',
                    theme.secondaryColorValue,
                    theme.secondaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildColorSwatch(
                    'Accent',
                    theme.accentColorValue,
                    theme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isActive ? null : () => _activateTheme(theme),
                icon: Icon(isActive ? Icons.check : Icons.palette),
                label: Text(isActive ? 'Active Theme' : 'Activate Theme'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive
                      ? AppTheme.successGreen
                      : theme.primaryColorValue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPreview(ThemeConfig theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            Expanded(
              child: Container(color: theme.primaryColorValue),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(color: theme.secondaryColorValue),
                  ),
                  Expanded(
                    child: Container(color: theme.accentColorValue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(String label, Color color, String hexCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hexCode,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildColorLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGold.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'How It Works',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Select a festival theme to instantly update your app colors\n'
            '• Primary: Main buttons, headers, and key UI elements\n'
            '• Secondary: Supporting colors and accents\n'
            '• Accent: Highlights, links, and special elements\n'
            '• Changes apply immediately across the entire app',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

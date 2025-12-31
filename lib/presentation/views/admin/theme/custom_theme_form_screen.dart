import 'package:flutter/material.dart';
import '../../../../data/services/api_service.dart';
import '../../../../utils/theme.dart';
import '../../../../utils/responsive.dart';
import '../../../widgets/enhanced_color_picker.dart';
import '../../../widgets/responsive_screen_wrapper.dart';

class CustomThemeFormScreen extends StatefulWidget {
  const CustomThemeFormScreen({super.key});

  @override
  State<CustomThemeFormScreen> createState() => _CustomThemeFormScreenState();
}

class _CustomThemeFormScreenState extends State<CustomThemeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  Color _primaryColor = const Color(0xFFFFD700);
  Color _secondaryColor = const Color(0xFFFFA500);
  Color _accentColor = const Color(0xFFFF8C00);
  Color _backgroundColor = const Color(0xFFFFFFFF);
  Color _surfaceColor = const Color(0xFFF5F5F5);

  String _type = 'custom';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _pickColor(String colorType) {
    Color initialColor;
    String title;
    switch (colorType) {
      case 'primary':
        initialColor = _primaryColor;
        title = 'Primary Color';
        break;
      case 'secondary':
        initialColor = _secondaryColor;
        title = 'Secondary Color';
        break;
      case 'accent':
        initialColor = _accentColor;
        title = 'Accent Color';
        break;
      case 'background':
        initialColor = _backgroundColor;
        title = 'Background Color';
        break;
      case 'surface':
        initialColor = _surfaceColor;
        title = 'Surface Color';
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => EnhancedColorPicker(
        initialColor: initialColor,
        title: title,
        onColorChanged: (Color color) {
          setState(() {
            switch (colorType) {
              case 'primary':
                _primaryColor = color;
                break;
              case 'secondary':
                _secondaryColor = color;
                break;
              case 'accent':
                _accentColor = color;
                break;
              case 'background':
                _backgroundColor = color;
                break;
              case 'surface':
                _surfaceColor = color;
                break;
            }
          });
        },
      ),
    );
  }

  Future<void> _saveTheme() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final themeData = {
        'name': _nameController.text.trim(),
        'type': _type,
        'primaryColor': _colorToHex(_primaryColor),
        'secondaryColor': _colorToHex(_secondaryColor),
        'accentColor': _colorToHex(_accentColor),
        'backgroundColor': _colorToHex(_backgroundColor),
        'surfaceColor': _colorToHex(_surfaceColor),
        'isActive': false,
      };

      await ApiService.createThemeConfig(themeData: themeData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom theme created successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating theme: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = Responsive.isWeb(context);

    return ResponsiveScaffold(
      title: 'Create Custom Theme',
      maxWidth: 1000,
      centerContent: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Theme Name
                    ResponsiveFormField(
                      label: 'Theme Name',
                      hint: 'e.g., Summer Collection',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a theme name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: Responsive.spacing(context, 20)),

                    // Theme Type
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Theme Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'custom', child: Text('Custom')),
                        DropdownMenuItem(value: 'festival', child: Text('Festival')),
                        DropdownMenuItem(value: 'seasonal', child: Text('Seasonal')),
                      ],
                      onChanged: (value) {
                        setState(() => _type = value!);
                      },
                    ),
                    const SizedBox(height: 32),

                    // Color Pickers Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGold.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.palette, color: AppTheme.primaryGold, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Theme Colors (5 Colors)',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pick colors visually or enter hex codes directly',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Color Grid for Web, List for Mobile
                    if (isWeb)
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildColorPickerCard(
                                  'Primary Color',
                                  'Main buttons, headers',
                                  _primaryColor,
                                  'primary',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildColorPickerCard(
                                  'Secondary Color',
                                  'Secondary buttons',
                                  _secondaryColor,
                                  'secondary',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildColorPickerCard(
                                  'Accent Color',
                                  'Highlights & links',
                                  _accentColor,
                                  'accent',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildColorPickerCard(
                                  'Background Color',
                                  'Page backgrounds',
                                  _backgroundColor,
                                  'background',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildColorPickerCard(
                                  'Surface Color',
                                  'Cards & containers',
                                  _surfaceColor,
                                  'surface',
                                ),
                              ),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildColorPickerCard(
                            'Primary Color',
                            'Main buttons, headers, key UI elements',
                            _primaryColor,
                            'primary',
                          ),
                          const SizedBox(height: 12),
                          _buildColorPickerCard(
                            'Secondary Color',
                            'Supporting colors and secondary buttons',
                            _secondaryColor,
                            'secondary',
                          ),
                          const SizedBox(height: 12),
                          _buildColorPickerCard(
                            'Accent Color',
                            'Highlights, links, special elements',
                            _accentColor,
                            'accent',
                          ),
                          const SizedBox(height: 12),
                          _buildColorPickerCard(
                            'Background Color',
                            'Main background for pages and screens',
                            _backgroundColor,
                            'background',
                          ),
                          const SizedBox(height: 12),
                          _buildColorPickerCard(
                            'Surface Color',
                            'Cards, containers, and elevated surfaces',
                            _surfaceColor,
                            'surface',
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),

                    // Preview
                    _buildPreviewSection(),
                    const SizedBox(height: 32),

                    // Save Button
                    ResponsiveButton(
                      label: 'Create Theme',
                      icon: Icons.save,
                      onPressed: _saveTheme,
                      color: AppTheme.primaryGold,
                      width: double.infinity,
                    ),
                    SizedBox(height: Responsive.spacing(context, 20)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildColorPickerCard(
    String title,
    String description,
    Color color,
    String colorType,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _pickColor(colorType),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Color Preview
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
              const SizedBox(width: 16),
              // Color Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _colorToHex(color),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit, color: AppTheme.primaryGold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theme Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Color Swatches Row
          Row(
            children: [
              Expanded(child: _buildColorSwatch('Primary', _primaryColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildColorSwatch('Secondary', _secondaryColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildColorSwatch('Accent', _accentColor)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildColorSwatch('Background', _backgroundColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildColorSwatch('Surface', _surfaceColor)),
              const SizedBox(width: 8),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),

          // Button Previews on Surface
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Text('Primary Button'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _secondaryColor,
                          side: BorderSide(color: _secondaryColor, width: 2),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Text('Secondary Button'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: _accentColor,
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Text('Accent Text Button'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(String label, Color color) {
    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


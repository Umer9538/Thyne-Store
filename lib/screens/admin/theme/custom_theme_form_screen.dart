import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../services/api_service.dart';
import '../../../utils/theme.dart';

class CustomThemeFormScreen extends StatefulWidget {
  const CustomThemeFormScreen({super.key});

  @override
  State<CustomThemeFormScreen> createState() => _CustomThemeFormScreenState();
}

class _CustomThemeFormScreenState extends State<CustomThemeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  Color _primaryColor = const Color(0xFF1B5E20);
  Color _secondaryColor = const Color(0xFF2E7D32);
  Color _accentColor = const Color(0xFF4CAF50);
  
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
    switch (colorType) {
      case 'primary':
        initialColor = _primaryColor;
        break;
      case 'secondary':
        initialColor = _secondaryColor;
        break;
      case 'accent':
        initialColor = _accentColor;
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick ${colorType.toUpperCase()} Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
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
                }
              });
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DONE'),
          ),
        ],
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Custom Theme'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Theme Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Theme Name',
                        hintText: 'e.g., Summer Collection',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a theme name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

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
                    const Text(
                      'Theme Colors',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Primary Color
                    _buildColorPickerCard(
                      'Primary Color',
                      'Main buttons, headers, key UI elements',
                      _primaryColor,
                      'primary',
                    ),
                    const SizedBox(height: 16),

                    // Secondary Color
                    _buildColorPickerCard(
                      'Secondary Color',
                      'Supporting colors and accents',
                      _secondaryColor,
                      'secondary',
                    ),
                    const SizedBox(height: 16),

                    // Accent Color
                    _buildColorPickerCard(
                      'Accent Color',
                      'Highlights, links, special elements',
                      _accentColor,
                      'accent',
                    ),
                    const SizedBox(height: 32),

                    // Preview
                    _buildPreviewSection(),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton.icon(
                      onPressed: _saveTheme,
                      icon: const Icon(Icons.save),
                      label: const Text('Create Theme'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
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
        color: Colors.grey.shade100,
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
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
    );
  }
}


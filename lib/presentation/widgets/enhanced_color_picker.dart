import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../utils/theme.dart';

/// Enhanced color picker with both visual picker and hex input
class EnhancedColorPicker extends StatefulWidget {
  final Color initialColor;
  final String title;
  final ValueChanged<Color> onColorChanged;

  const EnhancedColorPicker({
    super.key,
    required this.initialColor,
    required this.title,
    required this.onColorChanged,
  });

  @override
  State<EnhancedColorPicker> createState() => _EnhancedColorPickerState();
}

class _EnhancedColorPickerState extends State<EnhancedColorPicker> {
  late Color _currentColor;
  late TextEditingController _hexController;
  bool _isHexValid = true;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _hexController = TextEditingController(
      text: _colorToHex(_currentColor),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return color.value.toRadixString(16).substring(2).toUpperCase();
  }

  Color? _hexToColor(String hex) {
    // Remove # if present
    hex = hex.replaceAll('#', '');

    // Validate hex string
    if (hex.length != 6) return null;

    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }

  void _updateFromHex(String hex) {
    final color = _hexToColor(hex);
    if (color != null) {
      setState(() {
        _currentColor = color;
        _isHexValid = true;
      });
      widget.onColorChanged(color);
    } else {
      setState(() {
        _isHexValid = false;
      });
    }
  }

  void _updateFromPicker(Color color) {
    setState(() {
      _currentColor = color;
      _hexController.text = _colorToHex(color);
      _isHexValid = true;
    });
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.palette, color: AppTheme.primaryGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: isWeb ? 500 : screenWidth * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hex Input Section
              Row(
                children: [
                  const Icon(Icons.text_fields, size: 18, color: AppTheme.primaryGold),
                  const SizedBox(width: 8),
                  const Text(
                    'Enter Hex Code',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _currentColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _currentColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _hexController,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          prefixText: '#',
                          prefixStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                          hintText: 'FFD700',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: _isHexValid ? null : 'Invalid hex code',
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.check_circle,
                              color: _isHexValid ? Colors.green : Colors.grey,
                            ),
                            onPressed: () {
                              _updateFromHex(_hexController.text);
                            },
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                          LengthLimitingTextInputFormatter(6),
                          UpperCaseTextFormatter(),
                        ],
                        onChanged: (value) {
                          if (value.length == 6) {
                            _updateFromHex(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Visual Color Picker Section
              const Divider(height: 32),
              Row(
                children: [
                  const Icon(Icons.colorize, size: 18, color: AppTheme.primaryGold),
                  const SizedBox(width: 8),
                  const Text(
                    'Or Pick Visually',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ColorPicker(
                pickerColor: _currentColor,
                onColorChanged: _updateFromPicker,
                pickerAreaHeightPercent: 0.7,
                displayThumbColor: true,
                enableAlpha: false,
                labelTypes: const [],
                pickerAreaBorderRadius: BorderRadius.circular(12),
              ),

              const SizedBox(height: 24),

              // Common Colors Section
              Row(
                children: [
                  const Icon(Icons.palette_outlined, size: 18, color: AppTheme.primaryGold),
                  const SizedBox(width: 8),
                  const Text(
                    'Quick Colors',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickColor(const Color(0xFFFFD700), 'Gold'),
                  _buildQuickColor(const Color(0xFFFFA500), 'Orange'),
                  _buildQuickColor(const Color(0xFFFF6B6B), 'Coral'),
                  _buildQuickColor(const Color(0xFF4ECDC4), 'Teal'),
                  _buildQuickColor(const Color(0xFF95E1D3), 'Mint'),
                  _buildQuickColor(const Color(0xFFF38181), 'Pink'),
                  _buildQuickColor(const Color(0xFFAA96DA), 'Purple'),
                  _buildQuickColor(const Color(0xFF5F27CD), 'Deep Purple'),
                  _buildQuickColor(const Color(0xFF00D2FF), 'Sky Blue'),
                  _buildQuickColor(const Color(0xFF1B1464), 'Navy'),
                  _buildQuickColor(const Color(0xFF2ECC71), 'Green'),
                  _buildQuickColor(const Color(0xFFE74C3C), 'Red'),
                  _buildQuickColor(const Color(0xFFFFFFFF), 'White'),
                  _buildQuickColor(const Color(0xFFF5F5F5), 'Light Gray'),
                  _buildQuickColor(const Color(0xFF9E9E9E), 'Gray'),
                  _buildQuickColor(const Color(0xFF212121), 'Dark Gray'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_isHexValid) {
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGold,
          ),
          child: const Text('DONE'),
        ),
      ],
    );
  }

  Widget _buildQuickColor(Color color, String name) {
    final isSelected = _currentColor.value == color.value;
    final isDark = color.computeLuminance() < 0.5;

    return GestureDetector(
      onTap: () => _updateFromPicker(color),
      child: Tooltip(
        message: name,
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGold : Colors.grey.shade400,
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: AppTheme.primaryGold.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: isDark ? Colors.white : Colors.black,
                  size: 24,
                )
              : null,
        ),
      ),
    );
  }
}

/// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

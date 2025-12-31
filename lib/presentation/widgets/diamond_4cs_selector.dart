import 'package:flutter/material.dart';
import '../../data/models/store_settings.dart';

/// Widget for selecting Diamond 4Cs (Color, Clarity, Cut grades)
class Diamond4CsSelector extends StatelessWidget {
  final DiamondGrading? currentGrading;
  final List<String> availableColorGrades;
  final List<String> availableClarityGrades;
  final List<String> availableCutGrades;
  final Map<String, double>? colorPriceModifiers;
  final Map<String, double>? clarityPriceModifiers;
  final Map<String, double>? cutPriceModifiers;
  final ValueChanged<DiamondGrading> onGradingChanged;
  final bool showPriceModifiers;

  const Diamond4CsSelector({
    super.key,
    required this.currentGrading,
    required this.availableColorGrades,
    required this.availableClarityGrades,
    required this.availableCutGrades,
    this.colorPriceModifiers,
    this.clarityPriceModifiers,
    this.cutPriceModifiers,
    required this.onGradingChanged,
    this.showPriceModifiers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              const Icon(Icons.diamond_outlined, size: 18, color: Color(0xFF666666)),
              const SizedBox(width: 8),
              Text(
                'Diamond Quality (4Cs)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (currentGrading != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    currentGrading!.shortSummary,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Color Grade Section
        _GradeSection(
          title: 'Color',
          subtitle: 'D is colorless, K has faint yellow',
          icon: Icons.palette_outlined,
          grades: availableColorGrades,
          selectedGrade: currentGrading?.colorGrade,
          priceModifiers: colorPriceModifiers,
          showPriceModifiers: showPriceModifiers,
          gradeDescriptions: _colorDescriptions,
          onGradeSelected: (grade) => _updateGrading(colorGrade: grade),
        ),

        const SizedBox(height: 16),

        // Clarity Grade Section
        _GradeSection(
          title: 'Clarity',
          subtitle: 'FL is flawless, SI2 has slight inclusions',
          icon: Icons.visibility_outlined,
          grades: availableClarityGrades,
          selectedGrade: currentGrading?.clarityGrade,
          priceModifiers: clarityPriceModifiers,
          showPriceModifiers: showPriceModifiers,
          gradeDescriptions: _clarityDescriptions,
          onGradeSelected: (grade) => _updateGrading(clarityGrade: grade),
        ),

        const SizedBox(height: 16),

        // Cut Grade Section
        _GradeSection(
          title: 'Cut',
          subtitle: 'Determines brilliance and sparkle',
          icon: Icons.auto_awesome_outlined,
          grades: availableCutGrades,
          selectedGrade: currentGrading?.cutGrade,
          priceModifiers: cutPriceModifiers,
          showPriceModifiers: showPriceModifiers,
          gradeDescriptions: _cutDescriptions,
          onGradeSelected: (grade) => _updateGrading(cutGrade: grade),
        ),
      ],
    );
  }

  void _updateGrading({
    String? colorGrade,
    String? clarityGrade,
    String? cutGrade,
  }) {
    final newGrading = DiamondGrading(
      colorGrade: colorGrade ?? currentGrading?.colorGrade ?? 'G',
      clarityGrade: clarityGrade ?? currentGrading?.clarityGrade ?? 'VS1',
      cutGrade: cutGrade ?? currentGrading?.cutGrade ?? 'Excellent',
    );
    onGradingChanged(newGrading);
  }

  static const Map<String, String> _colorDescriptions = {
    'D': 'Absolutely colorless',
    'E': 'Colorless',
    'F': 'Colorless',
    'G': 'Near colorless',
    'H': 'Near colorless',
    'I': 'Near colorless',
    'J': 'Near colorless',
    'K': 'Faint yellow',
  };

  static const Map<String, String> _clarityDescriptions = {
    'FL': 'Flawless',
    'IF': 'Internally flawless',
    'VVS1': 'Very very slight inclusions',
    'VVS2': 'Very very slight inclusions',
    'VS1': 'Very slight inclusions',
    'VS2': 'Very slight inclusions',
    'SI1': 'Slight inclusions',
    'SI2': 'Slight inclusions',
  };

  static const Map<String, String> _cutDescriptions = {
    'Excellent': 'Maximum brilliance',
    'Very Good': 'Exceptional brilliance',
    'Good': 'Good brilliance',
    'Fair': 'Adequate brilliance',
  };
}

class _GradeSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> grades;
  final String? selectedGrade;
  final Map<String, double>? priceModifiers;
  final bool showPriceModifiers;
  final Map<String, String> gradeDescriptions;
  final ValueChanged<String> onGradeSelected;

  const _GradeSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.grades,
    required this.selectedGrade,
    this.priceModifiers,
    required this.showPriceModifiers,
    required this.gradeDescriptions,
    required this.onGradeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Grade chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: grades.map((grade) {
              final isSelected = grade == selectedGrade;
              final priceModifier = priceModifiers?[grade];
              final description = gradeDescriptions[grade];

              return _GradeChip(
                grade: grade,
                description: description,
                isSelected: isSelected,
                priceModifier: priceModifier,
                showPriceModifier: showPriceModifiers && priceModifier != null,
                onTap: () => onGradeSelected(grade),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final String grade;
  final String? description;
  final bool isSelected;
  final double? priceModifier;
  final bool showPriceModifier;
  final VoidCallback onTap;

  const _GradeChip({
    required this.grade,
    this.description,
    required this.isSelected,
    this.priceModifier,
    required this.showPriceModifier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: description ?? '',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                grade,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[800],
                ),
              ),
              if (showPriceModifier && priceModifier != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatMultiplier(priceModifier!),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : (priceModifier! > 1.0 ? Colors.orange[700] : Colors.green[700]),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatMultiplier(double multiplier) {
    if (multiplier == 1.0) return 'Base';
    if (multiplier > 1.0) {
      return '+${((multiplier - 1) * 100).toInt()}%';
    } else {
      return '-${((1 - multiplier) * 100).toInt()}%';
    }
  }
}

/// Compact version of 4Cs selector for space-constrained areas
class Diamond4CsCompact extends StatelessWidget {
  final DiamondGrading? currentGrading;
  final VoidCallback onTap;

  const Diamond4CsCompact({
    super.key,
    required this.currentGrading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.diamond_outlined, size: 20, color: Color(0xFFD4AF37)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diamond Quality (4Cs)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentGrading != null
                        ? 'Color: ${currentGrading!.colorGrade} | Clarity: ${currentGrading!.clarityGrade} | Cut: ${currentGrading!.cutGrade}'
                        : 'Tap to select quality grades',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

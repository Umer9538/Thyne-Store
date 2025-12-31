import 'package:flutter/material.dart';

/// Widget for selecting stone carat weight
class CaratWeightSelector extends StatelessWidget {
  final List<double> availableWeights;
  final double? selectedWeight;
  final double? pricePerCarat;
  final Map<double, double>? caratPriceMultipliers;
  final ValueChanged<double> onWeightSelected;
  final bool showPriceImpact;

  const CaratWeightSelector({
    super.key,
    required this.availableWeights,
    required this.selectedWeight,
    this.pricePerCarat,
    this.caratPriceMultipliers,
    required this.onWeightSelected,
    this.showPriceImpact = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.scale_outlined, size: 18, color: Color(0xFF666666)),
              const SizedBox(width: 8),
              Text(
                'Carat Weight',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (selectedWeight != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${selectedWeight!.toStringAsFixed(2)} ct',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Weight options
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableWeights.map((weight) {
            final isSelected = weight == selectedWeight;
            final multiplier = caratPriceMultipliers?[weight] ?? 1.0;
            final estimatedPrice = pricePerCarat != null
                ? pricePerCarat! * weight * multiplier
                : null;

            return _CaratChip(
              weight: weight,
              isSelected: isSelected,
              estimatedPrice: estimatedPrice,
              multiplier: multiplier,
              showPriceImpact: showPriceImpact,
              onTap: () => onWeightSelected(weight),
            );
          }).toList(),
        ),

        // Size reference
        if (selectedWeight != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSizeReference(selectedWeight!),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getSizeReference(double carat) {
    // Approximate diameter for round brilliant cut
    final diameter = _getApproximateDiameter(carat);
    return 'Round cut: ~${diameter.toStringAsFixed(1)}mm diameter';
  }

  double _getApproximateDiameter(double carat) {
    // Approximate formula for round brilliant diamonds
    // Based on standard proportions
    if (carat <= 0.25) return 4.1;
    if (carat <= 0.50) return 5.2;
    if (carat <= 0.75) return 5.9;
    if (carat <= 1.00) return 6.5;
    if (carat <= 1.25) return 6.9;
    if (carat <= 1.50) return 7.4;
    if (carat <= 2.00) return 8.2;
    if (carat <= 2.50) return 8.8;
    if (carat <= 3.00) return 9.4;
    return 10.0 + ((carat - 3.0) * 0.5);
  }
}

class _CaratChip extends StatelessWidget {
  final double weight;
  final bool isSelected;
  final double? estimatedPrice;
  final double multiplier;
  final bool showPriceImpact;
  final VoidCallback onTap;

  const _CaratChip({
    required this.weight,
    required this.isSelected,
    this.estimatedPrice,
    required this.multiplier,
    required this.showPriceImpact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.white,
          borderRadius: BorderRadius.circular(8),
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
              '${weight.toStringAsFixed(2)} ct',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
            if (showPriceImpact && multiplier != 1.0) ...[
              const SizedBox(height: 2),
              Text(
                _formatMultiplier(multiplier),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : (multiplier > 1.0 ? Colors.orange[700] : Colors.green[700]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatMultiplier(double multiplier) {
    if (multiplier == 1.0) return '';
    if (multiplier > 1.0) {
      return '+${((multiplier - 1) * 100).toInt()}%';
    } else {
      return '-${((1 - multiplier) * 100).toInt()}%';
    }
  }
}

/// Compact dropdown version of carat selector
class CaratWeightDropdown extends StatelessWidget {
  final List<double> availableWeights;
  final double? selectedWeight;
  final ValueChanged<double> onWeightSelected;

  const CaratWeightDropdown({
    super.key,
    required this.availableWeights,
    required this.selectedWeight,
    required this.onWeightSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: selectedWeight ?? (availableWeights.isNotEmpty ? availableWeights.first : null),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4AF37)),
          items: availableWeights.map((weight) {
            return DropdownMenuItem(
              value: weight,
              child: Row(
                children: [
                  const Icon(Icons.diamond, size: 16, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 8),
                  Text(
                    '${weight.toStringAsFixed(2)} carat',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onWeightSelected(value);
            }
          },
        ),
      ),
    );
  }
}

/// Slider version of carat selector for continuous selection
class CaratWeightSlider extends StatelessWidget {
  final double minWeight;
  final double maxWeight;
  final double currentWeight;
  final double? pricePerCarat;
  final ValueChanged<double> onWeightChanged;

  const CaratWeightSlider({
    super.key,
    this.minWeight = 0.25,
    this.maxWeight = 3.0,
    required this.currentWeight,
    this.pricePerCarat,
    required this.onWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Carat Weight',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${currentWeight.toStringAsFixed(2)} ct',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFD4AF37),
            inactiveTrackColor: Colors.grey[200],
            thumbColor: const Color(0xFFD4AF37),
            overlayColor: const Color(0xFFD4AF37).withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: currentWeight.clamp(minWeight, maxWeight),
            min: minWeight,
            max: maxWeight,
            divisions: ((maxWeight - minWeight) * 4).toInt(),
            onChanged: (value) {
              // Round to nearest 0.25
              final rounded = (value * 4).round() / 4;
              onWeightChanged(rounded);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${minWeight.toStringAsFixed(2)} ct',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            Text(
              '${maxWeight.toStringAsFixed(2)} ct',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }
}

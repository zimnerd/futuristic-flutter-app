import 'package:flutter/material.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Widget for filtering streams by category
class StreamCategoryFilter extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategoryChanged;

  const StreamCategoryFilter({
    super.key,
    this.selectedCategory,
    required this.onCategoryChanged,
  });

  static const List<Map<String, dynamic>> categories = [
    {'id': null, 'name': 'All', 'icon': Icons.apps},
    {'id': 'dating', 'name': 'Dating', 'icon': Icons.favorite},
    {'id': 'lifestyle', 'name': 'Lifestyle', 'icon': Icons.style},
    {'id': 'cooking', 'name': 'Cooking', 'icon': Icons.restaurant},
    {'id': 'fitness', 'name': 'Fitness', 'icon': Icons.fitness_center},
    {'id': 'music', 'name': 'Music', 'icon': Icons.music_note},
    {'id': 'travel', 'name': 'Travel', 'icon': Icons.flight},
    {'id': 'gaming', 'name': 'Gaming', 'icon': Icons.videogame_asset},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onCategoryChanged(category['id']),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PulseColors.primary
                      : context.outlineColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: context.outlineColor.withValues(alpha: 0.3),
                        ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'],
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : context.onSurfaceVariantColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category['name'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : context.onSurfaceVariantColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

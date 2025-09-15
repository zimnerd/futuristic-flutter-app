import 'package:flutter/material.dart';
import '../../../domain/entities/event.dart';
import '../../theme/pulse_colors.dart';

class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? PulseColors.primary 
              : PulseColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: PulseColors.primary.withValues(
              alpha: isSelected ? 1.0 : 0.3,
            ),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(),
              size: 16,
              color: isSelected ? Colors.white : PulseColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              EventCategories.getDisplayName(category),
              style: TextStyle(
                color: isSelected ? Colors.white : PulseColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (category) {
      case EventCategories.music:
        return Icons.music_note;
      case EventCategories.sports:
        return Icons.sports_soccer;
      case EventCategories.food:
        return Icons.restaurant;
      case EventCategories.drinks:
        return Icons.local_bar;
      case EventCategories.culture:
        return Icons.palette;
      case EventCategories.outdoors:
        return Icons.nature;
      case EventCategories.networking:
        return Icons.people;
      case EventCategories.education:
        return Icons.school;
      case EventCategories.wellness:
        return Icons.spa;
      case EventCategories.social:
        return Icons.group;
      default:
        return Icons.event;
    }
  }
}

class CategoryFilterChips extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategoryFilterChips({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All categories chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onCategorySelected(null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selectedCategory == null 
                      ? PulseColors.primary 
                      : PulseColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: PulseColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'All',
                  style: TextStyle(
                    color: selectedCategory == null ? Colors.white : PulseColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          // Category chips
          ...EventCategories.all.map((category) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryChip(
              category: category,
              isSelected: selectedCategory == category,
              onTap: () => onCategorySelected(category),
            ),
          )),
        ],
      ),
    );
  }
}
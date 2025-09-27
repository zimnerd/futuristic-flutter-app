import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/event.dart';
import '../../theme/pulse_colors.dart';
import '../../blocs/event/event_bloc.dart';
import '../../blocs/event/event_event.dart';
import '../../blocs/event/event_state.dart';

class CategoryChip extends StatelessWidget {
  final EventCategory? category; // null for "All" categories
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    this.category,
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
              category?.name ?? 'All',
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
    if (category == null) return Icons.apps; // "All" categories icon

    // Use icon from API if available, otherwise fall back to slug-based mapping
    if (category!.icon != null && category!.icon!.isNotEmpty) {
      // TODO: Implement icon mapping from string to IconData if needed
      // For now, fall back to slug-based mapping
    }

    switch (category!.slug) {
      case 'music':
        return Icons.music_note;
      case 'sports':
        return Icons.sports_soccer;
      case 'food':
        return Icons.restaurant;
      case 'drinks':
        return Icons.local_bar;
      case 'culture':
        return Icons.palette;
      case 'outdoors':
        return Icons.nature;
      case 'networking':
        return Icons.people;
      case 'education':
        return Icons.school;
      case 'wellness':
        return Icons.spa;
      case 'social':
        return Icons.group;
      case 'nightlife':
        return Icons.nightlife;
      case 'art':
        return Icons.brush;
      case 'fitness':
        return Icons.fitness_center;
      case 'business':
        return Icons.business;
      case 'community':
        return Icons.group_work;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.health_and_safety;
      case 'hobbies':
        return Icons.palette;
      case 'learning':
        return Icons.menu_book;
      case 'outdoor':
        return Icons.park;
      case 'photography':
        return Icons.camera_alt;
      case 'technology':
        return Icons.computer;
      case 'travel':
        return Icons.travel_explore;
      default:
        return Icons.event;
    }
  }
}

class CategoryFilterChips extends StatefulWidget {
  final String? selectedCategorySlug;
  final Function(String?) onCategorySelected;

  const CategoryFilterChips({
    super.key,
    this.selectedCategorySlug,
    required this.onCategorySelected,
  });

  @override
  State<CategoryFilterChips> createState() => _CategoryFilterChipsState();
}

class _CategoryFilterChipsState extends State<CategoryFilterChips> {
  @override
  void initState() {
    super.initState();
    // Load categories when widget initializes
    context.read<EventBloc>().add(const LoadEventCategories());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventBloc, EventState>(
      buildWhen: (previous, current) =>
          current is EventCategoriesLoaded ||
          current is EventLoading ||
          current is EventError,
      builder: (context, state) {
        if (state is EventLoading) {
          return Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (state is EventError) {
          // Fall back to legacy categories on error
          return _buildLegacyCategoryChips();
        }

        if (state is EventCategoriesLoaded) {
          return _buildApiCategoryChips(state.categories);
        }

        // Default to legacy categories
        return _buildLegacyCategoryChips();
      },
    );
  }

  Widget _buildApiCategoryChips(List<EventCategory> categories) {
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
            child: CategoryChip(
              category: null, // null represents "All"
              isSelected: widget.selectedCategorySlug == null,
              onTap: () => widget.onCategorySelected(null),
            ),
          ),
          // API Category chips
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CategoryChip(
                category: category,
                isSelected: widget.selectedCategorySlug == category.slug,
                onTap: () => widget.onCategorySelected(category.slug),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyCategoryChips() {
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
            child: CategoryChip(
              category: null,
              isSelected: widget.selectedCategorySlug == null,
              onTap: () => widget.onCategorySelected(null),
            ),
          ),
          // Legacy Category chips
          ...EventCategories.all.map(
            (categorySlug) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryChip(
                category: EventCategory(
                  id: 'legacy-$categorySlug',
                  name: EventCategories.getDisplayName(categorySlug),
                  slug: categorySlug,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
                isSelected: widget.selectedCategorySlug == categorySlug,
                onTap: () => widget.onCategorySelected(categorySlug),
            ),
          )),
        ],
      ),
    );
  }
}
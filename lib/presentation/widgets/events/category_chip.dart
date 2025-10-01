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
              _getCategoryDisplayText(),
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

  String _getCategoryDisplayText() {
    if (category == null)
      return 'All'; // Don't show count for "All" to keep it simple

    // Show event count if available (only show count if > 0)
    final count = category!.eventCount;
    if (count > 0) {
      return '${category!.name} ($count)';
    }

    return category!.name;
  }

  IconData _getCategoryIcon() {
    if (category == null) return Icons.apps; // "All" categories icon

    // Use icon from API if available, otherwise fall back to slug-based mapping
    if (category!.icon != null && category!.icon!.isNotEmpty) {
      return _mapStringToIcon(category!.icon!);
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

  /// Map string icon names from backend to Material IconData
  IconData _mapStringToIcon(String iconName) {
    // Normalize icon name (remove spaces, convert to lowercase)
    final normalized = iconName.toLowerCase().replaceAll(' ', '_');
    
    // Comprehensive icon mapping
    final iconMap = <String, IconData>{
      // Common event icons
      'music': Icons.music_note,
      'music_note': Icons.music_note,
      'sports': Icons.sports_soccer,
      'soccer': Icons.sports_soccer,
      'food': Icons.restaurant,
      'restaurant': Icons.restaurant,
      'dining': Icons.dining,
      'drinks': Icons.local_bar,
      'bar': Icons.local_bar,
      'coffee': Icons.local_cafe,
      'culture': Icons.palette,
      'art': Icons.brush,
      'palette': Icons.palette,
      'outdoors': Icons.nature,
      'nature': Icons.park,
      'park': Icons.park,
      'networking': Icons.people,
      'people': Icons.group,
      'group': Icons.group,
      'education': Icons.school,
      'school': Icons.school,
      'learning': Icons.menu_book,
      'book': Icons.menu_book,
      'wellness': Icons.spa,
      'spa': Icons.spa,
      'social': Icons.group,
      'nightlife': Icons.nightlife,
      'night': Icons.nightlife,
      'fitness': Icons.fitness_center,
      'gym': Icons.fitness_center,
      'business': Icons.business,
      'work': Icons.work,
      'community': Icons.group_work,
      'entertainment': Icons.movie,
      'movie': Icons.movie,
      'film': Icons.movie,
      'health': Icons.health_and_safety,
      'medical': Icons.medical_services,
      'hobbies': Icons.palette,
      'outdoor': Icons.park,
      'photography': Icons.camera_alt,
      'camera': Icons.camera_alt,
      'technology': Icons.computer,
      'tech': Icons.computer,
      'computer': Icons.computer,
      'travel': Icons.travel_explore,
      'explore': Icons.explore,
      'gaming': Icons.sports_esports,
      'games': Icons.videogame_asset,
      'theater': Icons.theater_comedy,
      'comedy': Icons.theater_comedy,
      'dance': Icons.music_note,
      'volunteer': Icons.volunteer_activism,
      'charity': Icons.volunteer_activism,
      'festival': Icons.celebration,
      'celebration': Icons.celebration,
      'party': Icons.celebration,
      'workshop': Icons.construction,
      'class': Icons.school,
      'lecture': Icons.school,
      'conference': Icons.business_center,
      'meetup': Icons.people,
      'concert': Icons.music_note,
      'exhibition': Icons.museum,
      'museum': Icons.museum,
      'cooking': Icons.restaurant_menu,
      'wine': Icons.wine_bar,
      'beer': Icons.sports_bar,
      'hiking': Icons.hiking,
      'running': Icons.directions_run,
      'cycling': Icons.directions_bike,
      'yoga': Icons.self_improvement,
      'meditation': Icons.self_improvement,
      'reading': Icons.menu_book,
      'writing': Icons.edit,
      'speaking': Icons.mic,
      'karaoke': Icons.mic,
      'trivia': Icons.quiz,
      'quiz': Icons.quiz,
      'shopping': Icons.shopping_bag,
      'market': Icons.storefront,
      'craft': Icons.color_lens,
      'diy': Icons.handyman,
    };
    
    return iconMap[normalized] ?? Icons.event;
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
  List<EventCategory>? _categories;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    // Load categories using EventBloc but maintain our own state
    context.read<EventBloc>().add(
      LoadEventCategories(forceRefresh: forceRefresh),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EventBloc, EventState>(
      listenWhen: (previous, current) =>
          current is EventCategoriesLoaded ||
          current is EventError,
      listener: (context, state) {
        if (state is EventCategoriesLoaded) {
          setState(() {
            _categories = state.categories;
            _isLoading = false;
          });
        } else if (state is EventError && _categories == null) {
          // Only show error if we don't have cached categories
          setState(() {
            _isLoading = false;
          });
        }
      },
      child: _buildCategoryChips(),
    );
  }

  Widget _buildCategoryChips() {
    if (_isLoading && _categories == null) {
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

    if (_categories != null) {
      return _buildApiCategoryChips(_categories!);
    }

    // Fall back to legacy categories if no API categories loaded
    return _buildLegacyCategoryChips();
  }

  Widget _buildApiCategoryChips(List<EventCategory> categories) {
    // Filter out categories with 0 events for better UX
    final categoriesWithEvents = categories
        .where((cat) => cat.eventCount > 0)
        .toList();
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Reload button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                _loadCategories(forceRefresh: true);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.grey,
                          ),
                    const SizedBox(width: 4),
                    const Text(
                      'Reload',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // All categories chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryChip(
              category: null, // null represents "All"
              isSelected: widget.selectedCategorySlug == null,
              onTap: () => widget.onCategorySelected(null),
            ),
          ),
          // API Category chips (only show categories with events > 0)
          ...categoriesWithEvents.map(
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
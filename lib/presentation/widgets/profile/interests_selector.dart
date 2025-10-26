import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/interest.dart';
import '../../../data/repositories/interests_repository.dart';
import '../../blocs/interests/interests_bloc.dart';
import '../../blocs/interests/interests_event.dart';
import '../../blocs/interests/interests_state.dart';
import '../../theme/pulse_colors.dart';

/// Enhanced interests selector with API integration
class InterestsSelector extends StatefulWidget {
  final List<Interest> selectedInterests;
  final Function(List<Interest>) onInterestsChanged;
  final int maxInterests;
  final int minInterests;

  const InterestsSelector({
    super.key,
    required this.selectedInterests,
    required this.onInterestsChanged,
    this.maxInterests = 10,
    this.minInterests = 3,
  });

  @override
  State<InterestsSelector> createState() => _InterestsSelectorState();
}

class _InterestsSelectorState extends State<InterestsSelector>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  late List<Interest> _selectedInterests = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedInterests = List.from(widget.selectedInterests);
    debugPrint(
      '🎯 InterestsSelector.initState: selectedInterests.length=${widget.selectedInterests.length}',
    );
    if (widget.selectedInterests.isNotEmpty) {
      debugPrint(
        '🎯 First interest in initState: id=${widget.selectedInterests.first.id}, name=${widget.selectedInterests.first.name}',
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InterestsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected interests if the parent widget provides new ones
    debugPrint(
      '🔄 didUpdateWidget: old=${oldWidget.selectedInterests.length}, new=${widget.selectedInterests.length}',
    );
    if (oldWidget.selectedInterests != widget.selectedInterests ||
        oldWidget.selectedInterests.length != widget.selectedInterests.length) {
      debugPrint('✅ Updating interests in InterestsSelector');
      setState(() {
        _selectedInterests = List.from(widget.selectedInterests);
      });
    }
  }

  void _toggleInterest(Interest interest) {
    setState(() {
      // Check if already selected by comparing IDs
      final index = _selectedInterests.indexWhere((i) => i.id == interest.id);

      if (index >= 0) {
        // Already selected, remove it
        _selectedInterests.removeAt(index);
      } else if (_selectedInterests.length < widget.maxInterests) {
        // Not selected and under limit, add it
        _selectedInterests.add(interest);
      } else {
        _showMaxInterestsReachedDialog();
        return;
      }
    });
    widget.onInterestsChanged(_selectedInterests);
  }

  void _showMaxInterestsReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Maximum Interests Reached',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You can select up to ${widget.maxInterests} interests.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Interest> _getFilteredInterests(List<Interest> interests) {
    if (_searchQuery.isEmpty) return interests;
    return interests
        .where(
          (interest) =>
              interest.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          InterestsBloc(repository: InterestsRepository())
            ..add(const LoadInterests()),
      child: BlocBuilder<InterestsBloc, InterestsState>(
        builder: (context, state) {
          if (state is InterestsLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    PulseColors.primary,
                  ),
                ),
              ),
            );
          }

          if (state is InterestsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load interests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<InterestsBloc>().add(
                        const RefreshInterests(),
                      );
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is InterestsLoaded) {
            final categories = state.categories;

            // Initialize tab controller with loaded data
            if (_tabController == null ||
                _tabController!.length != categories.length) {
              _tabController?.dispose();
              _tabController = TabController(
                length: categories.length,
                vsync: this,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Interests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedInterests.length}/${widget.maxInterests}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select at least ${widget.minInterests} interests that represent you',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search interests...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Selected interests (if any)
                if (_selectedInterests.isNotEmpty) ...[
                  Text(
                    'Selected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedInterests.map((interest) {
                      return _buildSelectedInterestChip(interest);
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Category tabs
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicator: BoxDecoration(
                      color: PulseColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    tabs: categories.map((category) {
                      return Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(category.name),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Interests grid
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: categories.map((category) {
                      // Pass full Interest objects, not just names
                      final interests = _getFilteredInterests(
                        category.interests,
                      );

                      if (interests.isEmpty && _searchQuery.isNotEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No interests found for "$_searchQuery"',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 3.5,
                            ),
                        itemCount: interests.length,
                        itemBuilder: (context, index) {
                          final interest = interests[index];
                          // Check if selected by ID comparison
                          final isSelected = _selectedInterests.any(
                            (i) => i.id == interest.id,
                          );
                          
                          // Debug all interests at the beginning
                          if (index == 0 && _selectedInterests.isNotEmpty) {
                            debugPrint(
                              '\n📊 INTEREST MATCHING DEBUG FOR THIS TAB:',
                            );
                            debugPrint(
                              '📋 _selectedInterests count: ${_selectedInterests.length}',
                            );
                            debugPrint(
                              '📋 Selected Interests IDs: ${_selectedInterests.map((i) => i.id).join(", ")}',
                            );
                            debugPrint(
                              '📋 Selected Interests Names: ${_selectedInterests.map((i) => i.name).join(", ")}',
                            );
                            debugPrint(
                              '📋 Current Tab has ${interests.length} interests',
                            );
                            debugPrint('---');
                          }

                          // Debug: Show ID comparison for each interest
                          debugPrint(
                            '🔍 Interest #$index: name="${interest.name}", id="${interest.id}", selected=$isSelected',
                          );
                          if (isSelected) {
                            debugPrint(
                              '  ✅ MATCHED! This interest IS in _selectedInterests',
                            );
                          } else if (_selectedInterests.length > 0) {
                            // Check if we can find it by name instead
                            final byName = _selectedInterests
                                .where((i) => i.name == interest.name)
                                .toList();
                            if (byName.isNotEmpty) {
                              debugPrint(
                                '  ⚠️ FOUND BY NAME! Name="${byName.first.name}" but ID mismatch! Saved=${byName.first.id}, Category=${interest.id}',
                              );
                            } else {
                              debugPrint(
                                '  ❌ Not selected. ID "${interest.id}" not in saved: ${_selectedInterests.map((i) => i.id).toList()}',
                              );
                            }
                          }
                          return _buildInterestChip(interest, isSelected);
                        },
                      );
                    }).toList(),
                  ),
                ),

                // Bottom info
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PulseColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PulseColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: PulseColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your interests help us find better matches and show you to people with similar hobbies.',
                          style: TextStyle(
                            fontSize: 13,
                            color: PulseColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInterestChip(Interest interest, bool isSelected) {
    return InkWell(
      onTap: () => _toggleInterest(interest),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? PulseColors.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? PulseColors.primary
                : Theme.of(context).colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                interest.name,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedInterestChip(Interest interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [PulseColors.primary, PulseColors.secondary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            interest.name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _toggleInterest(interest),
            child: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}

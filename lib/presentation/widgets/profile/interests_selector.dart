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
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
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
        backgroundColor: Colors.white,
        title: const Text(
          'Maximum Interests Reached',
          style: TextStyle(
            color: Color(0xFF202124), // Dark text color
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You can select up to ${widget.maxInterests} interests.',
          style: const TextStyle(
            color: Color(0xFF5F6368), // Medium gray text
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF6E3BFF), // Primary purple
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
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load interests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<InterestsBloc>().add(
                        const RefreshInterests(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      foregroundColor: Colors.white,
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
                    const Text(
                      'Interests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedInterests.length}/${widget.maxInterests}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select at least ${widget.minInterests} interests that represent you',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
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
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
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
                  const Text(
                    'Selected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
                    color: Colors.grey[50],
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
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
                                color: Colors.grey[400],
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No interests found for "$_searchQuery"',
                                style: TextStyle(
                                  color: Colors.grey[600],
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
          color: isSelected ? PulseColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? PulseColors.primary : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                interest.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: Colors.white, size: 16),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _toggleInterest(interest),
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }
}

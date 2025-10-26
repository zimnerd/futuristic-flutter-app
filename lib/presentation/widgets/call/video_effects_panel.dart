import 'package:flutter/material.dart';
import '../../../data/services/video_effects_service.dart';
import '../../theme/pulse_colors.dart';
import '../common/robust_network_image.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Video Effects Panel for managing filters and virtual backgrounds during calls
class VideoEffectsPanel extends StatefulWidget {
  final String callId;
  final VoidCallback? onClose;
  final Function(String message)? onError;

  const VideoEffectsPanel({
    super.key,
    required this.callId,
    this.onClose,
    this.onError,
  });

  @override
  State<VideoEffectsPanel> createState() => _VideoEffectsPanelState();
}

class _VideoEffectsPanelState extends State<VideoEffectsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VideoEffectsService _effectsService = VideoEffectsService.instance;

  List<VirtualBackground> _backgrounds = [];
  List<CameraFilter> _filters = [];
  String? _selectedBackgroundId;
  String? _selectedFilterId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEffectsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEffectsData() async {
    setState(() => _isLoading = true);

    try {
      // Load virtual backgrounds from server
      final backgrounds = await _effectsService.getVirtualBackgrounds();

      // Get available filters
      final filters = _effectsService.getAvailableFilters();

      setState(() {
        _backgrounds = backgrounds;
        _filters = filters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      widget.onError?.call('Failed to load video effects: $e');
    }
  }

  Future<void> _applyVirtualBackground(VirtualBackground background) async {
    setState(() => _isLoading = true);

    try {
      final success = await _effectsService.applyVirtualBackground(
        callId: widget.callId,
        backgroundId: background.id,
        backgroundUrl: background.url,
        blurIntensity: background.type == 'blur' ? 0.8 : 0.0,
      );

      if (success) {
        setState(() => _selectedBackgroundId = background.id);
      } else {
        widget.onError?.call('Failed to apply virtual background');
      }
    } catch (e) {
      widget.onError?.call('Error applying virtual background: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeVirtualBackground() async {
    setState(() => _isLoading = true);

    try {
      final success = await _effectsService.removeVirtualBackground(
        widget.callId,
      );

      if (success) {
        setState(() => _selectedBackgroundId = null);
      } else {
        widget.onError?.call('Failed to remove virtual background');
      }
    } catch (e) {
      widget.onError?.call('Error removing virtual background: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyCameraFilter(CameraFilter filter) async {
    setState(() => _isLoading = true);

    try {
      final success = await _effectsService.applyCameraFilter(
        callId: widget.callId,
        filterType: filter.id,
        settings: filter.settings,
      );

      if (success) {
        setState(() => _selectedFilterId = filter.id);
      } else {
        widget.onError?.call('Failed to apply camera filter');
      }
    } catch (e) {
      widget.onError?.call('Error applying camera filter: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeCameraFilter() async {
    if (_selectedFilterId == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await _effectsService.removeCameraFilter(
        callId: widget.callId,
        filterType: _selectedFilterId!,
      );

      if (success) {
        setState(() => _selectedFilterId = null);
      } else {
        widget.onError?.call('Failed to remove camera filter');
      }
    } catch (e) {
      widget.onError?.call('Error removing camera filter: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.video_call,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? PulseColors.primary
                      : PulseColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Video Effects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: PulseColors.primary,
              labelStyle: TextStyle(color: PulseColors.primary),
              unselectedLabelStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.wallpaper), text: 'Backgrounds'),
                Tab(icon: Icon(Icons.filter), text: 'Filters'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [_buildBackgroundsTab(), _buildFiltersTab()],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Remove Background Option
          _buildBackgroundTile(
            title: 'No Background',
            subtitle: 'Show your real environment',
            isSelected: _selectedBackgroundId == null,
            onTap: _removeVirtualBackground,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.no_photography, size: 30),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Virtual Backgrounds',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Backgrounds Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _backgrounds.length,
              itemBuilder: (context, index) {
                final background = _backgrounds[index];
                return _buildBackgroundItem(background);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Remove Filter Option
          _buildFilterTile(
            title: 'No Filter',
            subtitle: 'Original camera feed',
            icon: '📷',
            isSelected: _selectedFilterId == null,
            onTap: _removeCameraFilter,
          ),

          const SizedBox(height: 16),
          Text(
            'Camera Filters',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Filters List
          Expanded(
            child: ListView.builder(
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                return _buildFilterTile(
                  title: filter.name,
                  subtitle: filter.description,
                  icon: filter.icon,
                  isPremium: filter.isPremium,
                  isSelected: _selectedFilterId == filter.id,
                  onTap: () => _applyCameraFilter(filter),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? PulseColors.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            child,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: PulseColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundItem(VirtualBackground background) {
    final isSelected = _selectedBackgroundId == background.id;

    return InkWell(
      onTap: () => _applyVirtualBackground(background),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? PulseColors.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Background Image/Video
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: background.thumbnail != null
                  ? RobustNetworkImage(
                      imageUrl: background.thumbnail!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Theme.of(context).cardColor,
                      child: Icon(Icons.blur_on, size: 30),
                    ),
            ),

            // Selection Overlay
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: PulseColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle,
                      color: PulseColors.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),

            // Premium Badge
            if (background.isPremium)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: context.onSurfaceColor,
                    ),
                  ),
                ),
              ),

            // Background Name
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  background.name,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.onSurfaceColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTile({
    required String title,
    required String subtitle,
    required String icon,
    bool isPremium = false,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? PulseColors.primary
                  : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Filter Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(icon, style: TextStyle(fontSize: 24)),
                ),
              ),

              const SizedBox(width: 16),

              // Filter Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: context.onSurfaceColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection Indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: PulseColors.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../data/models/virtual_gift.dart';
import '../../theme/pulse_colors.dart';

/// Widget for displaying the gift catalog with categories and purchase options
class GiftCatalogWidget extends StatefulWidget {
  final List<VirtualGift> gifts;
  final int userBalance;
  final Function(VirtualGift) onGiftSelected;
  final VoidCallback onPurchaseCredits;

  const GiftCatalogWidget({
    super.key,
    required this.gifts,
    required this.userBalance,
    required this.onGiftSelected,
    required this.onPurchaseCredits,
  });

  @override
  State<GiftCatalogWidget> createState() => _GiftCatalogWidgetState();
}

class _GiftCatalogWidgetState extends State<GiftCatalogWidget> {
  GiftCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final filteredGifts = _selectedCategory == null
        ? widget.gifts
        : widget.gifts.where((gift) => gift.category == _selectedCategory).toList();

    return Column(
      children: [
        _buildHeader(),
        _buildCategoryFilter(),
        Expanded(
          child: _buildGiftGrid(filteredGifts),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PulseColors.primary.withOpacity(0.1),
            PulseColors.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gift Catalog',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Send meaningful gifts to your matches',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, color: Colors.amber[700], size: 20),
                const SizedBox(width: 4),
                Text(
                  '${widget.userBalance}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'credits',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: widget.onPurchaseCredits,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Buy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip('All', null),
          ...GiftCategory.values.map((category) =>
              _buildCategoryChip(_getCategoryName(category), category)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, GiftCategory? category) {
    final isSelected = _selectedCategory == category;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: PulseColors.primary.withOpacity(0.2),
        checkmarkColor: PulseColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? PulseColors.primary : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildGiftGrid(List<VirtualGift> gifts) {
    if (gifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No gifts in this category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        return _buildGiftCard(gift);
      },
    );
  }

  Widget _buildGiftCard(VirtualGift gift) {
    final canAfford = widget.userBalance >= gift.price;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: canAfford ? () => widget.onGiftSelected(gift) : null,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Gift Icon/Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCategoryColor(gift.category).withOpacity(0.1),
                      _getCategoryColor(gift.category).withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: gift.iconUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          gift.iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildGiftIcon(gift),
                        ),
                      )
                    : _buildGiftIcon(gift),
              ),
            ),
            
            // Gift Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gift.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gift.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: canAfford 
                                ? Colors.green[50] 
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: canAfford 
                                  ? Colors.green[300]! 
                                  : Colors.red[300]!,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars,
                                size: 14,
                                color: canAfford 
                                    ? Colors.green[700] 
                                    : Colors.red[700],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${gift.price}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford 
                                      ? Colors.green[700] 
                                      : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!canAfford)
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftIcon(VirtualGift gift) {
    return Center(
      child: Icon(
        _getCategoryIcon(gift.category),
        size: 48,
        color: _getCategoryColor(gift.category),
      ),
    );
  }

  String _getCategoryName(GiftCategory category) {
    return category.displayName;
  }

  Color _getCategoryColor(GiftCategory category) {
    switch (category) {
      case GiftCategory.flowers:
        return Colors.pink;
      case GiftCategory.drinks:
        return Colors.blue;
      case GiftCategory.activities:
        return Colors.green;
      case GiftCategory.premium:
        return Colors.purple;
      case GiftCategory.seasonal:
        return Colors.orange;
      case GiftCategory.romantic:
        return Colors.red;
    }
  }

  IconData _getCategoryIcon(GiftCategory category) {
    switch (category) {
      case GiftCategory.flowers:
        return Icons.local_florist;
      case GiftCategory.drinks:
        return Icons.local_bar;
      case GiftCategory.activities:
        return Icons.celebration;
      case GiftCategory.premium:
        return Icons.diamond;
      case GiftCategory.seasonal:
        return Icons.ac_unit;
      case GiftCategory.romantic:
        return Icons.favorite;
    }
  }
}

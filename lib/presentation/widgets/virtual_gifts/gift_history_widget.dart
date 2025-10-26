import 'package:flutter/material.dart';

import '../../../data/models/virtual_gift.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Widget for displaying gift transaction history
class GiftHistoryWidget extends StatefulWidget {
  final List<GiftTransaction> transactions;
  final String currentUserId; // Need this to determine sent vs received
  final bool isLoading;
  final String? error;
  final VoidCallback? onRefresh;

  const GiftHistoryWidget({
    super.key,
    required this.transactions,
    required this.currentUserId,
    this.isLoading = false,
    this.error,
    this.onRefresh,
  });

  @override
  State<GiftHistoryWidget> createState() => _GiftHistoryWidgetState();
}

class _GiftHistoryWidgetState extends State<GiftHistoryWidget> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    if (widget.error != null) {
      return _buildErrorState();
    }

    if (widget.isLoading) {
      return _buildLoadingState();
    }

    final filteredTransactions = _getFilteredTransactions();

    if (filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildHeader(),
        _buildFilterTabs(),
        Expanded(child: _buildTransactionList(filteredTransactions)),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PulseColors.primary.withValues(alpha: 0.1),
            PulseColors.primary.withValues(alpha: 0.05),
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
                  'Gift History',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your sent and received gifts',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(
                    color: context.onSurfaceVariantColor,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onRefresh != null)
            IconButton(
              onPressed: widget.onRefresh,
              icon: Icon(Icons.refresh),
              style: IconButton.styleFrom(
                backgroundColor: context.surfaceColor,
                foregroundColor: PulseColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'All', 'icon': Icons.all_inclusive},
      {'key': 'sent', 'label': 'Sent', 'icon': Icons.send},
      {'key': 'received', 'label': 'Received', 'icon': Icons.call_received},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                filter['icon'] as IconData,
                size: 18,
                color: isSelected
                    ? PulseColors.primary
                    : context.onSurfaceVariantColor,
              ),
              label: Text(filter['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['key'] as String;
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: PulseColors.primary.withValues(alpha: 0.2),
              checkmarkColor: PulseColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? PulseColors.primary
                    : context.onSurfaceVariantColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionList(List<GiftTransaction> transactions) {
    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh?.call();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return _buildTransactionCard(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionCard(GiftTransaction transaction) {
    // Determine if current user sent or received this gift
    final isSent = transaction.senderId == widget.currentUserId;
    final gift = transaction.gift;

    if (gift == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Gift Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _getCategoryColor(gift.category).withValues(alpha: 0.1),
              ),
              child: gift.iconUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        gift.iconUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildGiftIcon(gift),
                      ),
                    )
                  : _buildGiftIcon(gift),
            ),
            const SizedBox(width: 16),

            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          gift.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSent ? Colors.blue[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSent
                                ? Colors.blue[300]!
                                : Colors.green[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSent ? Icons.send : Icons.call_received,
                              size: 12,
                              color: isSent
                                  ? Colors.blue[700]
                                  : Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSent ? 'Sent' : 'Received',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSent
                                    ? Colors.blue[700]
                                    : Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSent
                        ? 'To ${transaction.receiverName ?? 'Unknown'}'
                        : 'From ${transaction.senderName ?? 'Unknown'}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(
                      color: context.onSurfaceVariantColor,
                    ),
                  ),
                  if (transaction.message != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.outlineColor.withValues(alpha: 0.15)!,
                        ),
                      ),
                      child: Text(
                        '"${transaction.message}"',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: context.onSurfaceVariantColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(transaction.sentAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.onSurfaceVariantColor.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.stars, size: 14, color: Colors.amber[700]),
                          const SizedBox(width: 2),
                          Text(
                            '${gift.price}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
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
        size: 32,
        color: _getCategoryColor(gift.category),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 64,
            color: context.outlineColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No gift history',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(
              color: context.onSurfaceVariantColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start sending gifts to see them here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(
              color: context.onSurfaceVariantColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: context.errorColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading gift history',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(
              color: context.errorColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.error ?? 'Unknown error occurred',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(
              color: context.onSurfaceVariantColor.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (widget.onRefresh != null)
            ElevatedButton(
              onPressed: widget.onRefresh,
              child: Text('Retry'),
            ),
        ],
      ),
    );
  }

  List<GiftTransaction> _getFilteredTransactions() {
    switch (_selectedFilter) {
      case 'sent':
        return widget.transactions
            .where((t) => t.senderId == widget.currentUserId)
            .toList();
      case 'received':
        return widget.transactions
            .where((t) => t.receiverId == widget.currentUserId)
            .toList();
      default:
        return widget.transactions;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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

import 'package:flutter/material.dart';

import '../../../data/models/virtual_gift.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Widget for confirming and completing gift purchases
class GiftPurchaseWidget extends StatefulWidget {
  final VirtualGift gift;
  final int userBalance;
  final String recipientName;
  final String? message;
  final Function(VirtualGift, String?) onConfirmPurchase;
  final VoidCallback onCancel;

  const GiftPurchaseWidget({
    super.key,
    required this.gift,
    required this.userBalance,
    required this.recipientName,
    this.message,
    required this.onConfirmPurchase,
    required this.onCancel,
  });

  @override
  State<GiftPurchaseWidget> createState() => _GiftPurchaseWidgetState();
}

class _GiftPurchaseWidgetState extends State<GiftPurchaseWidget> {
  final TextEditingController _messageController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _messageController.text = widget.message ?? '';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = widget.userBalance >= widget.gift.price;

    return Container(
      decoration: BoxDecoration(
        color: context.onSurfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -4),
            blurRadius: 20,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildGiftPreview(),
          _buildMessageInput(),
          _buildCostBreakdown(),
          _buildActionButtons(canAfford),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Gift',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'To ${widget.recipientName}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(
                    color: context.onSurfaceVariantColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: Icon(Icons.close),
            style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCategoryColor(widget.gift.category).withValues(alpha: 0.1),
            _getCategoryColor(widget.gift.category).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.outlineColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: context.onSurfaceColor,
            ),
            child: widget.gift.iconUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.gift.iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildGiftIcon(),
                    ),
                  )
                : _buildGiftIcon(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.gift.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.gift.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(
                    color: context.onSurfaceVariantColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRarityColor(
                      widget.gift.rarity,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getRarityColor(widget.gift.rarity),
                    ),
                  ),
                  child: Text(
                    widget.gift.rarity.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getRarityColor(widget.gift.rarity),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftIcon() {
    return Center(
      child: Icon(
        _getCategoryIcon(widget.gift.category),
        size: 40,
        color: _getCategoryColor(widget.gift.category),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a personal message (optional)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Write something sweet...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: context.outlineColor.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: PulseColors.primary),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdown() {
    final canAfford = widget.userBalance >= widget.gift.price;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canAfford ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canAfford ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gift Cost:', style: Theme.of(context).textTheme.bodyLarge),
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    size: 20,
                    color: canAfford ? Colors.green[700] : Colors.red[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.gift.price}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: canAfford ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Balance:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${widget.userBalance}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'After Purchase:',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '${widget.userBalance - widget.gift.price}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: canAfford ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          if (!canAfford) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: context.errorColor.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Insufficient balance. You need ${widget.gift.price - widget.userBalance} more credits.',
                      style: TextStyle(
                        color: context.errorColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool canAfford) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing ? null : widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canAfford && !_isProcessing
                  ? _handleConfirmPurchase
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: PulseColors.primary,
                foregroundColor: context.onSurfaceColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      canAfford ? 'Send Gift' : 'Insufficient Credits',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleConfirmPurchase() {
    setState(() {
      _isProcessing = true;
    });

    // Simulate processing delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        widget.onConfirmPurchase(
          widget.gift,
          _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
        );
      }
    });
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

  Color _getRarityColor(GiftRarity rarity) {
    return Color(rarity.colorValue);
  }
}

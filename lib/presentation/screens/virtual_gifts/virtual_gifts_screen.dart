import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/virtual_gift.dart';
import '../../blocs/virtual_gift/virtual_gift_bloc.dart';
import '../../blocs/virtual_gift/virtual_gift_event.dart';
import '../../blocs/virtual_gift/virtual_gift_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/pulse_colors.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/virtual_gifts/gift_catalog_widget.dart';
import '../../widgets/virtual_gifts/gift_history_widget.dart';

/// Main screen for virtual gifts functionality
class VirtualGiftsScreen extends StatefulWidget {
  final String? recipientId;
  final String? recipientName;

  const VirtualGiftsScreen({super.key, this.recipientId, this.recipientName});

  @override
  State<VirtualGiftsScreen> createState() => _VirtualGiftsScreenState();
}

class _VirtualGiftsScreenState extends State<VirtualGiftsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Gets the current user ID from the AuthBloc state
  String? get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<VirtualGiftBloc>().add(LoadGiftCatalog());
    context.read<VirtualGiftBloc>().add(LoadReceivedGifts());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: widget.recipientName != null
            ? Text('Send Gift to ${widget.recipientName}')
            : const Text('Virtual Gifts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).primaryColor,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PulseColors.primary.withValues(alpha: 0.1),
                PulseColors.secondary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: widget.recipientId == null
            ? TabBar(
                controller: _tabController,
                labelColor: PulseColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: PulseColors.primary,
                tabs: const [
                  Tab(icon: Icon(Icons.card_giftcard), text: 'Send Gifts'),
                  Tab(icon: Icon(Icons.history), text: 'Gift History'),
                ],
              )
            : null,
      ),
      body: BlocConsumer<VirtualGiftBloc, VirtualGiftState>(
        listener: (context, state) {
          if (state.status == VirtualGiftStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.status == VirtualGiftStatus.sent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gift sent successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            if (widget.recipientId != null) {
              Navigator.of(context).pop();
            }
          }
        },
        builder: (context, state) {
          if (state.status == VirtualGiftStatus.loading &&
              state.catalog.isEmpty) {
            return const Center(child: PulseLoadingWidget());
          }

          if (state.status == VirtualGiftStatus.error &&
              state.catalog.isEmpty) {
            return PulseErrorWidget(
              message: state.errorMessage ?? 'Failed to load gifts',
              onRetry: () {
                context.read<VirtualGiftBloc>().add(LoadGiftCatalog());
              },
            );
          }

          return widget.recipientId != null
              ? _buildGiftSendingInterface(state)
              : _buildMainInterface(state);
        },
      ),
    );
  }

  Widget _buildMainInterface(VirtualGiftState state) {
    return TabBarView(
      controller: _tabController,
      children: [_buildGiftCatalogTab(state), _buildGiftHistoryTab(state)],
    );
  }

  Widget _buildGiftSendingInterface(VirtualGiftState state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PulseColors.primary.withValues(alpha: 0.1),
                PulseColors.secondary.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.favorite, color: PulseColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Choose a special gift for ${widget.recipientName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: PulseColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildGiftCatalogTab(state)),
      ],
    );
  }

  Widget _buildGiftCatalogTab(VirtualGiftState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GiftCatalogWidget(
        gifts: state.catalog,
        userBalance: state.userStats?.credits ?? 0,
        onGiftSelected: (gift) => _handleGiftSelection(gift),
        onPurchaseCredits: () => _handlePurchaseCredits(),
      ),
    );
  }

  Widget _buildGiftHistoryTab(VirtualGiftState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GiftHistoryWidget(
        transactions: [...state.sentGifts, ...state.receivedGifts],
        currentUserId: _currentUserId ?? 'fallback-user-id',
        isLoading: state.status == VirtualGiftStatus.loading,
        error: state.errorMessage,
        onRefresh: () {
          context.read<VirtualGiftBloc>().add(LoadReceivedGifts());
          context.read<VirtualGiftBloc>().add(LoadSentGifts());
        },
      ),
    );
  }

  void _handleGiftSelection(VirtualGift gift) {
    if (widget.recipientId != null) {
      _showGiftConfirmationDialog(gift);
    } else {
      _navigateToGiftSending(gift);
    }
  }

  void _showGiftConfirmationDialog(VirtualGift gift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Gift?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: Icon(
                Icons.card_giftcard,
                size: 40,
                color: PulseColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Send "${gift.name}" to ${widget.recipientName}?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Cost: ${gift.price} coins',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: PulseColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<VirtualGiftBloc>().add(
                SendGift(giftId: gift.id, recipientId: widget.recipientId!),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Gift'),
          ),
        ],
      ),
    );
  }

  void _navigateToGiftSending(VirtualGift gift) {
    Navigator.of(
      context,
    ).pushNamed('/select-recipient', arguments: {'gift': gift});
  }

  void _handlePurchaseCredits() {
    Navigator.of(context).pushNamed('/purchase-credits');
  }
}

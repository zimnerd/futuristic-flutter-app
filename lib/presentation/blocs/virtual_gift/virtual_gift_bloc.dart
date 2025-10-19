import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../data/services/virtual_gift_service.dart';
import '../../../data/models/virtual_gift.dart';
import 'virtual_gift_event.dart';
import 'virtual_gift_state.dart';

class VirtualGiftBloc extends Bloc<VirtualGiftEvent, VirtualGiftState> {
  final VirtualGiftService _giftService;
  final Logger _logger = Logger();

  VirtualGiftBloc(this._giftService) : super(const VirtualGiftState()) {
    on<LoadGiftCatalog>(_onLoadGiftCatalog);
    on<SendGift>(_onSendGift);
    on<LoadReceivedGifts>(_onLoadReceivedGifts);
    on<LoadSentGifts>(_onLoadSentGifts);
    on<FilterGifts>(_onFilterGifts);
    on<CreateCustomGift>(_onCreateCustomGift);
    on<LoadGiftHistory>(_onLoadGiftHistory);
    on<ReactToGift>(_onReactToGift);
    on<LoadGiftCategories>(_onLoadGiftCategories);
    on<RefreshGifts>(_onRefreshGifts);
  }

  Future<void> _onLoadGiftCatalog(
    LoadGiftCatalog event,
    Emitter<VirtualGiftState> emit,
  ) async {
    try {
      emit(state.copyWith(status: VirtualGiftStatus.loading));

      final gifts = await _giftService.getAvailableGifts();

      emit(
        state.copyWith(
          status: VirtualGiftStatus.loaded,
          catalog: gifts,
          filteredCatalog: gifts,
        ),
      );

      _logger.d('Loaded ${gifts.length} gifts from catalog');
    } catch (e) {
      _logger.e('Error loading gift catalog: $e');
      emit(
        state.copyWith(
          status: VirtualGiftStatus.error,
          errorMessage: 'Failed to load gift catalog: $e',
        ),
      );
    }
  }

  Future<void> _onSendGift(
    SendGift event,
    Emitter<VirtualGiftState> emit,
  ) async {
    try {
      emit(state.copyWith(status: VirtualGiftStatus.sending));

      final transaction = await _giftService.sendGift(
        recipientId: event.recipientId,
        giftId: event.giftId,
        message: event.message,
      );

      if (transaction != null) {
        // Update sent gifts list
        final updatedSentGifts = [transaction, ...state.sentGifts];

        emit(
          state.copyWith(
            status: VirtualGiftStatus.sent,
            sentGifts: updatedSentGifts,
            lastSentGift: transaction,
          ),
        );

        _logger.d('Gift sent successfully: ${transaction.id}');
      } else {
        emit(
          state.copyWith(
            status: VirtualGiftStatus.error,
            errorMessage: 'Failed to send gift',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error sending gift: $e');
      emit(
        state.copyWith(
          status: VirtualGiftStatus.error,
          errorMessage: 'Failed to send gift: $e',
        ),
      );
    }
  }

  Future<void> _onLoadReceivedGifts(
    LoadReceivedGifts event,
    Emitter<VirtualGiftState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      final gifts = await _giftService.getReceivedGifts(
        page: event.page,
        limit: event.limit,
      );

      // If this is page 1, replace the list; otherwise, append
      final updatedGifts = event.page == 1
          ? gifts
          : [...state.receivedGifts, ...gifts];

      emit(state.copyWith(receivedGifts: updatedGifts, isLoading: false));

      _logger.d('Loaded ${gifts.length} received gifts');
    } catch (e) {
      _logger.e('Error loading received gifts: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load received gifts: $e',
        ),
      );
    }
  }

  Future<void> _onLoadSentGifts(
    LoadSentGifts event,
    Emitter<VirtualGiftState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      final gifts = await _giftService.getSentGifts(
        page: event.page,
        limit: event.limit,
      );

      // If this is page 1, replace the list; otherwise, append
      final updatedGifts = event.page == 1
          ? gifts
          : [...state.sentGifts, ...gifts];

      emit(state.copyWith(sentGifts: updatedGifts, isLoading: false));

      _logger.d('Loaded ${gifts.length} sent gifts');
    } catch (e) {
      _logger.e('Error loading sent gifts: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load sent gifts: $e',
        ),
      );
    }
  }

  Future<void> _onFilterGifts(
    FilterGifts event,
    Emitter<VirtualGiftState> emit,
  ) async {
    try {
      emit(state.copyWith(status: VirtualGiftStatus.filtering));

      var filtered = List<VirtualGift>.from(state.catalog);

      // Apply category filter
      if (event.category != null && event.category!.isNotEmpty) {
        filtered = filtered
            .where(
              (gift) =>
                  gift.category.name.toLowerCase() ==
                  event.category!.toLowerCase(),
            )
            .toList();
      }

      // Apply search query filter
      if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
        final query = event.searchQuery!.toLowerCase();
        filtered = filtered
            .where(
              (gift) =>
                  gift.name.toLowerCase().contains(query) ||
                  gift.description.toLowerCase().contains(query),
            )
            .toList();
      }

      // Apply price range filter
      if (event.priceRange != null && event.priceRange!.isNotEmpty) {
        final priceFilter = _parsePriceRange(event.priceRange!);
        if (priceFilter != null) {
          filtered = filtered
              .where(
                (gift) =>
                    gift.price >= priceFilter.min &&
                    gift.price <= priceFilter.max,
              )
              .toList();
        }
      }

      emit(
        state.copyWith(
          status: VirtualGiftStatus.filtered,
          filteredCatalog: filtered,
          selectedCategory: event.category,
          searchQuery: event.searchQuery,
          priceRange: event.priceRange,
        ),
      );

      _logger.d('Filtered gifts: ${filtered.length} results');
    } catch (e) {
      _logger.e('Error filtering gifts: $e');
      emit(
        state.copyWith(
          status: VirtualGiftStatus.error,
          errorMessage: 'Failed to filter gifts: $e',
        ),
      );
    }
  }

  Future<void> _onCreateCustomGift(
    CreateCustomGift event,
    Emitter<VirtualGiftState> emit,
  ) async {
    try {
      emit(state.copyWith(status: VirtualGiftStatus.loading));

      // Note: Service doesn't have createCustomGift method, so we'll simulate it
      _logger.d('Custom gift creation request: ${event.name}');

      // For now, just log the request since the service doesn't support it
      emit(
        state.copyWith(
          status: VirtualGiftStatus.error,
          errorMessage: 'Custom gift creation not yet implemented',
        ),
      );
    } catch (e) {
      _logger.e('Error creating custom gift: $e');
      emit(
        state.copyWith(
          status: VirtualGiftStatus.error,
          errorMessage: 'Failed to create custom gift: $e',
        ),
      );
    }
  }

  Future<void> _onLoadGiftHistory(
    LoadGiftHistory event,
    Emitter<VirtualGiftState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));

      final [receivedGifts, sentGifts, userStats] = await Future.wait([
        _giftService.getReceivedGifts(),
        _giftService.getSentGifts(),
        _giftService.getUserGiftStats(),
      ]);

      emit(
        state.copyWith(
          receivedGifts: receivedGifts as List<GiftTransaction>,
          sentGifts: sentGifts as List<GiftTransaction>,
          userStats: userStats as UserGiftStats?,
          isLoading: false,
        ),
      );

      _logger.d('Loaded gift history and user stats');
    } catch (e) {
      _logger.e('Error loading gift history: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load gift history: $e',
        ),
      );
    }
  }

  Future<void> _onReactToGift(
    ReactToGift event,
    Emitter<VirtualGiftState> emit,
  ) async {
    try {
      // For now, just log the reaction since the service doesn't have this method
      _logger.d(
        'Reacting to gift ${event.giftTransactionId} with ${event.reaction}',
      );

      // In a real implementation, you would call:
      // await _giftService.reactToGift(event.giftTransactionId, event.reaction);

      // Update local state optimistically
      final updatedReceivedGifts = state.receivedGifts.map((gift) {
        if (gift.id == event.giftTransactionId) {
          // In a real implementation, add reaction to the gift transaction
          return gift;
        }
        return gift;
      }).toList();

      emit(state.copyWith(receivedGifts: updatedReceivedGifts));
    } catch (e) {
      _logger.e('Error reacting to gift: $e');
      emit(state.copyWith(errorMessage: 'Failed to react to gift: $e'));
    }
  }

  Future<void> _onLoadGiftCategories(
    LoadGiftCategories event,
    Emitter<VirtualGiftState> emit,
  ) async {
    try {
      // Since the service doesn't have getGiftCategories, we'll use the enum values
      final categories = GiftCategory.values.map((e) => e.name).toList();

      emit(state.copyWith(categories: categories));
      _logger.d('Loaded ${categories.length} gift categories');
    } catch (e) {
      _logger.e('Error loading gift categories: $e');
      emit(state.copyWith(errorMessage: 'Failed to load gift categories: $e'));
    }
  }

  Future<void> _onRefreshGifts(
    RefreshGifts event,
    Emitter<VirtualGiftState> emit,
  ) async {
    try {
      // Refresh all gift data
      add(const LoadGiftCatalog());
      add(const LoadGiftCategories());
      add(const LoadGiftHistory());
    } catch (e) {
      _logger.e('Error refreshing gifts: $e');
      emit(state.copyWith(errorMessage: 'Failed to refresh gifts: $e'));
    }
  }

  // Helper method to parse price range strings like "0-50", "50-100", etc.
  ({int min, int max})? _parsePriceRange(String priceRange) {
    try {
      final parts = priceRange.split('-');
      if (parts.length == 2) {
        final min = int.parse(parts[0].trim());
        final max = int.parse(parts[1].trim());
        return (min: min, max: max);
      }
    } catch (e) {
      _logger.w('Invalid price range format: $priceRange');
    }
    return null;
  }
}

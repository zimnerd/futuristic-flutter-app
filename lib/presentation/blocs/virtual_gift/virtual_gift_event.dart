import 'package:equatable/equatable.dart';

// Simple reaction enum for gift reactions
enum GiftReaction { love, like, thanks, wow }

abstract class VirtualGiftEvent extends Equatable {
  const VirtualGiftEvent();

  @override
  List<Object?> get props => [];
}

class LoadGiftCatalog extends VirtualGiftEvent {
  final String? category;
  final double? minPrice;
  final double? maxPrice;

  const LoadGiftCatalog({this.category, this.minPrice, this.maxPrice});

  @override
  List<Object?> get props => [category, minPrice, maxPrice];
}

class SendGift extends VirtualGiftEvent {
  final String recipientId;
  final String giftId;
  final String? message;

  const SendGift({
    required this.recipientId,
    required this.giftId,
    this.message,
  });

  @override
  List<Object?> get props => [recipientId, giftId, message];
}

class LoadReceivedGifts extends VirtualGiftEvent {
  final int page;
  final int limit;

  const LoadReceivedGifts({this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [page, limit];
}

class LoadSentGifts extends VirtualGiftEvent {
  final int page;
  final int limit;

  const LoadSentGifts({this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [page, limit];
}

class FilterGifts extends VirtualGiftEvent {
  final String? category;
  final String? priceRange;
  final String? searchQuery;

  const FilterGifts({this.category, this.priceRange, this.searchQuery});

  @override
  List<Object?> get props => [category, priceRange, searchQuery];
}

class CreateCustomGift extends VirtualGiftEvent {
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;

  const CreateCustomGift({
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
  });

  @override
  List<Object?> get props => [name, description, price, imageUrl, category];
}

class LoadGiftHistory extends VirtualGiftEvent {
  const LoadGiftHistory();
}

class ReactToGift extends VirtualGiftEvent {
  final String giftTransactionId;
  final GiftReaction reaction;

  const ReactToGift({required this.giftTransactionId, required this.reaction});

  @override
  List<Object?> get props => [giftTransactionId, reaction];
}

class LoadGiftCategories extends VirtualGiftEvent {
  const LoadGiftCategories();
}

class RefreshGifts extends VirtualGiftEvent {
  const RefreshGifts();
}

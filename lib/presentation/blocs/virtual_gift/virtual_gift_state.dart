import 'package:equatable/equatable.dart';
import '../../../data/models/virtual_gift.dart';

enum VirtualGiftStatus {
  initial,
  loading,
  loaded,
  sending,
  sent,
  filtering,
  filtered,
  error,
}

class VirtualGiftState extends Equatable {
  final VirtualGiftStatus status;
  final List<VirtualGift> catalog;
  final List<VirtualGift> filteredCatalog;
  final List<GiftTransaction> receivedGifts;
  final List<GiftTransaction> sentGifts;
  final List<String> categories;
  final UserGiftStats? userStats;
  final String? selectedCategory;
  final String? priceRange;
  final String? searchQuery;
  final String? errorMessage;
  final bool isLoading;
  final GiftTransaction? lastSentGift;

  const VirtualGiftState({
    this.status = VirtualGiftStatus.initial,
    this.catalog = const [],
    this.filteredCatalog = const [],
    this.receivedGifts = const [],
    this.sentGifts = const [],
    this.categories = const [],
    this.userStats,
    this.selectedCategory,
    this.priceRange,
    this.searchQuery,
    this.errorMessage,
    this.isLoading = false,
    this.lastSentGift,
  });

  VirtualGiftState copyWith({
    VirtualGiftStatus? status,
    List<VirtualGift>? catalog,
    List<VirtualGift>? filteredCatalog,
    List<GiftTransaction>? receivedGifts,
    List<GiftTransaction>? sentGifts,
    List<String>? categories,
    UserGiftStats? userStats,
    String? selectedCategory,
    String? priceRange,
    String? searchQuery,
    String? errorMessage,
    bool? isLoading,
    GiftTransaction? lastSentGift,
  }) {
    return VirtualGiftState(
      status: status ?? this.status,
      catalog: catalog ?? this.catalog,
      filteredCatalog: filteredCatalog ?? this.filteredCatalog,
      receivedGifts: receivedGifts ?? this.receivedGifts,
      sentGifts: sentGifts ?? this.sentGifts,
      categories: categories ?? this.categories,
      userStats: userStats ?? this.userStats,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      priceRange: priceRange ?? this.priceRange,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      lastSentGift: lastSentGift ?? this.lastSentGift,
    );
  }

  @override
  List<Object?> get props => [
    status,
    catalog,
    filteredCatalog,
    receivedGifts,
    sentGifts,
    categories,
    userStats,
    selectedCategory,
    priceRange,
    searchQuery,
    errorMessage,
    isLoading,
    lastSentGift,
  ];
}

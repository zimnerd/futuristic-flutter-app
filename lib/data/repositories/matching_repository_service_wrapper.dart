import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/discovery_types.dart' as discovery_types;
import '../../../domain/repositories/matching_repository.dart';
import '../../../presentation/blocs/matching/matching_bloc.dart';
import '../services/matching_service.dart';

/// Implementation of MatchingRepository using MatchingService
class MatchingRepositoryServiceWrapper implements MatchingRepository {
  final MatchingService _matchingService;

  MatchingRepositoryServiceWrapper({required MatchingService matchingService})
      : _matchingService = matchingService;

  @override
  Future<Either<Failure, List<UserProfile>>> getPotentialMatches({
    MatchingFilters? filters,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final filterMap = filters != null ? {
        'minAge': filters.minAge,
        'maxAge': filters.maxAge,
        'maxDistance': filters.maxDistance,
        if (filters.showMeGender != null) 'showMeGender': filters.showMeGender,
        'verifiedOnly': filters.verifiedOnly,
        'hasPhotos': filters.hasPhotos,
      } : null;

      final profiles = await _matchingService.getPotentialMatches(
        limit: limit,
        offset: offset,
        filters: filterMap,
      );
      return Right(profiles);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, discovery_types.SwipeResult>> swipeProfile({
    required String profileId,
    required discovery_types.SwipeAction direction,
  }) async {
    try {
      final result = await _matchingService.swipeProfile(
        profileId: profileId,
        isLike: direction == discovery_types.SwipeAction.right, // right = like
      );
      
      return Right(discovery_types.SwipeResult(
        isMatch: result['isMatch'] ?? false,
        targetUserId: profileId,
        action: direction == discovery_types.SwipeAction.right ? discovery_types.SwipeAction.right : discovery_types.SwipeAction.left,
        conversationId: result['matchId'],
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> undoSwipe(String profileId) async {
    try {
      // MatchingService doesn't have undoSwipe, so we'll return false for now
      return const Right(false);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> reportProfile({
    required String profileId,
    required String reason,
    String? description,
  }) async {
    try {
      await _matchingService.reportProfile(
        profileId: profileId,
        reason: reason,
        description: description,
      );
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<discovery_types.SwipeAction>>> getSwipeHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // MatchingService doesn't have getSwipeHistory, return empty list for now
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MatchStats>> getMatchStats() async {
    try {
      // MatchingService doesn't have getMatchStats, return default values
      return const Right(MatchStats(
        totalLikes: 0,
        totalPasses: 0,
        totalSuperLikes: 0,
        totalMatches: 0,
        likesReceived: 0,
        matchRate: 0.0,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // MatchingService doesn't have updateLocation, return true for now
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserLimits>> getUserLimits() async {
    try {
      // MatchingService doesn't have getUserLimits, return default values
      final now = DateTime.now();
      return Right(UserLimits(
        superLikesRemaining: 1,
        undosRemaining: 1,
        superLikesResetAt: now.add(const Duration(hours: 24)),
        undosResetAt: now.add(const Duration(hours: 24)),
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> purchaseLimits({
    int? superLikes,
    int? undos,
  }) async {
    try {
      // MatchingService doesn't have purchaseLimits, return false for now
      return const Right(false);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Additional methods specific to this implementation
  Future<Either<Failure, bool>> blockProfile(String profileId) async {
    try {
      await _matchingService.blockProfile(profileId);
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, bool>> unblockProfile(String profileId) async {
    try {
      await _matchingService.unblockProfile(profileId);
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, List<UserProfile>>> getBlockedProfiles() async {
    try {
      // MatchingService doesn't have getBlockedProfiles, return empty list
      return const Right([]);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, UserProfile>> getProfile(String profileId) async {
    try {
      final profile = await _matchingService.getProfile(profileId);
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, List<UserProfile>>> getNearbyMatches({
    required double latitude,
    required double longitude,
    double radius = 50.0,
    int limit = 20,
  }) async {
    try {
      // Use getPotentialMatches as a fallback
      final profiles = await _matchingService.getPotentialMatches(
        limit: limit,
        offset: 0,
      );
      return Right(profiles);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, List<UserProfile>>> getCompatibleMatches({
    int limit = 10,
    double minCompatibility = 0.7,
  }) async {
    try {
      // Use getPotentialMatches as a fallback
      final profiles = await _matchingService.getPotentialMatches(
        limit: limit,
        offset: 0,
      );
      return Right(profiles);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

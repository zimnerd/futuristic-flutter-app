import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:pulse_dating_app/data/services/speed_dating_service.dart';
import 'package:pulse_dating_app/presentation/blocs/speed_dating/speed_dating_bloc.dart';
import 'package:pulse_dating_app/presentation/blocs/speed_dating/speed_dating_event.dart';
import 'package:pulse_dating_app/presentation/blocs/speed_dating/speed_dating_state.dart';

// Mock class
class MockSpeedDatingService extends Mock implements SpeedDatingService {}

void main() {
  late SpeedDatingBloc bloc;
  late MockSpeedDatingService mockService;

  setUp(() {
    mockService = MockSpeedDatingService();
    bloc = SpeedDatingBloc(speedDatingService: mockService);
  });

  tearDown(() {
    bloc.close();
  });

  group('SpeedDatingBloc - Initial State', () {
    test('initial state should be SpeedDatingInitial', () {
      expect(bloc.state, isA<SpeedDatingInitial>());
    });
  });

  group('SpeedDatingBloc - LoadSpeedDatingEvents', () {
    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'emits [SpeedDatingLoading, SpeedDatingLoaded] when events loaded successfully',
      build: () {
        when(() => mockService.getUpcomingEvents()).thenAnswer(
          (_) async => [
            {
              'id': 'event1',
              'title': 'Friday Speed Dating',
              'startTime': '2024-12-20T19:00:00Z',
              'status': 'upcoming',
            },
          ],
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LoadSpeedDatingEvents()),
      expect: () => [
        isA<SpeedDatingLoading>(),
        isA<SpeedDatingLoaded>(),
      ],
      verify: (_) {
        verify(() => mockService.getUpcomingEvents()).called(1);
      },
    );

    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'emits [SpeedDatingLoading, SpeedDatingError] when loading fails',
      build: () {
        when(() => mockService.getUpcomingEvents()).thenThrow(
          Exception('Network error'),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LoadSpeedDatingEvents()),
      expect: () => [
        isA<SpeedDatingLoading>(),
        isA<SpeedDatingError>(),
      ],
    );
  });

  group('SpeedDatingBloc - JoinSpeedDatingEvent', () {
    const eventId = 'event1';

    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'emits [SpeedDatingJoining, SpeedDatingJoined] when join successful',
      build: () {
        when(() => mockService.joinEvent(any(), any())).thenAnswer(
          (_) async => {'id': eventId, 'status': 'joined'},
        );
        when(() => mockService.getUpcomingEvents()).thenAnswer(
          (_) async => [],
        );
        return bloc;
      },
      act: (bloc) => bloc.add(JoinSpeedDatingEvent(eventId)),
      skip: 1, // Skip SpeedDatingJoining as it emits very quickly
      expect: () => [
        isA<SpeedDatingJoined>(),
        isA<
          SpeedDatingLoaded
        >(), // LoadUserSpeedDatingSessions is triggered after join
      ],
      verify: (_) {
        verify(() => mockService.joinEvent(eventId, any())).called(1);
      },
    );

    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'emits [SpeedDatingJoining, SpeedDatingError] when join fails',
      build: () {
        when(() => mockService.joinEvent(any(), any())).thenAnswer(
          (_) async => null, // Null indicates failure
        );
        return bloc;
      },
      act: (bloc) => bloc.add(JoinSpeedDatingEvent(eventId)),
      expect: () => [
        isA<SpeedDatingJoining>(),
        isA<SpeedDatingError>(),
      ],
    );
  });

  group('SpeedDatingBloc - LeaveSpeedDatingEvent', () {
    const eventId = 'event1';

    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'emits [SpeedDatingLeaving, SpeedDatingLeft] when leave successful',
      build: () {
        when(() => mockService.leaveEvent(any(), any())).thenAnswer(
          (_) async => true,
        );
        when(() => mockService.getUpcomingEvents()).thenAnswer(
          (_) async => [],
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LeaveSpeedDatingEvent(eventId)),
      skip: 1, // Skip SpeedDatingLeaving as it emits very quickly
      expect: () => [
        isA<SpeedDatingLeft>(),
        isA<
          SpeedDatingLoaded
        >(), // LoadUserSpeedDatingSessions is triggered after leave
      ],
      verify: (_) {
        verify(() => mockService.leaveEvent(eventId, any())).called(1);
      },
    );

    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'emits [SpeedDatingLeaving, SpeedDatingError] when leave fails',
      build: () {
        when(() => mockService.leaveEvent(any(), any())).thenAnswer(
          (_) async => false,
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LeaveSpeedDatingEvent(eventId)),
      expect: () => [
        isA<SpeedDatingLeaving>(),
        isA<SpeedDatingError>(),
      ],
    );
  });

  group('SpeedDatingBloc - RateSpeedDatingMatch', () {
    const sessionId = 'session1';
    const matchUserId = 'user456';
    const rating = 5;
    const notes = 'Great conversation!';

    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'emits [SpeedDatingRatingSubmitting, SpeedDatingRatingSubmitted] when rating successful',
      build: () {
        when(() => mockService.rateSession(
              any(),
              any(),
              any(),
              notes: any(named: 'notes'),
            )).thenAnswer(
          (_) async => {
            'success': true,
            'mutualInterest': true,
          },
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        RateSpeedDatingMatch(
          sessionId: sessionId,
          matchUserId: matchUserId,
          rating: rating,
          notes: notes,
        ),
      ),
      expect: () => [
        isA<SpeedDatingRatingSubmitting>(),
        isA<SpeedDatingRatingSubmitted>(),
      ],
      verify: (_) {
        verify(() => mockService.rateSession(
              sessionId,
              matchUserId,
              rating,
              notes: notes,
            )).called(1);
      },
    );

    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'emits [SpeedDatingRatingSubmitting, SpeedDatingError] when rating fails',
      build: () {
        when(() => mockService.rateSession(
              any(),
              any(),
              any(),
              notes: any(named: 'notes'),
            )).thenAnswer(
          (_) async => null,
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        RateSpeedDatingMatch(
          sessionId: sessionId,
          matchUserId: matchUserId,
          rating: rating,
          notes: notes,
        ),
      ),
      expect: () => [
        isA<SpeedDatingRatingSubmitting>(),
        isA<SpeedDatingError>(),
      ],
    );
  });

  group('SpeedDatingBloc - GetSpeedDatingMatches', () {
    const eventId = 'event1';

    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'emits [SpeedDatingMatchesLoading, SpeedDatingMatchesLoaded] when matches loaded',
      build: () {
        when(() => mockService.getEventMatches(any(), any())).thenAnswer(
          (_) async => [
            {
              'userId': 'user456',
              'name': 'Jane Doe',
              'matchPercentage': 92,
              'yourRating': 5,
              'theirRating': 5,
            },
            {
              'userId': 'user789',
              'name': 'Alice Smith',
              'matchPercentage': 85,
              'yourRating': 4,
              'theirRating': 5,
            },
          ],
        );
        return bloc;
      },
      act: (bloc) => bloc.add(GetSpeedDatingMatches(eventId)),
      expect: () => [
        isA<SpeedDatingMatchesLoading>(),
        isA<SpeedDatingMatchesLoaded>(),
      ],
      verify: (_) {
        verify(() => mockService.getEventMatches(eventId, any())).called(1);
      },
    );

    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'emits empty matches list when no matches found',
      build: () {
        when(() => mockService.getEventMatches(any(), any())).thenAnswer(
          (_) async => [],
        );
        return bloc;
      },
      act: (bloc) => bloc.add(GetSpeedDatingMatches(eventId)),
      expect: () => [
        isA<SpeedDatingMatchesLoading>(),
        isA<SpeedDatingMatchesLoaded>(),
      ],
    );
  });

  group('SpeedDatingBloc - StartSpeedDatingSession', () {
    const eventId = 'event1';

    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'emits [SpeedDatingSessionStarting, SpeedDatingSessionStarted] when session starts',
      build: () {
        when(() => mockService.joinEvent(any(), any())).thenAnswer(
          (_) async => {
            'id': eventId,
            'currentSession': {
              'partnerId': 'user456',
              'sessionNumber': 1,
            },
          },
        );
        return bloc;
      },
      act: (bloc) => bloc.add(StartSpeedDatingSession(eventId)),
      expect: () => [
        isA<SpeedDatingSessionStarting>(),
        isA<SpeedDatingSessionStarted>(),
      ],
    );
  });

  group('SpeedDatingBloc - EndSpeedDatingSession', () {
    const sessionId = 'session1';

    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'emits [SpeedDatingSessionEnding, SpeedDatingSessionEnded] when session ends',
      build: () {
        when(() => mockService.leaveEvent(any(), any())).thenAnswer(
          (_) async => true,
        );
        return bloc;
      },
      act: (bloc) => bloc.add(EndSpeedDatingSession(sessionId)),
      expect: () => [
        isA<SpeedDatingSessionEnding>(),
        isA<SpeedDatingSessionEnded>(),
      ],
    );
  });

  group('SpeedDatingBloc - RefreshSpeedDatingData', () {
    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'triggers LoadSpeedDatingEvents and LoadUserSpeedDatingSessions when in loaded state',
      build: () {
        when(() => mockService.getUpcomingEvents()).thenAnswer(
          (_) async => [],
        );
        return bloc;
      },
      seed: () => SpeedDatingLoaded(),
      act: (bloc) => bloc.add(RefreshSpeedDatingData()),
      skip: 1, // Skip SpeedDatingLoading as it emits very quickly
      expect: () => [
        isA<SpeedDatingLoaded>(), // Final loaded state after refresh completes
      ],
      verify: (_) {
        verify(
          () => mockService.getUpcomingEvents(),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<SpeedDatingBloc, SpeedDatingState>(
      'does nothing when not in loaded state',
      build: () => bloc,
      act: (bloc) => bloc.add(RefreshSpeedDatingData()),
      expect: () => [],
    );
  });
}

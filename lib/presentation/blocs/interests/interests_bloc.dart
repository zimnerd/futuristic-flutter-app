import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/interests_repository.dart';
import 'interests_event.dart';
import 'interests_state.dart';

class InterestsBloc extends Bloc<InterestsEvent, InterestsState> {
  final InterestsRepository repository;

  InterestsBloc({required this.repository}) : super(const InterestsInitial()) {
    on<LoadInterests>(_onLoadInterests);
    on<RefreshInterests>(_onRefreshInterests);
  }

  Future<void> _onLoadInterests(
    LoadInterests event,
    Emitter<InterestsState> emit,
  ) async {
    emit(const InterestsLoading());
    try {
      final categories = await repository.getCategories();
      emit(InterestsLoaded(categories));
    } catch (e) {
      emit(InterestsError(e.toString()));
    }
  }

  Future<void> _onRefreshInterests(
    RefreshInterests event,
    Emitter<InterestsState> emit,
  ) async {
    // Don't show loading state on refresh to avoid flickering
    try {
      final categories = await repository.getCategories();
      emit(InterestsLoaded(categories));
    } catch (e) {
      emit(InterestsError(e.toString()));
    }
  }
}

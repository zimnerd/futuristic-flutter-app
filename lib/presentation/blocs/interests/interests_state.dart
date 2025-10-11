import 'package:equatable/equatable.dart';
import '../../../data/models/interest_category.dart';

abstract class InterestsState extends Equatable {
  const InterestsState();

  @override
  List<Object?> get props => [];
}

class InterestsInitial extends InterestsState {
  const InterestsInitial();
}

class InterestsLoading extends InterestsState {
  const InterestsLoading();
}

class InterestsLoaded extends InterestsState {
  final List<InterestCategory> categories;

  const InterestsLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class InterestsError extends InterestsState {
  final String message;

  const InterestsError(this.message);

  @override
  List<Object?> get props => [message];
}

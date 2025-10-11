import 'package:equatable/equatable.dart';

abstract class InterestsEvent extends Equatable {
  const InterestsEvent();

  @override
  List<Object?> get props => [];
}

class LoadInterests extends InterestsEvent {
  const LoadInterests();
}

class RefreshInterests extends InterestsEvent {
  const RefreshInterests();
}

part of 'barter_bloc.dart';

abstract class BarterState extends Equatable {
  const BarterState();

  @override
  List<Object> get props => [];
}

class BarterInitial extends BarterState {}

class BarterLoading extends BarterState {}

class BarterInitialized extends BarterState {
  final Stream<List<BarterRecord?>> barterStream;
  final List<dynamic> userProducts;

  final List<dynamic> user2Products;

  BarterInitialized({
    required this.barterStream,
    required this.userProducts,
    required this.user2Products,
  });
}

class BarterError extends BarterState {
  final String message;

  BarterError(this.message);
}

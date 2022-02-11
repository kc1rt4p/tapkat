part of 'barter_bloc.dart';

abstract class BarterState extends Equatable {
  const BarterState();

  @override
  List<Object> get props => [];
}

class BarterInitial extends BarterState {}

class BarterLoading extends BarterState {}

class BarterTransactionsInitialized extends BarterState {
  // final List<BarterRecordModel> fromOthersList;
  // final List<BarterRecordModel> byYouList;

  final Stream<List<BarterRecordModel>> fromOthersStream;
  final Stream<List<BarterRecordModel>> byYouStream;

  BarterTransactionsInitialized({
    // required this.fromOthersList,
    // required this.byYouList,
    required this.fromOthersStream,
    required this.byYouStream,
  });
}

class StreambarterSuccess extends BarterState {
  final Stream<List<BarterRecord?>> barterStream;
  final List<ProductModel> userProducts;

  final List<ProductModel> user2Products;

  StreambarterSuccess({
    required this.barterStream,
    required this.userProducts,
    required this.user2Products,
  });
}

class BarterInitialized extends BarterState {
  final Stream<BarterRecordModel> barterStream;
  final List<ProductModel> userProducts;
  final Stream<List<BarterProductModel>> barterProductsStream;

  final List<ProductModel> user2Products;

  BarterInitialized({
    required this.barterStream,
    required this.userProducts,
    required this.user2Products,
    required this.barterProductsStream,
  });
}

class UpdateBarterStatusSuccess extends BarterState {}

class AddCashOfferSuccess extends BarterState {}

class DeleteCashOfferSuccess extends BarterState {}

class DeleteBarterProductsSuccess extends BarterState {}

class UpdateBarterProductsSuccess extends BarterState {}

class BarterChatInitialized extends BarterState {
  final Stream<List<ChatMessageModel>> barterChatStream;
  final User user;

  BarterChatInitialized({
    required this.user,
    required this.barterChatStream,
  });
}

class DeleteBarterSuccess extends BarterState {}

class BarterError extends BarterState {
  final String message;

  BarterError(this.message);
}

class SendMessageSuccess extends BarterState {}

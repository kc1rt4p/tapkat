part of 'barter_bloc.dart';

abstract class BarterState extends Equatable {
  const BarterState();

  @override
  List<Object> get props => [];
}

class BarterInitial extends BarterState {}

class BarterLoading extends BarterState {}

class GetCurrentUserItemsSuccess extends BarterState {
  final List<ProductModel> list;

  GetCurrentUserItemsSuccess(this.list);
}

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

class GetHiddenProducutsDone extends BarterState {
  final List<ProductModel> hiddenSenderProducts;
  final List<ProductModel> hiddenRecipientProducts;

  GetHiddenProducutsDone({
    required this.hiddenSenderProducts,
    required this.hiddenRecipientProducts,
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
  final Stream<BarterRecordModel?> barterStream;
  final List<ProductModel> remoteUserProducts;
  final Stream<List<BarterProductModel>> barterProductsStream;
  final List<ProductModel> currentUserProducts;

  BarterInitialized({
    required this.barterStream,
    required this.remoteUserProducts,
    required this.currentUserProducts,
    required this.barterProductsStream,
  });
}

class UpdateBarterStatusSuccess extends BarterState {}

class AddCashOfferSuccess extends BarterState {}

class DeleteCashOfferSuccess extends BarterState {}

class DeleteBarterProductsSuccess extends BarterState {}

class BarterRemoved extends BarterState {}

class GetUserReviewSuccess extends BarterState {
  final UserReviewModel? review;

  GetUserReviewSuccess(this.review);
}

class BarterUserError extends BarterState {
  final String message;

  BarterUserError(this.message);
}

class GetProductReviewSuccess extends BarterState {
  final ProductReviewModel? review;

  GetProductReviewSuccess(this.review);
}

class UpdateBarterProductsSuccess extends BarterState {}

class UpdateUserReviewSuccess extends BarterState {}

class UpdateProductRatingSuccess extends BarterState {}

class RateProductSuccess extends BarterState {}

class SwitchRolesSuccess extends BarterState {}

class AddUserReviewSuccess extends BarterState {}

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

class GetUnreadBarterMessagesSuccess extends BarterState {
  final List<ChatMessageModel> messages;

  GetUnreadBarterMessagesSuccess(this.messages);
}

class MarkMessagesAsReadSuccess extends BarterState {}

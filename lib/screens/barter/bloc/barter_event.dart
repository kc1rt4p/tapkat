part of 'barter_bloc.dart';

abstract class BarterEvent extends Equatable {
  const BarterEvent();

  @override
  List<Object> get props => [];
}

class SendMessage extends BarterEvent {
  final ChatMessageModel message;

  SendMessage(this.message);
}

class SwitchRoles extends BarterEvent {
  final String barterId;

  SwitchRoles(this.barterId);
}

class RateProduct extends BarterEvent {
  final ProductReviewModel review;

  RateProduct(this.review);
}

class UpdateProductRating extends BarterEvent {
  final ProductReviewModel review;

  UpdateProductRating(this.review);
}

class AddUserReview extends BarterEvent {
  final UserReviewModel review;
  AddUserReview(this.review);
}

class UpdateUserReview extends BarterEvent {
  final UserReviewModel review;

  UpdateUserReview(this.review);
}

class InitializeBarterChat extends BarterEvent {
  final String barterId;

  InitializeBarterChat(this.barterId);
}

class InitializeBarterTransactions extends BarterEvent {}

class StreamBarter extends BarterEvent {
  final BarterRecordModel barterRecord;

  StreamBarter(this.barterRecord);
}

class DeleteBarter extends BarterEvent {
  final String id;

  DeleteBarter(this.id);
}

class DeleteBarterProducts extends BarterEvent {
  final String barterId;
  final List<BarterProductModel> products;

  DeleteBarterProducts({
    required this.barterId,
    required this.products,
  });
}

class UpdateBarterProducts extends BarterEvent {
  final String barterId;
  final List<BarterProductModel> products;

  UpdateBarterProducts({
    required this.barterId,
    required this.products,
  });
}

class AddCashOffer extends BarterEvent {
  final String barterId;
  final String userId;
  final num amount;
  final String currency;

  AddCashOffer({
    required this.barterId,
    required this.userId,
    required this.amount,
    required this.currency,
  });
}

class DeleteCashOffer extends BarterEvent {
  final String barterId;
  final String productId;

  DeleteCashOffer({
    required this.barterId,
    required this.productId,
  });
}

class InitializeBarter extends BarterEvent {
  final BarterRecordModel barterData;

  InitializeBarter(this.barterData);
}

class UpdateBarterStatus extends BarterEvent {
  final String barterId;
  final String status;

  UpdateBarterStatus(this.barterId, this.status);
}

class CounterOffer extends BarterEvent {
  final String barterId;
  final BarterProductModel product;

  CounterOffer(this.barterId, this.product);
}

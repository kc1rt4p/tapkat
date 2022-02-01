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

class InitializeBarter extends BarterEvent {
  final BarterRecordModel barterData;

  InitializeBarter(this.barterData);
  // final String userid1;
  // final String userid2;
  // final bool user1Accepted;
  // final bool user2Accepted;
  // final String u1P1Id;
  // final String u1P1Name;
  // final double u1P1Price;
  // final String u2P1Id;
  // final String u2P1Name;
  // final double u2P1Price;
  // final String proposedBy;
  // final DateTime lastProposedDate;
  // final String dealStatus;
  // final DateTime dealDate;
  // final String u1P1Image;
  // final String u2P1Image;
  // final String barterid;
  // final int barterNo;

  // InitializeBarter({
  //   required this.userid1,
  //   required this.userid2,
  //   required this.user1Accepted,
  //   required this.user2Accepted,
  //   required this.u1P1Id,
  //   required this.u1P1Name,
  //   required this.u1P1Price,
  //   required this.u2P1Id,
  //   required this.u2P1Name,
  //   required this.u2P1Price,
  //   required this.proposedBy,
  //   required this.lastProposedDate,
  //   required this.dealStatus,
  //   required this.dealDate,
  //   required this.u1P1Image,
  //   required this.u2P1Image,
  //   required this.barterid,
  //   required this.barterNo,
  // });
}

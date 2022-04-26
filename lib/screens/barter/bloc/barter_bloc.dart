import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/models/barter_product.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/chat_message.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/models/request/product_review_resuest.dart';
import 'package:tapkat/models/request/user_review_request.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/barter_repository.dart';
import 'package:tapkat/repositories/notification_repository.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/schemas/barter_record.dart';
import 'package:tapkat/services/auth_service.dart';
import 'package:tapkat/utilities/application.dart' as application;

part 'barter_event.dart';
part 'barter_state.dart';

class BarterBloc extends Bloc<BarterEvent, BarterState> {
  List<ChatMessageModel> unreadMessages = [];
  BarterBloc() : super(BarterInitial()) {
    final _productRepository = ProductRepository();
    final _barterRepository = BarterRepository();
    final _userRepo = UserRepository();
    User? _user;
    final _notifRepo = NotificationRepository();
    on<BarterEvent>((event, emit) async {
      print('current event: $event');
      emit(BarterLoading());

      try {
        _user = application.currentUser;
        if (_user != null) {
          if (event is InitializeBarter) {
            print('=== barter id: ${event.barterData.barterId}');
            var _barterRecord = await _barterRepository
                .getBarterRecord(event.barterData.barterId!);
            print('=== _barterRecord: $_barterRecord');

            if (_barterRecord == null) {
              event.barterData.dealStatus = 'new';

              final user1Model =
                  await _userRepo.getUser(event.barterData.userid1!);
              final user2Model =
                  await _userRepo.getUser(event.barterData.userid2!);

              event.barterData.userid1Name = user1Model!.display_name;
              event.barterData.userid2Name = user2Model!.display_name;

              final newBarter =
                  await _barterRepository.setBarterRecord(event.barterData);

              var barterProducts = await _barterRepository
                  .getBarterProducts(event.barterData.barterId!);

              if (!barterProducts
                  .any((bProd) => bProd.productId == event.barterData.u2P1Id)) {
                await _barterRepository
                    .addBarterProducts(event.barterData.barterId!, [
                  BarterProductModel(
                    productId: event.barterData.u2P1Id,
                    userId: event.barterData.userid2,
                    productName: event.barterData.u2P1Name,
                    price: event.barterData.u2P1Price,
                    imgUrl: event.barterData.u2P1Image,
                  )
                ]);
                barterProducts = await _barterRepository
                    .getBarterProducts(event.barterData.barterId!);
              }

              _barterRecord = await _barterRepository
                  .getBarterRecord(event.barterData.barterId!);

              final senderUserId = _barterRecord!.userid1Role == 'sender'
                  ? _barterRecord.userid1
                  : _barterRecord.userid2;

              final recipientUserId = _barterRecord.userid1Role == 'recipient'
                  ? _barterRecord.userid1
                  : _barterRecord.userid2;

              final currentUserProducts =
                  await _productRepository.getFirstProducts(
                'user',
                sortBy: 'name',
                userId: application.currentUser!.uid,
              );

              final remoteUserProducts =
                  await _productRepository.getFirstProducts(
                'user',
                sortBy: 'name',
                userId: senderUserId == application.currentUser!.uid
                    ? recipientUserId!
                    : senderUserId!,
              );

              emit(BarterInitialized(
                barterStream:
                    _barterRepository.streamBarter(event.barterData.barterId!),
                remoteUserProducts: remoteUserProducts,
                currentUserProducts: currentUserProducts,
                barterProductsStream: _barterRepository
                    .streamBarterProducts(event.barterData.barterId!),
              ));
            } else {
              print('EXISTING BARTER');
              add(StreamBarter(_barterRecord));
            }
          }

          if (event is RateProduct) {
            final added =
                await _productRepository.addProductReview(event.review);

            if (added)
              emit(RateProductSuccess());
            else
              add(UpdateProductRating(event.review));
          }

          if (event is GetUserReview) {
            final review =
                await _userRepo.getUserReview(event.userId, event.reviewerId);
            emit(GetUserReviewSuccess(review));
          }

          if (event is GetProductReview) {
            final review = await _productRepository.getProductReview(
                event.productId, event.userId);
            emit(GetProductReviewSuccess(review));
          }

          if (event is UpdateProductRating) {
            final updated =
                await _productRepository.updateProductReview(event.review);
            if (updated) emit(UpdateProductRatingSuccess());
          }

          if (event is AddUserReview) {
            final userToReview = await _userRepo.getUser(event.review.userid!);
            event.review.user_image_url = userToReview!.photo_url!;
            final added = await _userRepo.addUserReview(event.review);

            if (added) {
              emit(AddUserReviewSuccess());
            } else {
              add(UpdateUserReview(event.review));
            }
          }

          if (event is UpdateUserReview) {
            final updated = await _userRepo.updateUserReview(event.review);

            if (updated) emit(UpdateUserReviewSuccess());
          }

          if (event is CounterOffer) {
            final _barterRecord =
                await _barterRepository.getBarterRecord(event.barterId);

            if (_barterRecord != null) {
              var _newBarterRecord = _barterRecord;
              _newBarterRecord.userid1Role =
                  _newBarterRecord.userid1Role == 'sender'
                      ? 'recipient'
                      : 'sender';
              _newBarterRecord.userid2Role =
                  _newBarterRecord.userid2Role == 'sender'
                      ? 'recipient'
                      : 'sender';
              _newBarterRecord.dealDate = DateTime.now();
              if (event.product != null) {
                _newBarterRecord.u2P1Id = event.product!.productId;
                _newBarterRecord.u2P1Name = event.product!.productName;
                _newBarterRecord.u2P1Price = event.product!.price != null
                    ? double.parse(event.product!.price.toString())
                    : 0;
                _newBarterRecord.u2P1Image = event.product!.imgUrl;
              }
              _newBarterRecord.dealStatus = 'submitted';

              final updated =
                  await _barterRepository.counterOffer(_newBarterRecord);

              if (updated) {
                _barterRepository.addMessage(ChatMessageModel(
                  barterId: event.barterId,
                  userId: application.currentUser!.uid,
                  userName: application.currentUser!.displayName,
                  message: 'Offer SUBMITTED (Counter Offer)',
                  dateCreated: DateTime.now(),
                ));

                _notifRepo.sendNotification(
                  body: 'Offer SUBMITTED (Counter Offer)',
                  title: application.currentUserModel!.display_name!,
                  receiver: _newBarterRecord.userid1 == _user!.uid
                      ? _newBarterRecord.userid2!
                      : _newBarterRecord.userid1!,
                  sender: _user!.uid,
                  barterId: _barterRecord.barterId!,
                );

                emit(UpdateBarterStatusSuccess());
              } else
                emit(BarterError('unable to counter offer'));
            }
          }

          if (event is UpdateBarterStatus) {
            await _barterRepository.updateBarterStatus(
                event.barterId, event.status);
            final barterRecord =
                await _barterRepository.getBarterRecord(event.barterId);
            if (barterRecord != null) {
              final senderUserId = barterRecord.userid1Role == 'sender'
                  ? barterRecord.userid1
                  : barterRecord.userid2;
              final recipientUserId = barterRecord.userid1Role == 'recipient'
                  ? barterRecord.userid1
                  : barterRecord.userid2;

              String userId =
                  ['accepted', 'rejected', 'completed'].contains(event.status)
                      ? recipientUserId!
                      : senderUserId!;

              _barterRepository.addMessage(ChatMessageModel(
                barterId: event.barterId,
                userId: application.currentUser!.uid,
                userName: application.currentUser!.displayName,
                message: 'Offer ${event.status.toUpperCase()}',
                dateCreated: DateTime.now(),
              ));

              _notifRepo.sendNotification(
                body: 'Offer ${event.status.toUpperCase()}',
                title: application.currentUserModel!.display_name!,
                receiver: barterRecord.userid1 == _user!.uid
                    ? barterRecord.userid2!
                    : barterRecord.userid1!,
                sender: _user!.uid,
                barterId: barterRecord.barterId!,
              );

              // update products' status
              // final barterProducts =
              //     await _barterRepository.getBarterProducts(event.barterId);

              // if (barterProducts.isNotEmpty &&
              //     barterRecord.dealStatus != 'new') {
              //   final productsToUpdate = barterProducts
              //       .where((bProduct) => !bProduct.productId!.contains('cash'));

              //   for (var product in productsToUpdate) {
              //     final productModel =
              //         await _productRepository.getProduct(product.productId!);

              //     var updatedData =
              //         ProductRequestModel.fromProduct(productModel);

              //     switch (event.status) {
              //       case 'accepted':
              //         updatedData.status = 'reserved';
              //         break;
              //       case 'completed':
              //         updatedData.status = 'sold';
              //         if (product.userId == senderUserId) {
              //           updatedData.acquired_by = recipientUserId;
              //         } else {
              //           updatedData.acquired_by = senderUserId;
              //         }

              //         break;
              //       default:
              //         updatedData.status = 'available';
              //     }

              //     await _productRepository.updateProduct(updatedData);
              //   }
              // }
            }
            emit(UpdateBarterStatusSuccess());
          }

          if (event is UpdateBarterProducts) {
            final barterProducts =
                await _barterRepository.getBarterProducts(event.barterId);
            final _products = event.products;
            barterProducts.forEach((bProduct) {
              final _product = ProductModel.fromJson(bProduct.toJson());
              if (_products.any((_p) => _p.productId == _product.productid)) {
                _products
                    .removeWhere((__p) => __p.productId == _product.productid);
              }
            });
            final success = await _barterRepository.addBarterProducts(
                event.barterId, _products);
            if (success) emit(UpdateBarterProductsSuccess());
          }

          if (event is AddCashOffer) {
            final added = await _barterRepository.addCashOffer(
              event.barterId,
              BarterProductModel(
                productId: 'cash-${DateTime.now().millisecondsSinceEpoch}',
                productName: 'Cash',
                price: event.amount,
                currency: event.currency,
                userId: event.userId,
              ),
            );

            if (added) emit(AddCashOfferSuccess());
          }

          if (event is DeleteCashOffer) {
            print('deleting cash with prodId: ${event.productId}');
            final deleted = await _barterRepository.deleteCashOffer(
              event.barterId,
              BarterProductModel(
                productId: event.productId,
              ),
            );

            if (deleted) emit(DeleteCashOfferSuccess());
          }

          if (event is StreamBarter) {
            final barterRecord = await _barterRepository
                .getBarterRecord(event.barterRecord.barterId!);
            final senderUserId = barterRecord!.userid1Role == 'sender'
                ? barterRecord.userid1
                : barterRecord.userid2;

            final recipientUserId = barterRecord.userid1Role == 'recipient'
                ? barterRecord.userid1
                : barterRecord.userid2;

            final currentUserProducts =
                await _productRepository.getFirstProducts(
              'user',
              sortBy: 'name',
              userId: application.currentUser!.uid,
            );

            final remoteUserProducts =
                await _productRepository.getFirstProducts(
              'user',
              sortBy: 'name',
              userId: senderUserId == application.currentUser!.uid
                  ? recipientUserId!
                  : senderUserId!,
            );

            emit(BarterInitialized(
              barterStream:
                  _barterRepository.streamBarter(event.barterRecord.barterId!),
              currentUserProducts: currentUserProducts,
              remoteUserProducts: remoteUserProducts,
              barterProductsStream: _barterRepository
                  .streamBarterProducts(event.barterRecord.barterId!),
            ));
          }

          if (event is InitializeBarterTransactions) {
            emit(BarterTransactionsInitialized(
              byYouStream:
                  await _barterRepository.streamBartersByUser(_user!.uid),
              fromOthersStream:
                  await _barterRepository.streamBartersFromOthers(_user!.uid),
            ));
          }

          if (event is InitializeBarterChat) {
            final barterChatStream =
                await _barterRepository.streamMessages(event.barterId);
            emit(BarterChatInitialized(
                user: _user!, barterChatStream: barterChatStream));
          }

          if (event is SendMessage) {
            event.message.dateCreated = DateTime.now();
            final _barterRecord = await _barterRepository
                .getBarterRecord(event.message.barterId!);
            final sent = await _barterRepository.addMessage(event.message);

            if (!sent) {
              emit(BarterError('Unable to send message'));
            } else {
              _notifRepo.sendNotification(
                body: event.message.message ?? '',
                title: application.currentUserModel!.display_name!,
                receiver: _barterRecord!.userid1 ==
                        application.currentUserModel!.userid
                    ? _barterRecord.userid2!
                    : _barterRecord.userid1!,
                sender: application.currentUserModel!.userid!,
                barterId: _barterRecord.barterId!,
              );
              emit(SendMessageSuccess());
            }
          }

          if (event is DeleteBarter) {
            final success = await _barterRepository.deleteBarter(event.id);
            if (success)
              emit(DeleteBarterSuccess());
            else
              emit(BarterError('Unable to delete barter record'));
          }

          if (event is DeleteBarterProducts) {
            final success = await _barterRepository.removeBarterProduct(
                event.barterId,
                event.products.map((prod) => prod.productId!).toList());
            if (success) {
              emit(DeleteBarterProductsSuccess());
            }
          }

          if (event is GetUnreadBarterMessages) {
            final messages = await _barterRepository.getUnreadBarterMessages();
            application.unreadBarterMessages = messages;
            emit(GetUnreadBarterMessagesSuccess(messages));
          }

          if (event is MarkMessagesAsRead) {
            final messages = application.unreadBarterMessages
                .where((msg) => msg.barterId == event.barterId)
                .toList();
            final marked = await _barterRepository.markAsRead(
                messages.where((msg) => msg.isRead == false).toList());
            if (marked) {
              emit(MarkMessagesAsReadSuccess());
              add(GetUnreadBarterMessages());
            }
          }
        }
      } catch (e) {
        emit(BarterError(e.toString()));
      }
    });
  }
}

final home = {
  'userid': 'bt5cnkJUqpRm4jtguOWPYTovDrz1',
  'productcount': 10,
  'location': {
    '_longitude': 123.19112,
    '_latitude': 13.6256732,
  },
  'radius': 5000,
  'sortby': 'distance',
  'sortdirection': 'ascending',
  'interests': ['PC11', 'PC10', 'PC06', 'PC01'],
};

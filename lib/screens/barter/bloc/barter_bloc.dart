import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_logs/flutter_logs.dart';
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
import 'package:tapkat/services/firebase.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'package:tapkat/utilities/upload_media.dart';

part 'barter_event.dart';
part 'barter_state.dart';

class BarterBloc extends Bloc<BarterEvent, BarterState> {
  BarterBloc() : super(BarterInitial()) {
    final _productRepository = ProductRepository();
    final _barterRepository = BarterRepository();
    final _userRepo = UserRepository();
    User? _user;
    final _notifRepo = NotificationRepository();
    on<BarterEvent>((event, emit) async {
      print('current event: $event');
      emit(BarterLoading());

      // try {
      _user = application.currentUser;
      if (_user != null) {
        if (event is InitializeBarter) {
          BarterRecordModel? _barterRecord = await _barterRepository
              .getBarterRecord(event.barterData.barterId!);

          print(
              '=== barter id: ${event.barterData.barterId} value: ${_barterRecord != null ? _barterRecord.toJson() : _barterRecord}');

          if (_barterRecord == null) {
            event.barterData.dealStatus = 'new';

            final user1Model =
                await _userRepo.getUser(event.barterData.userid1!);
            final user2Model =
                await _userRepo.getUser(event.barterData.userid2!);

            if (user2Model == null) {
              emit(BarterUserError(
                  'No data found for ${event.barterData.userid2Name}'));
              return;
            }

            if (user1Model == null) {
              emit(BarterUserError(
                  'No data found for ${event.barterData.userid1Name}'));
              return;
            }

            event.barterData.userid1Name = user1Model.display_name;
            event.barterData.userid2Name = user2Model.display_name;

            final product =
                await _productRepository.getProduct(event.barterData.u2P1Id!);

            print('1 remote product::::: ${product!.toJson()}');

            final newBarter =
                await _barterRepository.setBarterRecord(event.barterData);

            var barterProducts = await _barterRepository
                .getBarterProducts(event.barterData.barterId!);

            if (product.status != 'completed') {
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
                    barterid: event.barterData.barterId,
                  )
                ]);
                barterProducts = await _barterRepository
                    .getBarterProducts(event.barterData.barterId!);
              }
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
            final product =
                await _productRepository.getProduct(event.barterData.u2P1Id!);

            print('remote product::::: ${product!.toJson()}');
            if (_barterRecord.dealStatus == 'new') {
              await _barterRepository.deleteBarter(_barterRecord.barterId!,
                  permanent: true);
              add(InitializeBarter(event.barterData));
              return;
            }

            if (['withdrawn', 'rejected', 'completed']
                    .contains(_barterRecord.dealStatus) ||
                (_barterRecord.deletedFor != null &&
                    _barterRecord.deletedFor!
                        .contains(application.currentUser!.uid))) {
              final _barterId = event.barterData.barterId!.split('_');
              var newBarterId = '';
              if (_barterId.length > 1) {
                newBarterId = _barterId[0] +
                    '_' +
                    (int.parse(_barterId[1]) + 1).toString();
              } else {
                newBarterId = _barterId[0] + '_1';
              }
              event.barterData.barterId = newBarterId;
              add(InitializeBarter(event.barterData));
            } else {
              List<BarterProductModel> barterProducts = await _barterRepository
                  .getBarterProducts(_barterRecord.barterId!);
              barterProducts = barterProducts
                  .where((bProd) => !bProd.productId!.contains('cash'))
                  .toList();
              if (barterProducts.isNotEmpty) {
                if (!barterProducts.contains((BarterProductModel bProd) =>
                    bProd.productId == _barterRecord!.u2P1Id)) {
                  final bProd = barterProducts.firstWhere(
                      (bProd) =>
                          !bProd.productId!.contains('cash') &&
                          bProd.userId != application.currentUser!.uid,
                      orElse: () => barterProducts.first);
                  _barterRecord.u2P1Id = bProd.productId;
                  _barterRecord.u2P1Image = bProd.imgUrl;
                  _barterRecord.u2P1Name = bProd.productName;
                  _barterRecord.u2P1Price = (bProd.price ?? 0).toDouble();
                  await _barterRepository.updateBarter(
                      _barterRecord.barterId!, _barterRecord.toJson());
                }
              }

              await _barterRepository.updateBarter(
                  _barterRecord.barterId!, _barterRecord.toJson());
              add(StreamBarter(_barterRecord));
            }
          }
        }

        if (event is RemoveBarter) {
          final removed = await _barterRepository.removeBarter(event.barterId);
          if (removed)
            emit(BarterRemoved());
          else
            emit(BarterError('Unable to remove barter'));
        }

        if (event is GetCurrentUserItems) {
          final list = await _productRepository.getFirstProducts(
            'user',
            sortBy: 'name',
            userId: application.currentUser!.uid,
          );
          emit(GetCurrentUserItemsSuccess(list));
        }

        if (event is RateProduct) {
          final added = await _productRepository.addProductReview(event.review);

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
          event.review.user_image_url =
              userToReview!.photo_url != null ? userToReview.photo_url! : '';
          final added = await _userRepo.addUserReview(event.review);

          if (added) {
            emit(AddUserReviewSuccess());
          } else {
            add(UpdateUserReview(event.review));
          }
        }

        if (event is GetHiddenProducuts) {
          List<ProductModel> hiddenSenderProducts = [];
          List<ProductModel> hiddenRecipientProducts = [];

          if (event.hiddenSenderProducts.isNotEmpty) {
            await Future.forEach(event.hiddenSenderProducts,
                (String prodId) async {
              final product = await _productRepository.getProduct(prodId);
              if (product != null) {
                hiddenSenderProducts.add(product);
              }
            });
          }

          if (event.hiddenRecipientProducts.isNotEmpty) {
            await Future.forEach(event.hiddenRecipientProducts,
                (String prodId) async {
              final product = await _productRepository.getProduct(prodId);
              if (product != null) {
                hiddenRecipientProducts.add(product);
              }
            });
          }

          emit(GetHiddenProducutsDone(
            hiddenSenderProducts: hiddenSenderProducts,
            hiddenRecipientProducts: hiddenRecipientProducts,
          ));
        }

        if (event is UpdateUserReview) {
          final updated = await _userRepo.updateUserReview(event.review);

          if (updated) emit(UpdateUserReviewSuccess());
        }

        if (event is CounterOffer) {
          BarterRecordModel? _barterRecord =
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
            _newBarterRecord.deletedFor = [];

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

              List<BarterProductModel> barterProducts =
                  await _barterRepository.getBarterProducts(event.barterId);
              barterProducts = barterProducts
                  .where((bProd) => !bProd.productId!.contains('cash'))
                  .toList();
              if (barterProducts.isNotEmpty) {
                if (!barterProducts.contains((BarterProductModel bProd) =>
                    bProd.productId == _barterRecord.u2P1Id)) {
                  final bProd = barterProducts.firstWhere(
                      (bProd) =>
                          !bProd.productId!.contains('cash') &&
                          bProd.userId != application.currentUser!.uid,
                      orElse: () => barterProducts.first);
                  _barterRecord.u2P1Id = bProd.productId;
                  _barterRecord.u2P1Image = bProd.imgUrl;
                  _barterRecord.u2P1Name = bProd.productName;
                  _barterRecord.u2P1Price = (bProd.price ?? 0).toDouble();
                  await _barterRepository.updateBarter(
                      event.barterId, _barterRecord.toJson());
                }
              }

              emit(UpdateBarterStatusSuccess());
            } else
              emit(BarterError('unable to counter offer'));
          }
        }

        if (event is UpdateBarterStatus) {
          await _barterRepository.updateBarterStatus(
              event.barterId, event.status);
          BarterRecordModel? barterRecord =
              await _barterRepository.getBarterRecord(event.barterId);
          if (barterRecord != null) {
            // if (['accepted', 'rejected', 'completed']
            //     .contains(event.status)) {
            //   barterRecord.deletedFor = [];

            // }
            // final senderUserId = barterRecord.userid1Role == 'sender'
            //     ? barterRecord.userid1
            //     : barterRecord.userid2;
            // final recipientUserId = barterRecord.userid1Role == 'recipient'
            //     ? barterRecord.userid1
            //     : barterRecord.userid2;

            // String userId =
            //     ['accepted', 'rejected', 'completed'].contains(event.status)
            //         ? recipientUserId!
            //         : senderUserId!;

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

            if (event.status == 'completed') {
              final barterProducts =
                  await _barterRepository.getBarterProducts(event.barterId);
              if (barterProducts.isNotEmpty) {
                Future.forEach(barterProducts,
                    (BarterProductModel bProd) async {
                  final product =
                      await _productRepository.getProduct(bProd.productId!);
                  if (product != null && product.track_stock) {
                    ProductRequestModel newProductRequest =
                        ProductRequestModel.fromProduct(product);
                    if (product.stock_count > 0) {
                      _productRepository.updateProduct(newProductRequest,
                          dealDone: true);
                    } else {
                      newProductRequest.status = 'completed';
                      _productRepository.updateProduct(newProductRequest);
                    }
                  }
                });
              }
            }

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

            List<BarterProductModel> barterProducts =
                await _barterRepository.getBarterProducts(event.barterId);
            barterProducts = barterProducts
                .where((bProd) => !bProd.productId!.contains('cash'))
                .toList();
            if (barterProducts.isNotEmpty) {
              if (!barterProducts.contains((BarterProductModel bProd) =>
                  bProd.productId == barterRecord.u2P1Id)) {
                final bProd = barterProducts.firstWhere(
                    (bProd) =>
                        !bProd.productId!.contains('cash') &&
                        bProd.userId != application.currentUser!.uid,
                    orElse: () => barterProducts.first);
                barterRecord.u2P1Id = bProd.productId;
                barterRecord.u2P1Image = bProd.imgUrl;
                barterRecord.u2P1Name = bProd.productName;
                barterRecord.u2P1Price = (bProd.price ?? 0).toDouble();
                await _barterRepository.updateBarter(
                    event.barterId, barterRecord.toJson());
              }
            }
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
              barterid: event.barterId,
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
              barterid: event.barterId,
            ),
          );

          if (deleted) emit(DeleteCashOfferSuccess());
        }

        if (event is StreamBarter) {
          // try {
          final barterRecord = await _barterRepository
              .getBarterRecord(event.barterRecord.barterId!);

          final product =
              await _productRepository.getProduct(barterRecord!.u2P1Id!);

          if (product == null) {
            emit(BarterUserError(
                'This barter is no longer valid as one or more of the items cannot be retrieved'));
            return;
          }

          final senderUserId = barterRecord.userid1Role == 'sender'
              ? barterRecord.userid1
              : barterRecord.userid2;

          final recipientUserId = barterRecord.userid1Role == 'recipient'
              ? barterRecord.userid1
              : barterRecord.userid2;

          final currentUserProducts = await _productRepository.getFirstProducts(
            'user',
            sortBy: 'name',
            userId: application.currentUser!.uid,
            itemCount: 10,
          );

          final remoteUserProducts = await _productRepository.getFirstProducts(
            'user',
            sortBy: 'name',
            userId: senderUserId == application.currentUser!.uid
                ? recipientUserId!
                : senderUserId!,
            itemCount: 10,
          );

          BarterRecordModel? _barterRecord = await _barterRepository
              .getBarterRecord(event.barterRecord.barterId!);
          if (_barterRecord != null) {
            List<BarterProductModel> barterProducts = await _barterRepository
                .getBarterProducts(event.barterRecord.barterId!);
            barterProducts = barterProducts
                .where((bProd) => !bProd.productId!.contains('cash'))
                .toList();
            if (barterProducts.isNotEmpty) {
              if (!barterProducts.contains((BarterProductModel bProd) =>
                  bProd.productId == _barterRecord.u2P1Id)) {
                final bProd = barterProducts.firstWhere(
                    (bProd) =>
                        !bProd.productId!.contains('cash') &&
                        bProd.userId != application.currentUser!.uid,
                    orElse: () => barterProducts.first);
                _barterRecord.u2P1Id = bProd.productId;
                _barterRecord.u2P1Image = bProd.imgUrl;
                _barterRecord.u2P1Name = bProd.productName;
                _barterRecord.u2P1Price = (bProd.price ?? 0).toDouble();
                await _barterRepository.updateBarter(
                    event.barterRecord.barterId!, _barterRecord.toJson());
              }
            }
          }

          emit(BarterInitialized(
            barterStream:
                _barterRepository.streamBarter(event.barterRecord.barterId!),
            currentUserProducts: currentUserProducts,
            remoteUserProducts: remoteUserProducts,
            barterProductsStream: _barterRepository
                .streamBarterProducts(event.barterRecord.barterId!),
            existing: true,
          ));
          // } catch (e) {
          //   emit(BarterError(e.toString()));
          // }
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

          List<String> fileUrls = [];
          if (event.message.imagesFile != null &&
              event.message.imagesFile!.isNotEmpty) {
            final files = event.message.imagesFile!;
            await Future.forEach(files, (SelectedMedia file) async {
              final url = await uploadData(file.storagePath, file.bytes);
              fileUrls.add(url!);
            });
          }

          event.message.images = fileUrls;

          final _barterRecord =
              await _barterRepository.getBarterRecord(event.message.barterId!);
          final sent = await _barterRepository.addMessage(event.message);

          if (!sent) {
            emit(BarterError('Unable to send message'));
          } else {
            _notifRepo.sendNotification(
              body: event.message.message ?? '',
              title: application.currentUserModel!.display_name!,
              receiver:
                  _barterRecord!.userid1 == application.currentUserModel!.userid
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
            // check if thumbnail still exists on barter products
            BarterRecordModel? _barterRecord =
                await _barterRepository.getBarterRecord(event.barterId);
            if (_barterRecord != null) {
              List<BarterProductModel> barterProducts =
                  await _barterRepository.getBarterProducts(event.barterId);
              barterProducts = barterProducts
                  .where((bProd) => !bProd.productId!.contains('cash'))
                  .toList();
              if (barterProducts.isNotEmpty) {
                if (!barterProducts.contains((BarterProductModel bProd) =>
                    bProd.productId == _barterRecord.u2P1Id)) {
                  final bProd = barterProducts.firstWhere(
                      (bProd) =>
                          !bProd.productId!.contains('cash') &&
                          bProd.userId != application.currentUser!.uid,
                      orElse: () => barterProducts.first);
                  _barterRecord.u2P1Id = bProd.productId;
                  _barterRecord.u2P1Image = bProd.imgUrl;
                  _barterRecord.u2P1Name = bProd.productName;
                  _barterRecord.u2P1Price = (bProd.price ?? 0).toDouble();
                  await _barterRepository.updateBarter(
                      event.barterId, _barterRecord.toJson());
                }
              }
            }

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
      // } catch (e) {
      //   emit(BarterError(e.toString()));
      //   FlutterLogs.logToFile(
      //       logFileName: "Home Bloc",
      //       overwrite: false,
      //       logMessage: e.toString());
      // }
    });
  }

  List<ChatMessageModel> unreadMessages = [];
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

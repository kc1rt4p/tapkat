import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/models/barter_product.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/chat_message.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/repositories/barter_repository.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/schemas/barter_record.dart';
import 'package:tapkat/services/auth_service.dart';

part 'barter_event.dart';
part 'barter_state.dart';

class BarterBloc extends Bloc<BarterEvent, BarterState> {
  BarterBloc() : super(BarterInitial()) {
    final _authService = AuthService();
    final _productRepository = ProductRepository();
    final _barterRepository = BarterRepository();
    final _userRepo = UserRepository();
    User? _user;
    on<BarterEvent>((event, emit) async {
      print('current event: $event');
      emit(BarterLoading());

      try {
        _user = await _authService.getCurrentUser();

        if (_user != null) {
          if (event is InitializeBarter) {
            print('=== barter id: ${event.barterData.barterId}');
            final _barterRecord = await _barterRepository
                .getBarterRecord(event.barterData.barterId!);
            print('=== _barterRecord: $_barterRecord');

            if (_barterRecord == null) {
              event.barterData.dealStatus = 'new';
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

              final senderUserId = _barterRecord!.userid1Role == 'sender'
                  ? _barterRecord.userid1
                  : _barterRecord.userid2;

              final recipientUserId = _barterRecord.userid1Role == 'recipient'
                  ? _barterRecord.userid1
                  : _barterRecord.userid2;

              final senderProducts = await _productRepository.getFirstProducts(
                  'user', senderUserId);

              final recipientProducts = await _productRepository
                  .getFirstProducts('user', recipientUserId);

              emit(BarterInitialized(
                barterStream:
                    _barterRepository.streamBarter(event.barterData.barterId!),
                senderProducts: senderProducts,
                recipientProducts: recipientProducts,
                barterProductsStream: _barterRepository
                    .streamBarterProducts(event.barterData.barterId!),
              ));
            } else {
              print('EXISTING BARTER');
              add(StreamBarter(_barterRecord));
            }
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
              _newBarterRecord.dealStatus = 'submitted';
              _newBarterRecord.u2P1Id = event.product.productId;
              _newBarterRecord.u2P1Name = event.product.productName;
              _newBarterRecord.u2P1Price = event.product.price != null
                  ? double.parse(event.product.price.toString())
                  : 0;
              _newBarterRecord.u2P1Image = event.product.imgUrl;

              final updated =
                  await _barterRepository.counterOffer(_newBarterRecord);

              if (updated)
                emit(UpdateBarterStatusSuccess());
              else
                emit(BarterError('unable to counter offer'));
            }
          }

          if (event is UpdateBarterStatus) {
            await _barterRepository.updateBarterStatus(
                event.barterId, event.status);
            if (event.status != 'new') {
              final barterRecord =
                  await _barterRepository.getBarterRecord(event.barterId);
              if (barterRecord != null) {
                final userId =
                    ['accepted', 'rejected', 'sold'].contains(event.status)
                        ? barterRecord.userid2!
                        : barterRecord.userid1!;
                final user = await _userRepo.getUser(userId);

                _barterRepository.addMessage(ChatMessageModel(
                  barterId: event.barterId,
                  userId: userId,
                  userName: user!.firstname,
                  message: 'Offer ${event.status.toUpperCase()}',
                  dateCreated: DateTime.now(),
                ));
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
            final senderUserId = event.barterRecord.userid1Role == 'sender'
                ? event.barterRecord.userid1
                : event.barterRecord.userid2;

            final recipientUserId =
                event.barterRecord.userid1Role == 'recipient'
                    ? event.barterRecord.userid1
                    : event.barterRecord.userid2;

            final senderProducts =
                await _productRepository.getFirstProducts('user', senderUserId);

            final recipientProducts = await _productRepository.getFirstProducts(
                'user', recipientUserId);

            emit(BarterInitialized(
              barterStream:
                  _barterRepository.streamBarter(event.barterRecord.barterId!),
              senderProducts: senderProducts,
              recipientProducts: recipientProducts,
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
            final user = await _userRepo.getUser(_user!.uid);
            event.message.userId = _user!.uid;
            event.message.userName = user!.firstname;
            event.message.dateCreated = DateTime.now();
            final sent = await _barterRepository.addMessage(event.message);
            if (!sent) {
              emit(BarterError('Unable to send message'));
            } else {
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
        }
      } catch (e) {
        emit(BarterError(e.toString()));
      }
    });
  }
}

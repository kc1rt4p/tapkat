import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/backend.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/chat_message.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/repositories/barter_repository.dart';
import 'package:tapkat/repositories/product_repository.dart';
import 'package:tapkat/schemas/barter_record.dart';
import 'package:tapkat/services/auth_service.dart';

part 'barter_event.dart';
part 'barter_state.dart';

class BarterBloc extends Bloc<BarterEvent, BarterState> {
  BarterBloc() : super(BarterInitial()) {
    final _authService = AuthService();
    final _productRepository = ProductRepository();
    final _barterRepository = BarterRepository();
    User? _user;
    on<BarterEvent>((event, emit) async {
      emit(BarterLoading());

      try {
        _user = await _authService.getCurrentUser();

        if (_user != null) {
          if (event is InitializeBarter) {
            final userProducts = await _productRepository.getFirstProducts(
                'user', event.barterData.userid1);

            final user2Products = await _productRepository.getFirstProducts(
                'user', event.barterData.userid2);

            print("======BARTER DATA:: ${event.barterData}");

            // final _barterRef =
            //     await BarterRecord.collection.doc().set(event.barterData);
            // final barterData = BarterRecordModel.fromJson(event.barterData);
            final newBarter =
                await _barterRepository.setBarterRecord(event.barterData);

            print('new barter data ${event.barterData.toJson()}');
            print('success: $newBarter');

            emit(
              BarterInitialized(
                barterStream: queryBarterRecord(
                  queryBuilder: (barterRecord) => barterRecord.where('barterid',
                      isEqualTo: event.barterData.barterId),
                  singleRecord: true,
                ),
                userProducts: userProducts,
                user2Products: user2Products,
              ),
            );
          }

          if (event is StreamBarter) {
            final userProducts = await _productRepository.getFirstProducts(
                'user', event.barterRecord.userid1);

            final user2Products = await _productRepository.getFirstProducts(
                'user', event.barterRecord.userid2);
            final stream = await _barterRepository
                .streamBarter(event.barterRecord.barterId!);
            emit(
              BarterInitialized(
                barterStream: queryBarterRecord(
                  queryBuilder: (barterRecord) => barterRecord.where(
                    'barterid',
                    isEqualTo: event.barterRecord.barterId,
                  ),
                  singleRecord: true,
                ),
                userProducts: userProducts,
                user2Products: user2Products,
              ),
            );
          }

          if (event is InitializeBarterTransactions) {
            final byYouList =
                await _barterRepository.getBartersByUser(_user!.uid);
            final fromOthersList =
                await _barterRepository.getBartersFromOthers(_user!.uid);

            emit(BarterTransactionsInitialized(
              fromOthersList: fromOthersList,
              byYouList: byYouList,
            ));
          }

          if (event is InitializeBarterChat) {
            final barterChatStream =
                await _barterRepository.streamMessages(event.barterId);
            emit(BarterChatInitialized(
                user: _user!, barterChatStream: barterChatStream));
          }

          if (event is SendMessage) {
            event.message.userId = _user!.uid;
            event.message.userName = _user!.displayName;
            final sent = await _barterRepository.addMessage(event.message);
            if (!sent) {
              emit(BarterError('Unable to send message'));
            } else {
              emit(SendMessageSuccess());
            }
          }
        }
      } catch (e) {
        emit(BarterError(e.toString()));
      }
    });
  }
}

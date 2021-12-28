import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/chat_message.dart';

class BarterRepository {
  final barterRef = FirebaseFirestore.instance.collection('barter');

  Future<Stream<List<ChatMessageModel>>> streamMessages(String barterId) async {
    final barterDoc =
        await barterRef.where('barterid', isEqualTo: barterId).limit(1).get();
    final barterData = barterDoc.docs.first;

    return barterRef.doc(barterData.id).collection('messages').snapshots().map(
          (s) => s.docs
              .map(
                (doc) => ChatMessageModel.fromJson(
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<Stream<BarterRecordModel?>> streamBarter(String barterId) async {
    final doc =
        await barterRef.where('barterid', isEqualTo: barterId).limit(1).get();

    final barter = doc.docs.first;

    return barterRef.doc(barter.id).snapshots().map((doc) {
      final data = doc.data();

      if (data != null) {
        final record = BarterRecordModel.fromJson(data);
        record.barterId = doc.id;
      }
    });
  }

  Future<List<BarterRecordModel>> getBartersByUser(String userId) async {
    final a = await barterRef.where('userid1', isEqualTo: userId).get();
    if (a.docs.isEmpty) return [];

    return a.docs.map((doc) => BarterRecordModel.fromJson(doc.data())).toList();
  }

  Future<List<BarterRecordModel>> getBartersFromOthers(String userId) async {
    final a = await barterRef.where('userid2', isEqualTo: userId).get();
    if (a.docs.isEmpty) return [];

    return a.docs.map((doc) => BarterRecordModel.fromJson(doc.data())).toList();
  }

  Future<bool> addMessage(ChatMessageModel message) async {
    final doc = await barterRef
        .where('barterid', isEqualTo: message.barterId)
        .limit(1)
        .get();

    print('====== DOC: $doc');

    if (doc.size < 1) {
      return false;
    }

    final barter = doc.docs.first;

    final messageData = message.toJson();

    messageData['dateCreated'] = FieldValue.serverTimestamp();

    final newRecord = await barterRef
        .doc(barter.id)
        .collection('messages')
        .add(message.toJson());

    return true;
  }
}

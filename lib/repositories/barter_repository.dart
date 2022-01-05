import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/chat_message.dart';

class BarterRepository {
  final barterRef = FirebaseFirestore.instance.collection('barter');

  Future<bool> setBarterRecord(BarterRecordModel barterRecord) async {
    final doc =
        await barterRef.doc(barterRecord.barterId).set(barterRecord.toJson());

    final docSnapshot = await barterRef.doc(barterRecord.barterId).get();

    if (!docSnapshot.exists) return false;

    return true;
  }

  Future<Stream<List<ChatMessageModel>>> streamMessages(String barterId) async {
    return barterRef
        .doc(barterId)
        .collection('messages')
        .orderBy(
          'dateCreated',
          descending: false,
        )
        .snapshots()
        .map(
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
    return barterRef.doc(barterId).snapshots().map((doc) {
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
    final messageData = message.toJson();

    try {
      final newRecord = await barterRef
          .doc(message.barterId)
          .collection('messages')
          .add(message.toJson());

      return true;
    } catch (e) {
      return false;
    }
  }
}

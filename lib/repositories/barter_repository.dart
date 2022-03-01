import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapkat/models/barter_product.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/chat_message.dart';

class BarterRepository {
  final barterRef = FirebaseFirestore.instance.collection('barter');

  Future<bool> setBarterRecord(BarterRecordModel barterRecord) async {
    await barterRef.doc(barterRecord.barterId).set(barterRecord.toJson());

    final docSnapshot = await barterRef.doc(barterRecord.barterId).get();

    if (!docSnapshot.exists) return false;

    return true;
  }

  Future<List<BarterProductModel>> getBarterProducts(String barterId) async {
    final q = await barterRef.doc(barterId).collection('products').get();
    if (q.docs.isEmpty) return [];

    return q.docs
        .map((snapshot) => BarterProductModel.fromJson(snapshot.data()))
        .toList();
  }

  Stream<List<BarterProductModel>> streamBarterProducts(String barterId) {
    return barterRef.doc(barterId).collection('products').snapshots().map(
        (query) => query.docs
            .map((doc) => BarterProductModel.fromJson(doc.data()))
            .toList());
  }

  Future<BarterRecordModel?> getBarterRecord(String barterId) async {
    try {
      final docSnapshot = await barterRef.doc(barterId).get();

      return BarterRecordModel.fromJson(docSnapshot.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<bool> counterOffer(BarterRecordModel barterRecord) async {
    try {
      final _doc = barterRef.doc(barterRecord.barterId);
      await _doc.update(barterRecord.toJson());
      return true;
    } catch (e) {
      print('ERROR COUNTERING OFFER: ${e.toString()}');
      return false;
    }
  }

  Future<bool> addCashOffer(
      String barterId, BarterProductModel barterProduct) async {
    final existingProducts = await barterRef
        .doc(barterId)
        .collection('products')
        .where('userid', isEqualTo: barterProduct.userId)
        .get();

    if (existingProducts.docs.isNotEmpty) {
      existingProducts.docs.forEach((doc) async {
        final product = BarterProductModel.fromJson(doc.data());
        if (product.productId!.contains('cash')) {
          await barterRef
              .doc(barterId)
              .collection('products')
              .doc(doc.id)
              .delete();
        }
      });
    }

    barterProduct.dateAdded = DateTime.now();
    final docRef = await barterRef
        .doc(barterId)
        .collection('products')
        .add(barterProduct.toJson());

    final newOffer = await docRef.get();

    return newOffer.exists;
  }

  Future<bool> deleteCashOffer(
      String barterId, BarterProductModel barterProduct) async {
    final snapshot = await barterRef
        .doc(barterId)
        .collection('products')
        .where('productid', isEqualTo: barterProduct.productId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    final doc = snapshot.docs.first;

    try {
      await barterRef.doc(barterId).collection('products').doc(doc.id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addBarterProducts(
      String barterId, List<BarterProductModel> products) async {
    try {
      products.forEach((product) async {
        await barterRef
            .doc(barterId)
            .collection('products')
            .add(product.toJson());
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeBarterProduct(
      String barterId, List<String> productIds) async {
    try {
      print('barterId: $barterId');
      productIds.forEach((pId) async {
        final prod = await barterRef
            .doc(barterId)
            .collection('products')
            .where('productid', isEqualTo: pId)
            .get();
        if (prod.docs.length > 0) {
          await barterRef
              .doc(barterId)
              .collection('products')
              .doc(prod.docs.first.id)
              .delete();
        }
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateBarterStatus(String barterId, String status) async {
    try {
      await barterRef.doc(barterId).update({
        'dealStatus': status,
        'dealDate': DateTime.now(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<BarterRecordModel?> streamBarter(String barterId) {
    return barterRef.doc(barterId).snapshots().map((docSnapshot) =>
        docSnapshot.data() != null
            ? BarterRecordModel.fromJson(docSnapshot.data()!)
            : null);
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

  // Future<Stream<BarterRecordModel?>> streamBarter(String barterId) async {
  //   return barterRef.doc(barterId).snapshots().map((doc) {
  //     final data = doc.data();

  //     if (data != null) {
  //       final record = BarterRecordModel.fromJson(data);
  //       record.barterId = doc.id;
  //     }
  //   });
  // }

  Future<List<BarterRecordModel>> getBartersByUser(String userId) async {
    final a = await barterRef.where('userid1', isEqualTo: userId).get();
    if (a.docs.isEmpty) return [];

    return a.docs.map((doc) => BarterRecordModel.fromJson(doc.data())).toList();
  }

  Future<Stream<List<BarterRecordModel>>> streamBartersByUser(
      String userId) async {
    return barterRef
        .where('userid1', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              return BarterRecordModel.fromJson(doc.data());
            }).toList());
  }

  Future<Stream<List<BarterRecordModel>>> streamBartersFromOthers(
      String userId) async {
    return barterRef.where('userid2', isEqualTo: userId).snapshots().map((s) =>
        s.docs.map((doc) => BarterRecordModel.fromJson(doc.data())).toList());
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

  Future<bool> deleteBarter(String id) async {
    try {
      final messages = await barterRef.doc(id).collection('messages').get();
      if (messages.docs.isNotEmpty) {
        messages.docs.forEach((msg) async {
          await barterRef.doc(id).collection('messages').doc(msg.id).delete();
        });
      }

      final products = await barterRef.doc(id).collection('products').get();
      if (products.docs.isNotEmpty) {
        products.docs.forEach((prod) async {
          await barterRef.doc(id).collection('products').doc(prod.id).delete();
        });
      }

      await barterRef.doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}

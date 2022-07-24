import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapkat/models/barter_product.dart';
import 'package:tapkat/models/barter_record_model.dart';
import 'package:tapkat/models/chat_message.dart';
import 'package:tapkat/utilities/application.dart' as application;

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

      if (docSnapshot.exists) if (docSnapshot.data() != null &&
          docSnapshot.data()!['barterId'] != null)
        return BarterRecordModel.fromJson(docSnapshot.data()!);

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> doesBarterExist(String barterId) async {
    final barterDoc = await barterRef.doc(barterId).get();

    if (!barterDoc.exists) return false;

    final barterRecord = BarterRecordModel.fromJson(barterDoc.data()!);

    if (barterRecord.deletedFor != null &&
        barterRecord.deletedFor!.contains(application.currentUser!.uid))
      return false;

    return true;
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

  Future<bool> updateBarter(String barterId, Map<String, dynamic> data) async {
    try {
      await barterRef.doc(barterId).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkIfBarterable(
      String userId, String productId, String barterId) async {
    final querySnapshot = await barterRef.get();
    bool exists = false;

    if (querySnapshot.docs.isEmpty) return true;

    final barters = querySnapshot.docs
        .map((doc) => BarterRecordModel.fromJson(doc.data()))
        .toList();

    final openBarters = barters
        .where((barter) =>
            barter.dealStatus != 'completed' &&
            barter.dealStatus != 'rejected' &&
            barter.dealStatus != 'withdrawn' &&
            (barter.deletedFor == null ||
                (barter.deletedFor != null &&
                    !barter.deletedFor!
                        .contains(application.currentUser!.uid))))
        .toList();

    final usersInvolved = [userId, application.currentUser!.uid];

    final openBartersForUsersInvolved = openBarters
        .where((barter) =>
            usersInvolved.contains(barter.userid1) &&
            usersInvolved.contains(barter.userid2))
        .toList();

    if (openBartersForUsersInvolved.isEmpty) return true;

    await Future.forEach(openBartersForUsersInvolved,
        (BarterRecordModel barter) async {
      if (barter.barterId != barterId) {
        final docSnapshot =
            await barterRef.doc(barter.barterId).collection('products').get();

        if (docSnapshot.docs.isNotEmpty) {
          final products = docSnapshot.docs
              .map((doc) => BarterProductModel.fromJson(doc.data()))
              .toList();

          if (products.any((prod) => prod.productId == productId)) {
            exists = true;
          }
        }
      }
    });

    return exists ? false : true;
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

  Future<bool> markAsRead(List<ChatMessageModel> list) async {
    try {
      await Future.forEach<ChatMessageModel>(list, (msg) async {
        print('000--- ${msg.toJson()}');
        await barterRef
            .doc(msg.barterId)
            .collection('messages')
            .doc(msg.id)
            .update({'is_read': true});
      });

      return true;
    } catch (e) {
      print('_-=error: ${e.toString()}');
      return false;
    }
  }

  Future<List<ChatMessageModel>> getUnreadBarterMessages() async {
    List<BarterRecordModel> barters = [];
    barters.addAll(await getBartersByUser(application.currentUser!.uid));
    barters.addAll(await getBartersFromOthers(application.currentUser!.uid));
    List<ChatMessageModel> _unreadMessages = [];

    await Future.forEach<BarterRecordModel>(barters, (barter) async {
      final msgs = await barterRef
          .doc(barter.barterId)
          .collection('messages')
          .where('is_read', isNotEqualTo: true)
          .get();
      if (msgs.docs.isNotEmpty) {
        _unreadMessages.addAll(
          msgs.docs.map(
            (msg) {
              print('_-== ${ChatMessageModel.fromJson(msg.data()).toJson()}');
              return ChatMessageModel.fromJson(msg.data())..id = msg.id;
            },
          ),
        );
      }
    });

    _unreadMessages = _unreadMessages
        .where((chat) => chat.userId != application.currentUser!.uid)
        .toList();

    print('_-=msgforuser ${_unreadMessages.length} -==-');
    return _unreadMessages;
  }

  Future<bool> updateBarterStatus(String barterId, String status) async {
    Map<String, dynamic> data = {
      'dealStatus': status,
      'dealDate': DateTime.now(),
    };

    if (['accepted', 'rejected', 'completed'].contains(status)) {
      data.addAll({
        'deletedFor': [],
      });
    }
    try {
      await barterRef.doc(barterId).update(data);
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
                )..id = doc.id,
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
    try {
      await barterRef
          .doc(message.barterId)
          .collection('messages')
          .add(message.toJson());

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeBarter(String barterId) async {
    try {
      final barterRecord = await getBarterRecord(barterId);
      final messages =
          await barterRef.doc(barterId).collection('messages').get();
      if (messages.docs.isNotEmpty) {
        messages.docs.forEach((msg) async {
          await barterRef
              .doc(barterId)
              .collection('messages')
              .doc(msg.id)
              .delete();
        });
      }

      final products =
          await barterRef.doc(barterId).collection('products').get();
      if (products.docs.isNotEmpty) {
        await Future.forEach(products.docs,
            (QueryDocumentSnapshot<Map<String, dynamic>> prod) async {
          final product = BarterProductModel.fromJson(prod.data());
          if (product.productId != barterRecord!.u2P1Id) {
            await barterRef
                .doc(barterId)
                .collection('products')
                .doc(prod.id)
                .delete();
          }
        });

        // BarterRecordModel? barterRecord = await getBarterRecord(barterId);

        // if (barterRecord != null) {
        //   barterRecord.deletedFor = [];
        //   barterRecord.dealStatus = 'new';
        //   barterRecord.dealDate = DateTime.now();

        //   await barterRef.doc(barterId).update(barterRecord.toJson());
        // }

        // products.docs.forEach((prod) async {
        //   await barterRef
        //       .doc(barterId)
        //       .collection('products')
        //       .doc(prod.id)
        //       .delete();
        // });
      }
      // await barterRef.doc(barterId).delete();

      await updateBarterStatus(barterId, 'new');

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBarter(String id) async {
    try {
      await barterRef.doc(id).update({
        'deletedFor': [application.currentUser!.uid],
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}

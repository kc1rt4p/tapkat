import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapkat/models/store_like.dart';

class StoreRepository {
  final barterRef = FirebaseFirestore.instance.collection('userstore_likes');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamStoreLike(
    String storeId,
    String likerId,
  ) {
    return barterRef
        .where('userid', isEqualTo: storeId)
        .where('likerid', isEqualTo: likerId)
        .snapshots();
  }
}

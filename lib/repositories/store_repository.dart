import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapkat/models/store_like.dart';

class StoreRepository {
  final barterRef = FirebaseFirestore.instance.collection('userstore_likes');

  Stream<StoreLikeModel?> streamStoreLike(
    String storeId,
    String likerId,
  ) {
    return barterRef
        .where('userid', isEqualTo: storeId)
        .where('likerid', isEqualTo: likerId)
        .snapshots()
        .map((docSnapshot) {
      if (docSnapshot.docs.isNotEmpty) {
        final doc = docSnapshot.docs.first;
        return StoreLikeModel.fromJson(doc.data());
      }

      return null;
    });
  }
}

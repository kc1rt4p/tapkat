import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapkat/schemas/barter_items_record.dart';
import 'package:tapkat/schemas/barter_record.dart';
import 'package:tapkat/schemas/product_markers_record.dart';
import 'package:tapkat/schemas/serializers.dart';
import 'package:tapkat/schemas/user_likes_record.dart';
import 'package:tapkat/schemas/users_record.dart';
import 'package:tapkat/utilities/helper.dart';

Stream<List<ProductMarkersRecord?>> queryProductMarkersRecord(
        {Query Function(Query)? queryBuilder,
        int limit = -1,
        bool singleRecord = false}) =>
    queryCollection(
        ProductMarkersRecord.collection, ProductMarkersRecord.serializer,
        queryBuilder: queryBuilder, limit: limit, singleRecord: singleRecord);

Stream<List<UsersRecord?>> queryUsersRecord(
        {Query Function(Query)? queryBuilder,
        int limit = -1,
        bool singleRecord = false}) =>
    queryCollection(UsersRecord.collection, UsersRecord.serializer,
        queryBuilder: queryBuilder, limit: limit, singleRecord: singleRecord);

Stream<List<BarterRecord?>> queryBarterRecord(
        {Query Function(Query)? queryBuilder,
        int limit = -1,
        bool singleRecord = false}) =>
    queryCollection(BarterRecord.collection, BarterRecord.serializer,
        queryBuilder: queryBuilder, limit: limit, singleRecord: singleRecord);

Stream<List<BarterItemsRecord?>> queryBarterItemsRecord(
        {Query Function(Query)? queryBuilder,
        int limit = -1,
        bool singleRecord = false}) =>
    queryCollection(BarterItemsRecord.collection, BarterItemsRecord.serializer,
        queryBuilder: queryBuilder, limit: limit, singleRecord: singleRecord);

Stream<List<UserLikesRecord?>> queryUserLikesRecord(
        {Query Function(Query)? queryBuilder,
        int limit = -1,
        bool singleRecord = false}) =>
    queryCollection(UserLikesRecord.collection, UserLikesRecord.serializer,
        queryBuilder: queryBuilder, limit: limit, singleRecord: singleRecord);

Stream<List<T?>> queryCollection<T>(
    CollectionReference collection, Serializer<T> serializer,
    {Query Function(Query)? queryBuilder,
    int limit = -1,
    bool singleRecord = false}) {
  final builder = queryBuilder ?? (q) => q;
  var query = builder(collection);
  if (limit > 0 || singleRecord) {
    query = query.limit(singleRecord ? 1 : limit);
  }
  return query.snapshots().map((s) => s.docs
      .map(
        (d) => safeGet(
          () => serializers.deserializeWith(serializer, serializedData(d)),
          (e) => print('Error serializing doc ${d.reference.path}:\n$e'),
        ),
      )
      .where((d) => d != null)
      .toList());
}

// Creates a Firestore record representing the logged in user if it doesn't yet exist
Future maybeCreateUser(User user) async {
  final userRecord = UsersRecord.collection.doc(user.uid);
  final userExists = await userRecord.get().then((u) => u.exists);

  if (userExists) {
    return;
  }

  final userData = createUsersRecordData(
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    uid: user.uid,
    phoneNumber: user.phoneNumber,
    createdTime: getCurrentTimestamp,
  );

  await userRecord.set(userData);
}

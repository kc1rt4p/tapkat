import 'dart:async';

import 'package:built_value/built_value.dart';

import 'serializers.dart';

part 'user_likes_record.g.dart';

abstract class UserLikesRecord
    implements Built<UserLikesRecord, UserLikesRecordBuilder> {
  static Serializer<UserLikesRecord> get serializer =>
      _$userLikesRecordSerializer;

  String? get userid;

  String? get productid;

  String? get productname;

  double? get price;

  @BuiltValueField(wireName: 'image_url')
  String? get imageUrl;

  bool? get liked;

  @BuiltValueField(wireName: kDocumentReferenceField)
  DocumentReference? get reference;

  static void _initializeBuilder(UserLikesRecordBuilder builder) => builder
    ..userid = ''
    ..productid = ''
    ..productname = ''
    ..price = 0.0
    ..imageUrl = ''
    ..liked = false;

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('user_likes');

  static Stream<UserLikesRecord?> getDocument(DocumentReference ref) => ref
      .snapshots()
      .map((s) => serializers.deserializeWith(serializer, serializedData(s)));

  UserLikesRecord._();
  factory UserLikesRecord([void Function(UserLikesRecordBuilder) updates]) =
      _$UserLikesRecord;

  static UserLikesRecord? getDocumentFromData(
          Map<String, dynamic> data, DocumentReference reference) =>
      serializers.deserializeWith(serializer,
          {...mapFromFirestore(data), kDocumentReferenceField: reference});
}

Map<String, dynamic> createUserLikesRecordData({
  String? userid,
  String? productid,
  String? productname,
  double? price,
  String? imageUrl,
  bool? liked,
}) =>
    serializers.toFirestore(
        UserLikesRecord.serializer,
        UserLikesRecord((u) => u
          ..userid = userid
          ..productid = productid
          ..productname = productname
          ..price = price
          ..imageUrl = imageUrl
          ..liked = liked));

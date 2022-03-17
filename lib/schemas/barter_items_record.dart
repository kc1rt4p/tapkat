import 'dart:async';

import 'package:built_value/built_value.dart';

import 'serializers.dart';

part 'barter_items_record.g.dart';

abstract class BarterItemsRecord
    implements Built<BarterItemsRecord, BarterItemsRecordBuilder> {
  static Serializer<BarterItemsRecord> get serializer =>
      _$barterItemsRecordSerializer;

  String? get barterid;

  String? get userid;

  String? get productid;

  String? get productname;

  double? get price;

  @BuiltValueField(wireName: 'image_url')
  String? get imageUrl;

  @BuiltValueField(wireName: kDocumentReferenceField)
  DocumentReference get reference;

  static void _initializeBuilder(BarterItemsRecordBuilder builder) => builder
    ..barterid = ''
    ..userid = ''
    ..productid = ''
    ..productname = ''
    ..price = 0.0
    ..imageUrl = '';

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('barter_items');

  static Stream<BarterItemsRecord?> getDocument(DocumentReference ref) => ref
      .snapshots()
      .map((s) => serializers.deserializeWith(serializer, serializedData(s)));

  BarterItemsRecord._();
  factory BarterItemsRecord([void Function(BarterItemsRecordBuilder) updates]) =
      _$BarterItemsRecord;

  static BarterItemsRecord? getDocumentFromData(
          Map<String, dynamic> data, DocumentReference reference) =>
      serializers.deserializeWith(serializer,
          {...mapFromFirestore(data), kDocumentReferenceField: reference});
}

Map<String, dynamic> createBarterItemsRecordData({
  String? userid,
  String? barterid,
  String? productid,
  String? productname,
  double? price,
  String? imageUrl,
}) =>
    serializers.toFirestore(
        BarterItemsRecord.serializer,
        BarterItemsRecord((b) => b
          ..barterid = barterid
          ..userid = userid
          ..productid = productid
          ..productname = productname
          ..price = price
          ..imageUrl = imageUrl));

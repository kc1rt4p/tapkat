import 'dart:async';

import 'package:built_value/built_value.dart';

import 'serializers.dart';

part 'barter_record.g.dart';

abstract class BarterRecord
    implements Built<BarterRecord, BarterRecordBuilder> {
  static Serializer<BarterRecord> get serializer => _$barterRecordSerializer;

  String? get userid1;

  String? get userid2;

  @BuiltValueField(wireName: 'user1_accepted')
  bool? get user1Accepted;

  @BuiltValueField(wireName: 'user2_accepted')
  bool? get user2Accepted;

  @BuiltValueField(wireName: 'u1_p1_id')
  String? get u1P1Id;

  @BuiltValueField(wireName: 'u1_p1_name')
  String? get u1P1Name;

  @BuiltValueField(wireName: 'u1_p1_price')
  double? get u1P1Price;

  @BuiltValueField(wireName: 'u2_p1_id')
  String? get u2P1Id;

  @BuiltValueField(wireName: 'u2_p1_name')
  String? get u2P1Name;

  @BuiltValueField(wireName: 'u2_p1_price')
  double? get u2P1Price;

  @BuiltValueField(wireName: 'proposed_by')
  String? get proposedBy;

  @BuiltValueField(wireName: 'last_proposed_date')
  DateTime? get lastProposedDate;

  @BuiltValueField(wireName: 'deal_status')
  String? get dealStatus;

  @BuiltValueField(wireName: 'deal_date')
  DateTime? get dealDate;

  @BuiltValueField(wireName: 'u1_p1_image')
  String? get u1P1Image;

  @BuiltValueField(wireName: 'u2_p1_image')
  String? get u2P1Image;

  String? get barterid;

  @BuiltValueField(wireName: 'barter_no')
  int? get barterNo;

  @BuiltValueField(wireName: kDocumentReferenceField)
  DocumentReference? get reference;

  static void _initializeBuilder(BarterRecordBuilder builder) => builder
    ..userid1 = ''
    ..userid2 = ''
    ..user1Accepted = false
    ..user2Accepted = false
    ..u1P1Id = ''
    ..u1P1Name = ''
    ..u1P1Price = 0.0
    ..u2P1Id = ''
    ..u2P1Name = ''
    ..u2P1Price = 0.0
    ..proposedBy = ''
    ..dealStatus = ''
    ..u1P1Image = ''
    ..u2P1Image = ''
    ..barterid = ''
    ..barterNo = 0;

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('barter');

  static Stream<BarterRecord?> getDocument(DocumentReference ref) => ref
      .snapshots()
      .map((s) => serializers.deserializeWith(serializer, serializedData(s)));

  BarterRecord._();
  factory BarterRecord([void Function(BarterRecordBuilder) updates]) =
      _$BarterRecord;

  static BarterRecord? getDocumentFromData(
          Map<String, dynamic> data, DocumentReference reference) =>
      serializers.deserializeWith(serializer,
          {...mapFromFirestore(data), kDocumentReferenceField: reference});
}

Map<String, dynamic> createBarterRecordData({
  required String? userid1,
  required String? userid2,
  bool? user1Accepted,
  bool? user2Accepted,
  String? u1P1Id,
  required String? u1P1Name,
  required double? u1P1Price,
  String? u2P1Id,
  String? u2P1Name,
  double? u2P1Price,
  String? proposedBy,
  DateTime? lastProposedDate,
  String? dealStatus,
  DateTime? dealDate,
  required String? u1P1Image,
  String? u2P1Image,
  required String? barterid,
  required int? barterNo,
}) =>
    serializers.toFirestore(
        BarterRecord.serializer,
        BarterRecord((b) => b
          ..userid1 = userid1
          ..userid2 = userid2
          ..user1Accepted = user1Accepted
          ..user2Accepted = user2Accepted
          ..u1P1Id = u1P1Id
          ..u1P1Name = u1P1Name
          ..u1P1Price = u1P1Price
          ..u2P1Id = u2P1Id
          ..u2P1Name = u2P1Name
          ..u2P1Price = u2P1Price
          ..proposedBy = proposedBy
          ..lastProposedDate = lastProposedDate
          ..dealStatus = dealStatus
          ..dealDate = dealDate
          ..u1P1Image = u1P1Image
          ..u2P1Image = u2P1Image
          ..barterid = barterid
          ..barterNo = barterNo));

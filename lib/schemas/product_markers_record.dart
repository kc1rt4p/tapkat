import 'dart:async';

import 'package:built_value/built_value.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tapkat/services/algolia_manager.dart';

import 'serializers.dart';

part 'product_markers_record.g.dart';

abstract class ProductMarkersRecord
    implements Built<ProductMarkersRecord, ProductMarkersRecordBuilder> {
  static Serializer<ProductMarkersRecord> get serializer =>
      _$productMarkersRecordSerializer;

  String? get productid;

  String? get productname;

  double? get price;

  LatLng get location;

  @BuiltValueField(wireName: kDocumentReferenceField)
  DocumentReference? get reference;

  static void _initializeBuilder(ProductMarkersRecordBuilder builder) => builder
    ..productid = ''
    ..productname = ''
    ..price = 0.0;

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('product_markers');

  static Stream<ProductMarkersRecord?> getDocument(DocumentReference ref) => ref
      .snapshots()
      .map((s) => serializers.deserializeWith(serializer, serializedData(s)));

  static ProductMarkersRecord? fromAlgolia(AlgoliaObjectSnapshot snapshot) =>
      ProductMarkersRecord(
        (c) => c
          ..productid = snapshot.data['productid']
          ..productname = snapshot.data['productname']
          ..price = snapshot.data['price']
          ..location = safeGet(() => LatLng(
                snapshot.data['_geoloc']['lat'],
                snapshot.data['_geoloc']['lng'],
              ))
          ..reference = ProductMarkersRecord.collection.doc(snapshot.objectID),
      );

  static Future<List<ProductMarkersRecord?>> search({
    String? term,
    FutureOr<LatLng?> location,
    int? maxResults,
    double? searchRadiusMeters,
  }) =>
      FFAlgoliaManager.instance
          .algoliaQuery(
            index: 'product_markers',
            term: term,
            maxResults: maxResults,
            location: location,
            searchRadiusMeters: searchRadiusMeters,
          )
          .then((r) => r != null ? r.map(fromAlgolia).toList() : []);

  ProductMarkersRecord._();
  factory ProductMarkersRecord(
          [void Function(ProductMarkersRecordBuilder) updates]) =
      _$ProductMarkersRecord;

  static ProductMarkersRecord? getDocumentFromData(
          Map<String, dynamic> data, DocumentReference reference) =>
      serializers.deserializeWith(serializer,
          {...mapFromFirestore(data), kDocumentReferenceField: reference});
}

Map<String, dynamic> createProductMarkersRecordData({
  String? productid,
  String? productname,
  double? price,
  LatLng? location,
}) =>
    serializers.toFirestore(
        ProductMarkersRecord.serializer,
        ProductMarkersRecord((p) => p
          ..productid = productid
          ..productname = productname
          ..price = price
          ..location = location));

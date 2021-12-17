// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_markers_record.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<ProductMarkersRecord> _$productMarkersRecordSerializer =
    new _$ProductMarkersRecordSerializer();

class _$ProductMarkersRecordSerializer
    implements StructuredSerializer<ProductMarkersRecord> {
  @override
  final Iterable<Type> types = const [
    ProductMarkersRecord,
    _$ProductMarkersRecord
  ];
  @override
  final String wireName = 'ProductMarkersRecord';

  @override
  Iterable<Object?> serialize(
      Serializers serializers, ProductMarkersRecord object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'location',
      serializers.serialize(object.location,
          specifiedType: const FullType(LatLng)),
    ];
    Object? value;
    value = object.productid;
    if (value != null) {
      result
        ..add('productid')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.productname;
    if (value != null) {
      result
        ..add('productname')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.price;
    if (value != null) {
      result
        ..add('price')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(double)));
    }
    value = object.reference;
    if (value != null) {
      result
        ..add('Document__Reference__Field')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(
                DocumentReference, const [const FullType.nullable(Object)])));
    }
    return result;
  }

  @override
  ProductMarkersRecord deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new ProductMarkersRecordBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'productid':
          result.productid = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'productname':
          result.productname = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'price':
          result.price = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double?;
          break;
        case 'location':
          result.location = serializers.deserialize(value,
              specifiedType: const FullType(LatLng)) as LatLng;
          break;
        case 'Document__Reference__Field':
          result.reference = serializers.deserialize(value,
              specifiedType: const FullType(DocumentReference, const [
                const FullType.nullable(Object)
              ])) as DocumentReference<Object?>?;
          break;
      }
    }

    return result.build();
  }
}

class _$ProductMarkersRecord extends ProductMarkersRecord {
  @override
  final String? productid;
  @override
  final String? productname;
  @override
  final double? price;
  @override
  final LatLng location;
  @override
  final DocumentReference<Object?>? reference;

  factory _$ProductMarkersRecord(
          [void Function(ProductMarkersRecordBuilder)? updates]) =>
      (new ProductMarkersRecordBuilder()..update(updates)).build();

  _$ProductMarkersRecord._(
      {this.productid,
      this.productname,
      this.price,
      required this.location,
      this.reference})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        location, 'ProductMarkersRecord', 'location');
  }

  @override
  ProductMarkersRecord rebuild(
          void Function(ProductMarkersRecordBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductMarkersRecordBuilder toBuilder() =>
      new ProductMarkersRecordBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductMarkersRecord &&
        productid == other.productid &&
        productname == other.productname &&
        price == other.price &&
        location == other.location &&
        reference == other.reference;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc($jc($jc(0, productid.hashCode), productname.hashCode),
                price.hashCode),
            location.hashCode),
        reference.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('ProductMarkersRecord')
          ..add('productid', productid)
          ..add('productname', productname)
          ..add('price', price)
          ..add('location', location)
          ..add('reference', reference))
        .toString();
  }
}

class ProductMarkersRecordBuilder
    implements Builder<ProductMarkersRecord, ProductMarkersRecordBuilder> {
  _$ProductMarkersRecord? _$v;

  String? _productid;
  String? get productid => _$this._productid;
  set productid(String? productid) => _$this._productid = productid;

  String? _productname;
  String? get productname => _$this._productname;
  set productname(String? productname) => _$this._productname = productname;

  double? _price;
  double? get price => _$this._price;
  set price(double? price) => _$this._price = price;

  LatLng? _location;
  LatLng? get location => _$this._location;
  set location(LatLng? location) => _$this._location = location;

  DocumentReference<Object?>? _reference;
  DocumentReference<Object?>? get reference => _$this._reference;
  set reference(DocumentReference<Object?>? reference) =>
      _$this._reference = reference;

  ProductMarkersRecordBuilder() {
    ProductMarkersRecord._initializeBuilder(this);
  }

  ProductMarkersRecordBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _productid = $v.productid;
      _productname = $v.productname;
      _price = $v.price;
      _location = $v.location;
      _reference = $v.reference;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductMarkersRecord other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ProductMarkersRecord;
  }

  @override
  void update(void Function(ProductMarkersRecordBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$ProductMarkersRecord build() {
    final _$result = _$v ??
        new _$ProductMarkersRecord._(
            productid: productid,
            productname: productname,
            price: price,
            location: BuiltValueNullFieldError.checkNotNull(
                location, 'ProductMarkersRecord', 'location'),
            reference: reference);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new

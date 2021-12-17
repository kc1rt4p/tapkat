// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barter_items_record.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<BarterItemsRecord> _$barterItemsRecordSerializer =
    new _$BarterItemsRecordSerializer();

class _$BarterItemsRecordSerializer
    implements StructuredSerializer<BarterItemsRecord> {
  @override
  final Iterable<Type> types = const [BarterItemsRecord, _$BarterItemsRecord];
  @override
  final String wireName = 'BarterItemsRecord';

  @override
  Iterable<Object?> serialize(Serializers serializers, BarterItemsRecord object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[
      'Document__Reference__Field',
      serializers.serialize(object.reference,
          specifiedType: const FullType(
              DocumentReference, const [const FullType.nullable(Object)])),
    ];
    Object? value;
    value = object.barterid;
    if (value != null) {
      result
        ..add('barterid')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.userid;
    if (value != null) {
      result
        ..add('userid')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
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
    value = object.imageUrl;
    if (value != null) {
      result
        ..add('image_url')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  BarterItemsRecord deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BarterItemsRecordBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'barterid':
          result.barterid = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'userid':
          result.userid = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
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
        case 'image_url':
          result.imageUrl = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'Document__Reference__Field':
          result.reference = serializers.deserialize(value,
              specifiedType: const FullType(DocumentReference, const [
                const FullType.nullable(Object)
              ])) as DocumentReference<Object?>;
          break;
      }
    }

    return result.build();
  }
}

class _$BarterItemsRecord extends BarterItemsRecord {
  @override
  final String? barterid;
  @override
  final String? userid;
  @override
  final String? productid;
  @override
  final String? productname;
  @override
  final double? price;
  @override
  final String? imageUrl;
  @override
  final DocumentReference<Object?> reference;

  factory _$BarterItemsRecord(
          [void Function(BarterItemsRecordBuilder)? updates]) =>
      (new BarterItemsRecordBuilder()..update(updates)).build();

  _$BarterItemsRecord._(
      {this.barterid,
      this.userid,
      this.productid,
      this.productname,
      this.price,
      this.imageUrl,
      required this.reference})
      : super._() {
    BuiltValueNullFieldError.checkNotNull(
        reference, 'BarterItemsRecord', 'reference');
  }

  @override
  BarterItemsRecord rebuild(void Function(BarterItemsRecordBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BarterItemsRecordBuilder toBuilder() =>
      new BarterItemsRecordBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BarterItemsRecord &&
        barterid == other.barterid &&
        userid == other.userid &&
        productid == other.productid &&
        productname == other.productname &&
        price == other.price &&
        imageUrl == other.imageUrl &&
        reference == other.reference;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc($jc($jc(0, barterid.hashCode), userid.hashCode),
                        productid.hashCode),
                    productname.hashCode),
                price.hashCode),
            imageUrl.hashCode),
        reference.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BarterItemsRecord')
          ..add('barterid', barterid)
          ..add('userid', userid)
          ..add('productid', productid)
          ..add('productname', productname)
          ..add('price', price)
          ..add('imageUrl', imageUrl)
          ..add('reference', reference))
        .toString();
  }
}

class BarterItemsRecordBuilder
    implements Builder<BarterItemsRecord, BarterItemsRecordBuilder> {
  _$BarterItemsRecord? _$v;

  String? _barterid;
  String? get barterid => _$this._barterid;
  set barterid(String? barterid) => _$this._barterid = barterid;

  String? _userid;
  String? get userid => _$this._userid;
  set userid(String? userid) => _$this._userid = userid;

  String? _productid;
  String? get productid => _$this._productid;
  set productid(String? productid) => _$this._productid = productid;

  String? _productname;
  String? get productname => _$this._productname;
  set productname(String? productname) => _$this._productname = productname;

  double? _price;
  double? get price => _$this._price;
  set price(double? price) => _$this._price = price;

  String? _imageUrl;
  String? get imageUrl => _$this._imageUrl;
  set imageUrl(String? imageUrl) => _$this._imageUrl = imageUrl;

  DocumentReference<Object?>? _reference;
  DocumentReference<Object?>? get reference => _$this._reference;
  set reference(DocumentReference<Object?>? reference) =>
      _$this._reference = reference;

  BarterItemsRecordBuilder() {
    BarterItemsRecord._initializeBuilder(this);
  }

  BarterItemsRecordBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _barterid = $v.barterid;
      _userid = $v.userid;
      _productid = $v.productid;
      _productname = $v.productname;
      _price = $v.price;
      _imageUrl = $v.imageUrl;
      _reference = $v.reference;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BarterItemsRecord other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$BarterItemsRecord;
  }

  @override
  void update(void Function(BarterItemsRecordBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$BarterItemsRecord build() {
    final _$result = _$v ??
        new _$BarterItemsRecord._(
            barterid: barterid,
            userid: userid,
            productid: productid,
            productname: productname,
            price: price,
            imageUrl: imageUrl,
            reference: BuiltValueNullFieldError.checkNotNull(
                reference, 'BarterItemsRecord', 'reference'));
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new

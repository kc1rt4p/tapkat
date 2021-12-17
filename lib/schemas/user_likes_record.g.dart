// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_likes_record.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<UserLikesRecord> _$userLikesRecordSerializer =
    new _$UserLikesRecordSerializer();

class _$UserLikesRecordSerializer
    implements StructuredSerializer<UserLikesRecord> {
  @override
  final Iterable<Type> types = const [UserLikesRecord, _$UserLikesRecord];
  @override
  final String wireName = 'UserLikesRecord';

  @override
  Iterable<Object?> serialize(Serializers serializers, UserLikesRecord object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[];
    Object? value;
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
    value = object.liked;
    if (value != null) {
      result
        ..add('liked')
        ..add(
            serializers.serialize(value, specifiedType: const FullType(bool)));
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
  UserLikesRecord deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new UserLikesRecordBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
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
        case 'liked':
          result.liked = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool?;
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

class _$UserLikesRecord extends UserLikesRecord {
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
  final bool? liked;
  @override
  final DocumentReference<Object?>? reference;

  factory _$UserLikesRecord([void Function(UserLikesRecordBuilder)? updates]) =>
      (new UserLikesRecordBuilder()..update(updates)).build();

  _$UserLikesRecord._(
      {this.userid,
      this.productid,
      this.productname,
      this.price,
      this.imageUrl,
      this.liked,
      this.reference})
      : super._();

  @override
  UserLikesRecord rebuild(void Function(UserLikesRecordBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UserLikesRecordBuilder toBuilder() =>
      new UserLikesRecordBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserLikesRecord &&
        userid == other.userid &&
        productid == other.productid &&
        productname == other.productname &&
        price == other.price &&
        imageUrl == other.imageUrl &&
        liked == other.liked &&
        reference == other.reference;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc($jc($jc(0, userid.hashCode), productid.hashCode),
                        productname.hashCode),
                    price.hashCode),
                imageUrl.hashCode),
            liked.hashCode),
        reference.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('UserLikesRecord')
          ..add('userid', userid)
          ..add('productid', productid)
          ..add('productname', productname)
          ..add('price', price)
          ..add('imageUrl', imageUrl)
          ..add('liked', liked)
          ..add('reference', reference))
        .toString();
  }
}

class UserLikesRecordBuilder
    implements Builder<UserLikesRecord, UserLikesRecordBuilder> {
  _$UserLikesRecord? _$v;

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

  bool? _liked;
  bool? get liked => _$this._liked;
  set liked(bool? liked) => _$this._liked = liked;

  DocumentReference<Object?>? _reference;
  DocumentReference<Object?>? get reference => _$this._reference;
  set reference(DocumentReference<Object?>? reference) =>
      _$this._reference = reference;

  UserLikesRecordBuilder() {
    UserLikesRecord._initializeBuilder(this);
  }

  UserLikesRecordBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userid = $v.userid;
      _productid = $v.productid;
      _productname = $v.productname;
      _price = $v.price;
      _imageUrl = $v.imageUrl;
      _liked = $v.liked;
      _reference = $v.reference;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UserLikesRecord other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$UserLikesRecord;
  }

  @override
  void update(void Function(UserLikesRecordBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$UserLikesRecord build() {
    final _$result = _$v ??
        new _$UserLikesRecord._(
            userid: userid,
            productid: productid,
            productname: productname,
            price: price,
            imageUrl: imageUrl,
            liked: liked,
            reference: reference);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new

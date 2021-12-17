// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barter_record.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<BarterRecord> _$barterRecordSerializer =
    new _$BarterRecordSerializer();

class _$BarterRecordSerializer implements StructuredSerializer<BarterRecord> {
  @override
  final Iterable<Type> types = const [BarterRecord, _$BarterRecord];
  @override
  final String wireName = 'BarterRecord';

  @override
  Iterable<Object?> serialize(Serializers serializers, BarterRecord object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object?>[];
    Object? value;
    value = object.userid1;
    if (value != null) {
      result
        ..add('userid1')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.userid2;
    if (value != null) {
      result
        ..add('userid2')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.user1Accepted;
    if (value != null) {
      result
        ..add('user1_accepted')
        ..add(
            serializers.serialize(value, specifiedType: const FullType(bool)));
    }
    value = object.user2Accepted;
    if (value != null) {
      result
        ..add('user2_accepted')
        ..add(
            serializers.serialize(value, specifiedType: const FullType(bool)));
    }
    value = object.u1P1Id;
    if (value != null) {
      result
        ..add('u1_p1_id')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.u1P1Name;
    if (value != null) {
      result
        ..add('u1_p1_name')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.u1P1Price;
    if (value != null) {
      result
        ..add('u1_p1_price')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(double)));
    }
    value = object.u2P1Id;
    if (value != null) {
      result
        ..add('u2_p1_id')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.u2P1Name;
    if (value != null) {
      result
        ..add('u2_p1_name')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.u2P1Price;
    if (value != null) {
      result
        ..add('u2_p1_price')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(double)));
    }
    value = object.proposedBy;
    if (value != null) {
      result
        ..add('proposed_by')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.lastProposedDate;
    if (value != null) {
      result
        ..add('last_proposed_date')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(DateTime)));
    }
    value = object.dealStatus;
    if (value != null) {
      result
        ..add('deal_status')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.dealDate;
    if (value != null) {
      result
        ..add('deal_date')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(DateTime)));
    }
    value = object.u1P1Image;
    if (value != null) {
      result
        ..add('u1_p1_image')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.u2P1Image;
    if (value != null) {
      result
        ..add('u2_p1_image')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.barterid;
    if (value != null) {
      result
        ..add('barterid')
        ..add(serializers.serialize(value,
            specifiedType: const FullType(String)));
    }
    value = object.barterNo;
    if (value != null) {
      result
        ..add('barter_no')
        ..add(serializers.serialize(value, specifiedType: const FullType(int)));
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
  BarterRecord deserialize(
      Serializers serializers, Iterable<Object?> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new BarterRecordBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'userid1':
          result.userid1 = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'userid2':
          result.userid2 = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'user1_accepted':
          result.user1Accepted = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool?;
          break;
        case 'user2_accepted':
          result.user2Accepted = serializers.deserialize(value,
              specifiedType: const FullType(bool)) as bool?;
          break;
        case 'u1_p1_id':
          result.u1P1Id = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'u1_p1_name':
          result.u1P1Name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'u1_p1_price':
          result.u1P1Price = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double?;
          break;
        case 'u2_p1_id':
          result.u2P1Id = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'u2_p1_name':
          result.u2P1Name = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'u2_p1_price':
          result.u2P1Price = serializers.deserialize(value,
              specifiedType: const FullType(double)) as double?;
          break;
        case 'proposed_by':
          result.proposedBy = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'last_proposed_date':
          result.lastProposedDate = serializers.deserialize(value,
              specifiedType: const FullType(DateTime)) as DateTime?;
          break;
        case 'deal_status':
          result.dealStatus = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'deal_date':
          result.dealDate = serializers.deserialize(value,
              specifiedType: const FullType(DateTime)) as DateTime?;
          break;
        case 'u1_p1_image':
          result.u1P1Image = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'u2_p1_image':
          result.u2P1Image = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'barterid':
          result.barterid = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String?;
          break;
        case 'barter_no':
          result.barterNo = serializers.deserialize(value,
              specifiedType: const FullType(int)) as int?;
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

class _$BarterRecord extends BarterRecord {
  @override
  final String? userid1;
  @override
  final String? userid2;
  @override
  final bool? user1Accepted;
  @override
  final bool? user2Accepted;
  @override
  final String? u1P1Id;
  @override
  final String? u1P1Name;
  @override
  final double? u1P1Price;
  @override
  final String? u2P1Id;
  @override
  final String? u2P1Name;
  @override
  final double? u2P1Price;
  @override
  final String? proposedBy;
  @override
  final DateTime? lastProposedDate;
  @override
  final String? dealStatus;
  @override
  final DateTime? dealDate;
  @override
  final String? u1P1Image;
  @override
  final String? u2P1Image;
  @override
  final String? barterid;
  @override
  final int? barterNo;
  @override
  final DocumentReference<Object?>? reference;

  factory _$BarterRecord([void Function(BarterRecordBuilder)? updates]) =>
      (new BarterRecordBuilder()..update(updates)).build();

  _$BarterRecord._(
      {this.userid1,
      this.userid2,
      this.user1Accepted,
      this.user2Accepted,
      this.u1P1Id,
      this.u1P1Name,
      this.u1P1Price,
      this.u2P1Id,
      this.u2P1Name,
      this.u2P1Price,
      this.proposedBy,
      this.lastProposedDate,
      this.dealStatus,
      this.dealDate,
      this.u1P1Image,
      this.u2P1Image,
      this.barterid,
      this.barterNo,
      this.reference})
      : super._();

  @override
  BarterRecord rebuild(void Function(BarterRecordBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BarterRecordBuilder toBuilder() => new BarterRecordBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BarterRecord &&
        userid1 == other.userid1 &&
        userid2 == other.userid2 &&
        user1Accepted == other.user1Accepted &&
        user2Accepted == other.user2Accepted &&
        u1P1Id == other.u1P1Id &&
        u1P1Name == other.u1P1Name &&
        u1P1Price == other.u1P1Price &&
        u2P1Id == other.u2P1Id &&
        u2P1Name == other.u2P1Name &&
        u2P1Price == other.u2P1Price &&
        proposedBy == other.proposedBy &&
        lastProposedDate == other.lastProposedDate &&
        dealStatus == other.dealStatus &&
        dealDate == other.dealDate &&
        u1P1Image == other.u1P1Image &&
        u2P1Image == other.u2P1Image &&
        barterid == other.barterid &&
        barterNo == other.barterNo &&
        reference == other.reference;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc(
                                        $jc(
                                            $jc(
                                                $jc(
                                                    $jc(
                                                        $jc(
                                                            $jc(
                                                                $jc(
                                                                    $jc(
                                                                        $jc(
                                                                            $jc(
                                                                                0,
                                                                                userid1
                                                                                    .hashCode),
                                                                            userid2
                                                                                .hashCode),
                                                                        user1Accepted
                                                                            .hashCode),
                                                                    user2Accepted
                                                                        .hashCode),
                                                                u1P1Id
                                                                    .hashCode),
                                                            u1P1Name.hashCode),
                                                        u1P1Price.hashCode),
                                                    u2P1Id.hashCode),
                                                u2P1Name.hashCode),
                                            u2P1Price.hashCode),
                                        proposedBy.hashCode),
                                    lastProposedDate.hashCode),
                                dealStatus.hashCode),
                            dealDate.hashCode),
                        u1P1Image.hashCode),
                    u2P1Image.hashCode),
                barterid.hashCode),
            barterNo.hashCode),
        reference.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('BarterRecord')
          ..add('userid1', userid1)
          ..add('userid2', userid2)
          ..add('user1Accepted', user1Accepted)
          ..add('user2Accepted', user2Accepted)
          ..add('u1P1Id', u1P1Id)
          ..add('u1P1Name', u1P1Name)
          ..add('u1P1Price', u1P1Price)
          ..add('u2P1Id', u2P1Id)
          ..add('u2P1Name', u2P1Name)
          ..add('u2P1Price', u2P1Price)
          ..add('proposedBy', proposedBy)
          ..add('lastProposedDate', lastProposedDate)
          ..add('dealStatus', dealStatus)
          ..add('dealDate', dealDate)
          ..add('u1P1Image', u1P1Image)
          ..add('u2P1Image', u2P1Image)
          ..add('barterid', barterid)
          ..add('barterNo', barterNo)
          ..add('reference', reference))
        .toString();
  }
}

class BarterRecordBuilder
    implements Builder<BarterRecord, BarterRecordBuilder> {
  _$BarterRecord? _$v;

  String? _userid1;
  String? get userid1 => _$this._userid1;
  set userid1(String? userid1) => _$this._userid1 = userid1;

  String? _userid2;
  String? get userid2 => _$this._userid2;
  set userid2(String? userid2) => _$this._userid2 = userid2;

  bool? _user1Accepted;
  bool? get user1Accepted => _$this._user1Accepted;
  set user1Accepted(bool? user1Accepted) =>
      _$this._user1Accepted = user1Accepted;

  bool? _user2Accepted;
  bool? get user2Accepted => _$this._user2Accepted;
  set user2Accepted(bool? user2Accepted) =>
      _$this._user2Accepted = user2Accepted;

  String? _u1P1Id;
  String? get u1P1Id => _$this._u1P1Id;
  set u1P1Id(String? u1P1Id) => _$this._u1P1Id = u1P1Id;

  String? _u1P1Name;
  String? get u1P1Name => _$this._u1P1Name;
  set u1P1Name(String? u1P1Name) => _$this._u1P1Name = u1P1Name;

  double? _u1P1Price;
  double? get u1P1Price => _$this._u1P1Price;
  set u1P1Price(double? u1P1Price) => _$this._u1P1Price = u1P1Price;

  String? _u2P1Id;
  String? get u2P1Id => _$this._u2P1Id;
  set u2P1Id(String? u2P1Id) => _$this._u2P1Id = u2P1Id;

  String? _u2P1Name;
  String? get u2P1Name => _$this._u2P1Name;
  set u2P1Name(String? u2P1Name) => _$this._u2P1Name = u2P1Name;

  double? _u2P1Price;
  double? get u2P1Price => _$this._u2P1Price;
  set u2P1Price(double? u2P1Price) => _$this._u2P1Price = u2P1Price;

  String? _proposedBy;
  String? get proposedBy => _$this._proposedBy;
  set proposedBy(String? proposedBy) => _$this._proposedBy = proposedBy;

  DateTime? _lastProposedDate;
  DateTime? get lastProposedDate => _$this._lastProposedDate;
  set lastProposedDate(DateTime? lastProposedDate) =>
      _$this._lastProposedDate = lastProposedDate;

  String? _dealStatus;
  String? get dealStatus => _$this._dealStatus;
  set dealStatus(String? dealStatus) => _$this._dealStatus = dealStatus;

  DateTime? _dealDate;
  DateTime? get dealDate => _$this._dealDate;
  set dealDate(DateTime? dealDate) => _$this._dealDate = dealDate;

  String? _u1P1Image;
  String? get u1P1Image => _$this._u1P1Image;
  set u1P1Image(String? u1P1Image) => _$this._u1P1Image = u1P1Image;

  String? _u2P1Image;
  String? get u2P1Image => _$this._u2P1Image;
  set u2P1Image(String? u2P1Image) => _$this._u2P1Image = u2P1Image;

  String? _barterid;
  String? get barterid => _$this._barterid;
  set barterid(String? barterid) => _$this._barterid = barterid;

  int? _barterNo;
  int? get barterNo => _$this._barterNo;
  set barterNo(int? barterNo) => _$this._barterNo = barterNo;

  DocumentReference<Object?>? _reference;
  DocumentReference<Object?>? get reference => _$this._reference;
  set reference(DocumentReference<Object?>? reference) =>
      _$this._reference = reference;

  BarterRecordBuilder() {
    BarterRecord._initializeBuilder(this);
  }

  BarterRecordBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _userid1 = $v.userid1;
      _userid2 = $v.userid2;
      _user1Accepted = $v.user1Accepted;
      _user2Accepted = $v.user2Accepted;
      _u1P1Id = $v.u1P1Id;
      _u1P1Name = $v.u1P1Name;
      _u1P1Price = $v.u1P1Price;
      _u2P1Id = $v.u2P1Id;
      _u2P1Name = $v.u2P1Name;
      _u2P1Price = $v.u2P1Price;
      _proposedBy = $v.proposedBy;
      _lastProposedDate = $v.lastProposedDate;
      _dealStatus = $v.dealStatus;
      _dealDate = $v.dealDate;
      _u1P1Image = $v.u1P1Image;
      _u2P1Image = $v.u2P1Image;
      _barterid = $v.barterid;
      _barterNo = $v.barterNo;
      _reference = $v.reference;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BarterRecord other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$BarterRecord;
  }

  @override
  void update(void Function(BarterRecordBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  _$BarterRecord build() {
    final _$result = _$v ??
        new _$BarterRecord._(
            userid1: userid1,
            userid2: userid2,
            user1Accepted: user1Accepted,
            user2Accepted: user2Accepted,
            u1P1Id: u1P1Id,
            u1P1Name: u1P1Name,
            u1P1Price: u1P1Price,
            u2P1Id: u2P1Id,
            u2P1Name: u2P1Name,
            u2P1Price: u2P1Price,
            proposedBy: proposedBy,
            lastProposedDate: lastProposedDate,
            dealStatus: dealStatus,
            dealDate: dealDate,
            u1P1Image: u1P1Image,
            u2P1Image: u2P1Image,
            barterid: barterid,
            barterNo: barterNo,
            reference: reference);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,deprecated_member_use_from_same_package,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new

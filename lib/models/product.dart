import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapkat/models/address.dart';
import 'package:tapkat/models/media_primary_model.dart';

class ProductModel {
  String? productid;
  String? userid;
  String? productname;
  String? productdesc;
  String? currency;
  String? specifications;
  String? type;
  String? category;
  String? display_name;
  MediaPrimaryModel? mediaPrimary;
  List<MediaPrimaryModel>? media;

  List<AddressModel>? meet_location;
  num? price;
  int? likes;
  AddressModel? address;
  num? rating;
  String? imgUrl;
  String? status;
  DateTime? updated_time;
  String? acquired_by;
  double? distance;
  List<String>? tradeFor;
  bool? free;
  int stock_count;
  bool track_stock;
  int deal_count;

  ProductModel({
    this.productid,
    this.userid,
    this.productname,
    this.productdesc,
    this.currency,
    this.specifications,
    this.type,
    this.category,
    this.mediaPrimary,
    this.price,
    this.likes,
    this.address,
    this.rating,
    this.media,
    this.imgUrl,
    this.status,
    this.updated_time,
    this.display_name,
    this.acquired_by,
    this.distance,
    this.tradeFor,
    this.free,
    this.meet_location,
    this.stock_count = 0,
    this.track_stock = false,
    this.deal_count = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productid: json['productid'],
      userid: json['userid'],
      productname: json['productname'],
      productdesc: json['productdesc'],
      currency: json['currency'],
      specifications: json['specifications'],
      type: json['type'],
      category: json['category'] is List<dynamic>
          ? (json['category'] as List<dynamic>).first as String?
          : json['category'] as String?,
      mediaPrimary: json['media_primary'] != null
          ? MediaPrimaryModel.fromJson(json['media_primary'])
          : null,
      price: json['price'],
      likes: json['likes'] is String ? int.parse(json['likes']) : json['likes'],
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'])
          : null,
      rating: json['rating'],
      media: json['media'] != null
          ? (json['media'] as List<dynamic>)
              .map((m) => MediaPrimaryModel.fromJson(m))
              .toList()
          : [],
      imgUrl: json['image_url'] as String?,
      status: json['status'] as String?,
      updated_time: json['updated_time'] != null
          ? json['updated_time'] is String
              ? DateTime.parse(json['updated_time'])
              : Timestamp(json['updated_time']['_seconds'],
                      json['updated_time']['_nanoseconds'])
                  .toDate()
          : null,
      display_name: json['image_url'] as String?,
      acquired_by: json['acquired_by'] as String?,
      distance:
          json['distance'] != null ? json['distance'] + 0.0 as double? : null,
      tradeFor: json['tradefor'] != null
          ? (json['tradefor'] as List<dynamic>)
              .map((item) => item.toString())
              .toList()
          : [],
      free: json['free'] != null ? json['free'] as bool? : false,
      meet_location: json['meet_location'] != null
          ? (json['meet_location'] as List<dynamic>)
              .map((item) => AddressModel.fromJson(item))
              .toList()
          : [],
      track_stock: json['track_stock'] as bool? ?? false,
      stock_count: json['stock_count'] as int? ?? 0,
      deal_count: json['deal_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson([bool withId = false]) {
    final json = {
      'userid': this.userid,
      'productname': this.productname,
      'productdesc': this.productdesc,
      'currency': this.currency,
      'specifications': this.specifications,
      'type': this.type,
      'category': this.category,
      'media_primary':
          this.mediaPrimary != null ? this.mediaPrimary!.toJson() : null,
      'price': this.price,
      'likes': this.likes,
      'display_name': this.display_name,
      'updated_time': this.updated_time,
      'acquired_by': this.acquired_by,
      'status': this.status,
      'tradefor': this.tradeFor,
      'free': this.free,
      'meet_location': this.meet_location,
      'stock_count': this.stock_count,
      'track_stock': this.track_stock,
      'deal_count': this.deal_count,
    };
    return json..addAll({'productid': this.productid});
  }
}

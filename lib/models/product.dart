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
  MediaPrimaryModel? mediaPrimary;
  List<MediaPrimaryModel>? media;
  num? price;
  int? likes;
  AddressModel? address;
  num? rating;
  String? imgUrl;

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
      category: json['category'],
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': this.userid,
      'productname': this.productname,
      'productdesc': this.productdesc,
      'currency': this.currency,
      'specifications': this.specifications,
      'type': this.type,
      'category': this.category,
      'media_primary': this.mediaPrimary,
      'price': this.price,
      'likes': this.likes,
    };
  }
}

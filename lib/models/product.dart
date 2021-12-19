import 'package:tapkat/models/address.dart';

class ProductModel {
  String? productid;
  String? userid;
  String? productname;
  String? productdesc;
  String? currency;
  String? specifications;
  String? type;
  String? category;
  String? imgUrl;
  num? price;
  int? likes;
  AddressModel? address;
  num? rating;

  ProductModel({
    this.productid,
    this.userid,
    this.productname,
    this.productdesc,
    this.currency,
    this.specifications,
    this.type,
    this.category,
    this.imgUrl,
    this.price,
    this.likes,
    this.address,
    this.rating,
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
      imgUrl: json['imgUrl'],
      price: json['price'],
      likes: json['likes'],
      address: AddressModel.fromJson(json['address']),
      rating: json['rating'],
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
      'imgUrl': this.imgUrl,
      'price': this.price,
      'likes': this.likes,
    };
  }
}

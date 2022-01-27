import 'package:tapkat/models/product.dart';

class BarterProductModel {
  String? id;
  String? productId;
  String? userId;
  String? productName;
  num? price;
  String? imgUrl;
  String? currency;

  BarterProductModel({
    this.id,
    this.productId,
    this.userId,
    this.productName,
    this.price,
    this.imgUrl,
    this.currency,
  });

  factory BarterProductModel.fromProductModel(ProductModel product) {
    return BarterProductModel(
      productId: product.productid,
      userId: product.userid,
      productName: product.productname,
      price: product.price,
      imgUrl: product.mediaPrimary != null ? product.mediaPrimary!.url : '',
      currency: product.currency,
    );
  }

  factory BarterProductModel.fromJson(Map<String, dynamic> json) {
    return BarterProductModel(
      productId: json['productid'],
      userId: json['userid'],
      productName: json['productname'],
      price: json['price'],
      imgUrl: json['imgUrl'],
      currency: json['currency'],
    );
  }

  Map<String, dynamic> toJson([bool withId = false]) {
    var json = {
      'productid': this.productId,
      'userid': this.userId,
      'productname': this.productName,
      'price': this.price,
      'imgUrl': this.imgUrl,
      'currency': this.currency,
    };

    if (withId) {
      json.addAll({
        'id': this.id,
      });
    }

    return json;
  }
}

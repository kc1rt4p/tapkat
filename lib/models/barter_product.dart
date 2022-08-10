import 'package:tapkat/models/product.dart';

class BarterProductModel {
  String? id;
  String? productId;
  String? userId;
  String? productName;
  num? price;
  String? imgUrl;
  String? currency;
  String? barterid;
  DateTime? dateAdded;

  BarterProductModel({
    this.barterid,
    this.id,
    this.productId,
    this.userId,
    this.productName,
    this.price,
    this.imgUrl,
    this.currency,
    this.dateAdded,
  });

  factory BarterProductModel.fromProductModel(
      ProductModel product, String barterId) {
    var thumbnail = '';

    if (product.mediaPrimary != null &&
        product.mediaPrimary!.url != null &&
        product.mediaPrimary!.url!.isNotEmpty)
      thumbnail = product.mediaPrimary!.url!;

    if (product.mediaPrimary != null &&
        product.mediaPrimary!.url_t != null &&
        product.mediaPrimary!.url_t!.isNotEmpty)
      thumbnail = product.mediaPrimary!.url_t!;

    if (product.mediaPrimary == null ||
        product.mediaPrimary!.url!.isEmpty &&
            product.mediaPrimary!.url_t!.isEmpty &&
            product.media != null &&
            product.media!.isNotEmpty)
      thumbnail = product.media!.first.url_t != null
          ? product.media!.first.url_t!
          : product.media!.first.url!;
    return BarterProductModel(
      productId: product.productid,
      userId: product.userid,
      productName: product.productname,
      price: product.price,
      imgUrl: thumbnail,
      barterid: barterId,
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
      barterid: json['barterid'],
      currency: json['currency'],
      dateAdded: json['dateAdded'] != null ? json['dateAdded'].toDate() : null,
    );
  }

  Map<String, dynamic> toJson([bool withId = false]) {
    var json = {
      'productid': this.productId,
      'userid': this.userId,
      'barterid': this.barterid,
      'productname': this.productName,
      'price': this.price,
      'imgUrl': this.imgUrl,
      'currency': this.currency,
      'dateAdded': this.dateAdded,
    };

    if (withId) {
      json.addAll({
        'id': this.id,
      });
    }

    return json;
  }
}

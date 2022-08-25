import 'package:tapkat/models/address.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product.dart';

class ProductRequestModel {
  String? userid;
  String? productid;
  String? productname;
  String? productdesc;
  String? currency;
  String? specifications;
  String? type;
  String? address;
  String? city;
  String? country;
  String? category;
  String? postcode;
  String? image_url;
  List<AddressModel>? meet_location;
  String? media_type;
  String? display_name;
  String? status;
  String? acquired_by;
  LocationModel? location;
  num? price;
  num? rating;
  List<String>? tradefor;
  bool? free;
  int stock_count;
  bool track_stock;

  ProductRequestModel({
    this.productid,
    this.userid,
    this.productname,
    this.productdesc,
    this.currency,
    this.specifications,
    this.type,
    this.address,
    this.city,
    this.country,
    this.postcode,
    this.category,
    this.image_url,
    this.media_type,
    this.location,
    this.rating,
    this.price,
    this.display_name,
    this.status,
    this.acquired_by,
    this.tradefor,
    this.free,
    this.meet_location,
    this.stock_count = 0,
    this.track_stock = false,
  });

  factory ProductRequestModel.fromProduct(ProductModel product) {
    return ProductRequestModel(
      productid: product.productid ?? '',
      userid: product.userid ?? '',
      productname: product.productname ?? '',
      productdesc: product.productdesc ?? '',
      currency: product.currency ?? '',
      specifications: product.specifications ?? '',
      type: product.type ?? '',
      address: product.address!.address ?? '',
      city: product.address!.city ?? '',
      country: product.address!.country ?? '',
      postcode: product.address!.postCode ?? '',
      category: product.category ?? '',
      image_url: product.mediaPrimary!.url ?? product.mediaPrimary!.url_t ?? '',
      media_type: product.mediaPrimary!.type ?? '',
      location: product.address!.location ?? null,
      price: product.price ?? 0,
      rating: product.rating ?? 0,
      display_name: product.display_name,
      acquired_by: product.acquired_by ?? '',
      status: product.status ?? '',
      tradefor: product.tradeFor ?? [],
      free: product.free ?? null,
      meet_location: product.meet_location ?? null,
      stock_count: product.stock_count,
      track_stock: product.track_stock,
    );
  }

  Map<String, dynamic> toJson({bool updating = false, bool deal_done = false}) {
    Map<String, dynamic> map = {
      'userid': this.userid ?? '',
      'productname': this.productname ?? '',
      'productdesc': this.productdesc ?? '',
      'currency': this.currency ?? '',
      'specifications': this.specifications ?? '',
      'type': this.type ?? '',
      'address': this.address ?? '',
      'city': this.city ?? '',
      'country': this.country ?? '',
      'postcode': this.postcode ?? '',
      'category': this.category ?? '',
      'image_url': this.image_url ?? '',
      'media_type': this.media_type ?? '',
      'location': this.location != null ? this.location!.toJson() : {},
      'rating': this.rating ?? 0,
      'price': this.price ?? 0,
      'display_name': this.display_name ?? '',
      'acquired_by': this.acquired_by ?? '',
      'status': this.status ?? '',
      'tradefor': this.tradefor ?? [],
      'free': this.free,
      'meet_location': this.meet_location != null
          ? this.meet_location!.map((item) => item.toJson()).toList()
          : [],
      'stock_count': this.stock_count,
      'track_stock': this.track_stock,
    };

    if (updating) {
      map.addAll({
        'productid': this.productid,
      });
    }

    if (deal_done) {
      map.addAll({
        'deal_done': true,
      });
    }

    return map;
  }
}

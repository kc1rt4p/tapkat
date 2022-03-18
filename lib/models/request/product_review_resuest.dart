class ProductReviewModel {
  String? productid;
  String? productname;
  String? image_url_t;
  String? userid;
  String? display_name;
  num? rating;
  String? review;
  DateTime? review_date;

  ProductReviewModel({
    this.productid,
    this.productname,
    this.image_url_t,
    this.userid,
    this.display_name,
    this.rating,
    this.review,
    this.review_date,
  });

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    return ProductReviewModel(
      productid: json['productid'] as String?,
      productname: json['productname'] as String?,
      image_url_t: json['image_url_t'] as String?,
      userid: json['userid'] as String?,
      display_name: json['display_name'] as String?,
      rating: json['rating'] as num?,
      review: json['review'] as String?,
      review_date: DateTime.parse(json['review_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "productid": this.productid,
      "productname": this.productname,
      "image_url_t": this.image_url_t,
      "userid": this.userid,
      "display_name": this.display_name,
      "rating": this.rating,
      "review": this.review,
      "review_date": this.review_date,
    };
  }
}

class UserReviewModel {
  String? userid;
  String? username;
  String? user_image_url;
  String? reviewerid;
  String? reviewername;
  double? rating;
  String? review;
  String? review_date;

  UserReviewModel({
    this.userid,
    this.username,
    this.user_image_url,
    this.reviewerid,
    this.reviewername,
    this.rating,
    this.review,
    this.review_date,
  });

  factory UserReviewModel.fromJson(Map<String, dynamic> json) {
    return UserReviewModel(
        userid: json['userid'] as String?,
        username: json['username'] as String?,
        user_image_url: json['user_image_url'] as String?,
        reviewerid: json['reviewerid'] as String?,
        reviewername: json['reviewername'] as String?,
        rating: json['rating'] as double?,
        review: json['review'] as String?,
        review_date: json['review_date'] as String?);
  }

  Map<String, dynamic> toJson() {
    return {
      "userid": this.userid,
      "username": this.username,
      "user_image_url": this.user_image_url,
      "reviewerid": this.reviewerid,
      "reviewername": this.reviewername,
      "rating": this.rating,
      "review": this.review,
      'review_date': this.review_date,
    };
  }
}

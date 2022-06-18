import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart';
import 'package:mime_type/mime_type.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapkat/models/decode_param.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/models/product_type.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/models/request/product_review_resuest.dart';
import 'package:tapkat/models/store_like.dart';
import 'package:tapkat/models/upload_product_image_response.dart';
import 'package:tapkat/services/http/api_service.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/utilities/application.dart' as application;

void decodeIsolate(DecodeParam param) {
  var image = decodeImage(param.file.readAsBytesSync())!;
  print('0====> ORIGINAL IMAGE SIZE: ${image.length}');
  var thumbnail = copyResizeCropSquare(image, 200);
  print('0====> THUMBNAIL IMAGE SIZE: ${thumbnail.length}');
  param.sendPort.send(thumbnail);
}

class ProductRepository {
  final _apiService = ApiService();

  Future<List<LikedProductModel>> getUserFavourites(String userId) async {
    final response =
        await _apiService.post(url: 'users/likes/searchfirst', body: {
      "psk": psk,
      "userid": userId,
      "productcount": productCount,
      'location': application.currentUserLocation!.toJson(),
    });

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['like_list'] as List<dynamic>)
        .map((json) => LikedProductModel.fromJson(json))
        .toList();
  }

  Future<List<ProductModel>> getnextuserFavourites(
      String userId, String lastProductId, String lastProductDate) async {
    final response =
        await _apiService.post(url: 'users/likes/searchset', body: {
      "psk": psk,
      "userid": userId,
      "productcount": productCount,
      "startaferval": lastProductDate,
      "productid": lastProductId,
      'location': application.currentUserLocation!.toJson(),
    });

    return (response.data['like_list'] as List<dynamic>)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  Future<ProductModel> getProduct(String id) async {
    final response = await _apiService.get(url: 'products/single/$id');

    return ProductModel.fromJson(response.data);
  }

  Future<String?> addProduct(ProductRequestModel product) async {
    final response = await _apiService.post(
      url: 'products',
      body: {
        "psk": "lcp9321p",
        ...product.toJson(),
      },
    );

    if (response.data['status'] != 'SUCCESS') return null;

    return response.data['productid'] as String;
  }

  Future<bool> addProductReview(ProductReviewModel productReview) async {
    final response = await _apiService.post(
      url: 'products/review',
      body: {
        "psk": "lcp9321p",
        ...productReview.toJson(),
      },
    );

    return response.data['status'] == 'SUCCESS';
  }

  Future<ProductReviewModel?> getProductReview(
      String productId, String userId) async {
    final response = await _apiService.post(
      url: 'products/review/get',
      body: {
        'userid': userId,
        'productid': productId,
      },
    );

    if (response.data['status'] == 'SUCCESS')
      return ProductReviewModel.fromJson(response.data['products']);

    return null;
  }

  Future<bool> updateProductReview(ProductReviewModel productReview) async {
    final response =
        await _apiService.patch(url: 'products/review/update', body: {
      ...productReview.toJson(),
    });

    return response.data['status'] == 'SUCCESS';
  }

  Future<UploadProductImageResponseModel?> addProductImages({
    required String productId,
    required String userId,
    required List<SelectedMedia> images,
  }) async {
    var formData = FormData.fromMap({
      "psk": "lcp9321p",
      'userid': userId,
      'productid': productId,
    });

    List<SelectedMedia> _imgsToUpload = [];

    for (var img in images) {
      var receivePort = ReceivePort();
      await Isolate.spawn(
          decodeIsolate, DecodeParam(File(img.rawPath!), receivePort.sendPort));

      // Get the processed image from the isolate.
      var image = await receivePort.first as Image;

      final fileName = img.fileName.split('.')[0] + '_t.jpg';

      Directory appDocDirectory = await getApplicationDocumentsDirectory();

      final thumbnail = await File(appDocDirectory.path + '/' + fileName)
          .writeAsBytes(encodeJpg(image));

      _imgsToUpload.addAll([
        img,
        SelectedMedia(fileName, thumbnail.path, thumbnail.readAsBytesSync(),
            appDocDirectory.path + '/' + fileName),
      ]);
    }

    for (var img in _imgsToUpload) {
      final mimeType = mime(img.fileName);
      String mimee = mimeType!.split('/')[0];
      String type = mimeType.split('/')[1];

      if (img.rawPath == null) continue;

      formData.files.add(
        MapEntry(
          'media',
          MultipartFile.fromFileSync(
            img.rawPath!,
            contentType: MediaType(mimee, type),
          ),
        ),
      );
    }

    final response = await _apiService.post(
      url: 'products/upload',
      formData: formData,
    );

    if (response.data['status'] != 'SUCCESS') return null;

    return UploadProductImageResponseModel.fromJson(response.data);
  }

  Future<List<ProductReviewModel>> getProductRatings({
    String? productId,
    String? userId,
  }) async {
    final response = await _apiService.post(
      url: 'products/review/searchfirst',
      body: {
        productId != null ? 'productid' : 'userid': productId ?? userId,
        'sortby': 'date',
        'sortdirection': 'descending',
        'productcount': 10,
      },
    );

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['products'] as List<dynamic>)
        .map((d) => ProductReviewModel.fromJson(d))
        .toList();
  }

  Future<List<ProductReviewModel>> getNextRatings({
    String? productId,
    String? userId,
    required String secondaryVal,
    required String startAfterVal,
  }) async {
    final response = await _apiService.post(
      url: 'products/review/searchSet',
      body: {
        productId != null ? 'productid' : 'userid': productId ?? userId,
        'sortby': 'date',
        'sortdirection': 'descending',
        'productcount': 10,
        'startafterval': startAfterVal,
        'secondaryval': secondaryVal,
      },
    );

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['products'] as List<dynamic>)
        .map((d) => ProductReviewModel.fromJson(d))
        .toList();
  }

  Future<List<ProductModel>> getNextProducts({
    required String listType,
    required userId,
    required String lastProductId,
    required dynamic startAfterVal,
    required String sortBy,
    List<String>? category,
    List<String>? interests,
    LocationModel? location,
    int? itemCount,
    int radius = 5000,
  }) async {
    var body = {
      'userid': userId,
      'productcount': itemCount ?? productCount,
    };

    if (location != null) {
      body.addAll({
        'startafterval': startAfterVal,
        'location': location.toJson(),
        'radius': radius,
      });
    }

    if (category != null) {
      body.addAll({
        'category': category,
      });
    }

    body.addAll({
      'sortby': sortBy == 'name' ? 'productname' : sortBy.toLowerCase(),
      'startafterval': startAfterVal,
      'productid': lastProductId,
      'sortdirection': sortBy == 'rating' ? 'descending' : 'ascending',
    });

    if (listType == 'reco' && interests != null) {
      body.addAll({'interests': interests});
    }

    final response = await _apiService.post(
      url: 'products/$listType/searchset',
      body: body,
    );

    if (response.data['status'] == 'FAIL') return [];

    return (response.data['products'] as List<dynamic>).map((json) {
      return ProductModel.fromJson(json);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getAllCategoryProducts() async {
    final data = await getProductRefData();
    if (data == null) return [];
    final categories = data['categories'] as List<ProductCategoryModel>;
    print("=== === === ${categories.length}");
    List<Map<String, dynamic>> list = [];

    final products = await getCategoryProducts(
        categories
            .where((cat) => cat.type == 'PT1')
            .map((c) => c.code!)
            .toList(),
        application.currentUser!.uid);
    final cats = categories.where((cat) => cat.type == 'PT1').toList();

    for (var cat in cats) {
      list.add({
        'name': cat.name,
        'code': cat.code,
        'products':
            products.where((product) => product.category == cat.code).toList(),
      });
    }

    return list;
  }

  Future<List<ProductModel>> getCategoryProducts(List<String> categories,
      [String? userid]) async {
    var _body = {
      'sortby': 'distance',
      'type': 'PT1',
      'userid': userid,
      'sortdirection': 'ascending',
      'productcount': 100,
      'location': application.currentUserLocation != null
          ? application.currentUserLocation!.toJson()
          : application.currentUserModel!.location!.toJson(),
      'radius': 5000,
    };

    final response = await _apiService.post(
      url: 'products/searchfirst',
      body: _body,
    );

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['products'] as List<dynamic>)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  Future<List<ProductModel>> getFirstProducts(
    String listType, {
    required String userId,
    List<String>? interests,
    List<String>? category,
    required String sortBy,
    LocationModel? location,
    int? itemCount,
    double radius = 5000,
  }) async {
    if (listType == 'reco') {}
    var body = {
      'userid': userId,
      'productcount': itemCount ?? productCount,
    };

    if (category != null) {
      body.addAll({
        'category': category,
      });
    }

    if (listType != 'user') {
      body.addAll({
        'location': location!.toJson(),
        'radius': radius,
      });
    }

    body.addAll({
      'sortby': sortBy == 'name' ? 'productname' : sortBy.toLowerCase(),
      'sortdirection': sortBy == 'rating' ? 'descending' : 'ascending',
    });

    if (listType == 'reco' && interests != null) {
      body.addAll({'interests': interests});
    }

    final response = await _apiService.post(
      url: 'products/$listType/searchfirst',
      body: body,
    );

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['products'] as List<dynamic>).map((json) {
      return ProductModel.fromJson(json);
    }).toList();
  }

  Future<bool> deleteProduct(String id) async {
    final response = await _apiService.delete(url: 'products/$id');

    return response.data['status'] == 'SUCCESS';
  }

  Future<Map<String, dynamic>?> getProductRefData() async {
    final response = await _apiService.get(url: 'reference/productref');

    if (response.data['status'] != 'SUCCESS') return null;

    return {
      'categories': (response.data['product reference data']['categories']
              as List<dynamic>)
          .map((data) => ProductCategoryModel.fromJson(data))
          .toList(),
      'types':
          (response.data['product reference data']['types'] as List<dynamic>)
              .map((data) => ProductTypeModel.fromJson(data))
              .toList(),
    };
  }

  Future<bool> updateProduct(ProductRequestModel product) async {
    final response = await _apiService.post(
      url: 'products/update/${product.productid}',
      body: {
        ...product.toJson(updating: true),
      },
    );

    return response.data['status'] == 'SUCCESS';
  }

  Future<bool> deleteImages(
      List<String> urls, String userId, String productId) async {
    var body = {
      'userid': userId,
      'productid': productId,
    };

    if (urls.length > 0) {
      urls.asMap().forEach((key, value) {
        body.addAll({
          'media${key + 1}': value,
        });
      });
    }

    final response = await _apiService.post(
      url: 'products/delete',
      body: body,
    );

    if (response.data['status'] != 'SUCCESS') return false;

    return true;
  }

  Future<List<ProductModel>> searchProducts(List<String> keyword,
      {String? lastProductId,
      dynamic startAfterVal,
      List<String>? category,
      required String sortBy,
      required LocationModel location,
      int itemCount = 10,
      double radius = 5000}) async {
    var _body = {
      'sortby':
          sortBy.toLowerCase() == 'name' ? 'productname' : sortBy.toLowerCase(),
      'sortdirection':
          sortBy.toLowerCase() == 'rating' ? 'descending' : 'ascending',
      'productcount': itemCount,
      'userid': application.currentUser!.uid,
      'location': location.toJson(),
      'radius': radius,
      'type': 'PT1',
    };
    if (keyword.length > 0) _body.addAll({'keywords': keyword});
    if (category != null) _body.addAll({'category': category});
    if (lastProductId != null && startAfterVal != null) {
      _body.addAll({
        'startafterval': startAfterVal,
        'productid': lastProductId,
      });
    }
    final response = await _apiService.post(
      url:
          'products/${(lastProductId != null && startAfterVal != null) ? 'searchset' : 'searchfirst'}',
      body: _body,
    );

    if (response.data['status'] != 'SUCCESS') return [];

    return (response.data['products'] as List<dynamic>)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  Future<bool> addToWishList(String productId, String userId) async {
    final response = await _apiService.post(url: 'products/wishlist', body: {
      'userid': userId,
      'productid': productId,
    });

    return response.data['status'] == 'SUCCESS';
  }

  Future<bool> deleteRating(ProductReviewModel review) async {
    final response = await _apiService.delete(
      url: 'products/review/delete',
      body: {
        'productid': review.productid,
        'userid': application.currentUser!.uid,
      },
    );

    return response.data['status'] == 'SUCCESS';
  }

  Future<bool> addRating({
    required ProductRequestModel productRequest,
    required String userId,
    required double rating,
  }) async {
    final response = await _apiService.post(
      url: 'products/update/${productRequest.productid}',
      body: {
        ...productRequest.toJson(updating: true),
        'rating': rating,
      },
    );

    return response.data['status'] == 'SUCCESS';
  }

  Future<bool> likeProduct({
    required ProductRequestModel productRequest,
    required String userId,
    required int like,
  }) async {
    // final _productRef = FirebaseFirestore.instance.collection('user_likes');
    final response = await _apiService.post(
      url: 'products/like',
      body: {
        'productid': productRequest.productid,
        'productname': productRequest.productname,
        'userid': userId,
        'like': like,
        'price': productRequest.price,
        'image_url': productRequest.image_url,
      },
    );

    return response.data['status'] == 'SUCCESS';
  }
}

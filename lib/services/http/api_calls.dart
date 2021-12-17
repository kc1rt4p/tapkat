import 'api_manager.dart';

Future<dynamic> searchProductsCall({
  String searchString = '',
}) {
  final body = '''
{
  "psk": "lcp9321p",
  "keywords": [
    "${searchString}"
  ],
  "productcount": 50,
  "sortby": "price",
  "sortdirection": "ascending"
}''';
  return ApiManager.instance.makeApiCall(
    callName: 'Search Products',
    apiUrl: 'https://mapsurfapi-odyljeyswa-as.a.run.app/products/searchfirst',
    callType: ApiCallType.POST,
    headers: {},
    params: {
      'searchString': searchString,
    },
    body: body,
    bodyType: BodyType.JSON,
    returnResponse: true,
  );
}

Future<dynamic> getProductDetailsCall({
  String productid = '',
}) {
  return ApiManager.instance.makeApiCall(
    callName: 'Get product details',
    apiUrl:
        'https://mapsurfapi-odyljeyswa-as.a.run.app/products/single/$productid',
    callType: ApiCallType.GET,
    headers: {},
    params: {},
    returnResponse: true,
  );
}

Future<dynamic> addLikeToAProductCall({
  String productid = '',
  String userid = '',
}) {
  final body = '''
{
  "psk": "lcp9321p",
  "productid": "${productid}",
  "userid": "${userid}",
  "like": 1
}''';
  return ApiManager.instance.makeApiCall(
    callName: 'Add like to a product',
    apiUrl: 'https://api.cloud-next.com.au/products/update/$productid',
    callType: ApiCallType.POST,
    headers: {},
    params: {
      'userid': userid,
    },
    body: body,
    bodyType: BodyType.JSON,
    returnResponse: true,
  );
}

Future<dynamic> getUserLikesCall({
  String userid = '',
}) {
  return ApiManager.instance.makeApiCall(
    callName: 'Get user likes',
    apiUrl: 'https://api.cloud-next.com.au/users/likes/$userid',
    callType: ApiCallType.GET,
    headers: {},
    params: {},
    returnResponse: true,
  );
}

Future<dynamic> addMarkerForMapViewCall({
  String productname = '',
  double? latitude,
  double? longitude,
  double? price,
  String productid = '',
}) {
  final body = '''
{
  "psk": "lcp9321p",
  "productid": "${productid}",
  "productname": "${productname}",
  "latitude": ${latitude},
  "longitude": ${longitude},
  "price": ${price}
}''';
  return ApiManager.instance.makeApiCall(
    callName: 'Add marker for map view',
    apiUrl: 'https://api.cloud-next.com.au/products/addmarker',
    callType: ApiCallType.POST,
    headers: {},
    params: {
      'productname': productname,
      'latitude': latitude,
      'longitude': longitude,
      'price': price,
      'productid': productid,
    },
    body: body,
    bodyType: BodyType.JSON,
    returnResponse: true,
  );
}

Future<dynamic> addProductCall({
  String userid = '',
  String productname = '',
  String productdesc = '',
  double? price,
  String type = '',
  String category = '',
  double? latitude,
  double? longitude,
  String mediaType = '',
  String imageUrl = '',
}) {
  final body = '''
{
  "psk": "lcp9321p",
  "userid": "${userid}",
  "productname": "${productname}",
  "productdesc": "${productdesc}",
  "price": ${price},
  "type": "${type}",
  "category": "${category}",
  "media_type": "${mediaType}",
  "image_url": "${imageUrl}"
}''';
  return ApiManager.instance.makeApiCall(
    callName: 'Add Product',
    apiUrl: 'https://api.cloud-next.com.au/products',
    callType: ApiCallType.POST,
    headers: {},
    params: {
      'userid': userid,
      'productname': productname,
      'productdesc': productdesc,
      'price': price,
      'type': type,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'media_type': mediaType,
      'image_url': imageUrl,
    },
    body: body,
    bodyType: BodyType.JSON,
    returnResponse: true,
  );
}

Future<dynamic> deleteAProductCall({
  String productid = '',
}) {
  return ApiManager.instance.makeApiCall(
    callName: 'Delete a product',
    apiUrl: 'https://mapsurfapi-odyljeyswa-as.a.run.app/products/$productid',
    callType: ApiCallType.DELETE,
    headers: {},
    params: {},
    returnResponse: true,
  );
}

Future<dynamic> updateProductCall({
  String userid = '',
  String productid = '',
  String productname = '',
  double? price,
  String type = '',
  String category = '',
  double? latitude,
  double? longitude,
  String mediaType = '',
  String imageUrl = '',
  String productdesc = '',
}) {
  final body = '''
{
  "psk": "lcp9321p",
  "userid": "${userid}",
  "productid": "${productid}",
  "productname": "${productname}",
  "productdesc": "${productdesc}",
  "price": ${price},
  "type": "${type}",
  "category": "${category}",
  "media_type": "${mediaType}",
  "image_url": "${imageUrl}"
}''';
  return ApiManager.instance.makeApiCall(
    callName: 'Update product',
    apiUrl: 'https://api.cloud-next.com.au/products/update/$productid',
    callType: ApiCallType.POST,
    headers: {},
    params: {
      'userid': userid,
      'productname': productname,
      'price': price,
      'type': type,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'media_type': mediaType,
      'image_url': imageUrl,
      'productdesc': productdesc,
    },
    body: body,
    bodyType: BodyType.JSON,
    returnResponse: true,
  );
}

Future<dynamic> getProductsInDemandCall({
  String userid = '',
}) {
  final body = '''
{
  "psk": "lcp9321p",
  "userid": "${userid}",
  "productcount": 20,
  "sortby": "price",
  "sortdirection": "descending"
}''';
  return ApiManager.instance.makeApiCall(
    callName: 'Get products in demand',
    apiUrl: 'https://api.cloud-next.com.au/products/demand/searchfirst',
    callType: ApiCallType.POST,
    headers: {},
    params: {
      'userid': userid,
    },
    body: body,
    bodyType: BodyType.JSON,
    returnResponse: true,
  );
}

Future<dynamic> getRecommendedProductsCall({
  String userid = '',
}) {
  final body = '''
{
  "psk": "lcp9321p",
  "userid": "${userid}",
  "productcount": 20,
  "sortby": "price",
  "sortdirection": "ascending"
}''';
  return ApiManager.instance.makeApiCall(
    callName: 'Get recommended products',
    apiUrl: 'https://api.cloud-next.com.au/products/reco/searchfirst',
    callType: ApiCallType.POST,
    headers: {},
    params: {
      'userid': userid,
    },
    body: body,
    bodyType: BodyType.JSON,
    returnResponse: true,
  );
}

Future<dynamic> getUserProductsCall({
  String userid = '',
}) {
  final body = '''
{
  "psk": "lcp9321p",
  "userid": "${userid}",
  "productcount": 20,
  "sortby": "productname",
  "sortdirection": "ascending"
}''';
  return ApiManager.instance.makeApiCall(
    callName: 'Get user products',
    apiUrl: 'https://api.cloud-next.com.au/products/user/searchfirst',
    callType: ApiCallType.POST,
    headers: {},
    params: {
      'userid': userid,
    },
    body: body,
    bodyType: BodyType.JSON,
    returnResponse: true,
  );
}

Future<dynamic> addWishlistRecordCall({
  String userid = '',
  String productid = '',
}) {
  final body = '''
{
  "psk": "lcp9321p",
  "userid": "${userid}",
  "productid": "${productid}"
}''';
  return ApiManager.instance.makeApiCall(
    callName: 'Add wishlist record',
    apiUrl: 'https://api.cloud-next.com.au/products/wishlist',
    callType: ApiCallType.POST,
    headers: {},
    params: {
      'userid': userid,
      'productid': productid,
    },
    body: body,
    bodyType: BodyType.JSON,
    returnResponse: true,
  );
}

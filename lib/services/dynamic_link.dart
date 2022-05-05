import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class DynamincLinkService {
  FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;

  final String DynamicLink = 'https://tapkat.page.link/product';
  final String Link = 'https://tapkat.page.link/product';

  Future<Uri> createDynamicLink(
      {bool short = true, Map<String, dynamic>? data}) async {
    // setState(() {
    //   _isCreatingLink = true;
    // });

    String newDynamicLink = DynamicLink;

    if (data != null) {
      data.forEach((key, value) {
        newDynamicLink += '?$key=$value';
      });
    }

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://tapkat.page.link/',
      longDynamicLink: Uri.parse(
        'https://tapkat.page.link/?link=https://tapkat.page.link/product?productid=${data!['productid']}&apn=com.flutterflow.tapkat',
      ),
      link: Uri.parse(newDynamicLink),
      androidParameters: const AndroidParameters(
        packageName: 'com.flutterflow.tapkat',
        minimumVersion: 0,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.flutterflow.tapkat',
        minimumVersion: '0',
      ),
    );
    Uri url;
    if (short) {
      final ShortDynamicLink shortLink =
          await dynamicLinks.buildShortLink(parameters);
      url = shortLink.shortUrl;
    } else {
      url = await dynamicLinks.buildLink(parameters);
    }

    return url;

    // setState(() {
    //   _linkMessage = url.toString();
    //   _isCreatingLink = false;
    // });
  }
}

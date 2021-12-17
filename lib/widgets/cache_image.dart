import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CacheImage extends StatelessWidget {
  final String url;
  final double height;
  final double width;
  final double borderRadius;
  final BoxFit fit;
  final List<BoxShadow>? boxShadow;

  CacheImage(this.url,
      {this.height = double.maxFinite,
      this.width = double.infinity,
      this.borderRadius = 0.0,
      this.fit = BoxFit.contain,
      this.boxShadow});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: boxShadow,
          image: DecorationImage(
            image: imageProvider,
            fit: fit,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }
}

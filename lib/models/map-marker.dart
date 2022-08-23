import 'package:fluster/fluster.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:label_marker/label_marker.dart';
import 'package:meta/meta.dart';

class MapMarker extends Clusterable {
  final String id;
  final String? productName;
  final LatLng position;
  Function()? onTap;
  BitmapDescriptor icon;
  MapMarker({
    required this.id,
    required this.position,
    this.productName,
    this.icon = BitmapDescriptor.defaultMarker,
    this.onTap,
    isCluster = false,
    clusterId,
    pointsSize,
    childMarkerId,
  }) : super(
          markerId: id,
          latitude: position.latitude,
          longitude: position.longitude,
          isCluster: isCluster,
          clusterId: clusterId,
          pointsSize: pointsSize,
          childMarkerId: childMarkerId,
        );
  Marker toMarker() => Marker(
        onTap: onTap,
        markerId: MarkerId(id),
        position: LatLng(
          position.latitude,
          position.longitude,
        ),
        icon: icon,
      );

  LabelMarker toLabelMarker() => LabelMarker(
        label: productName ?? '',
        markerId: MarkerId(id),
        position: position,
      );
}

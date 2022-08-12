import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/screens/store/bloc/store_bloc.dart';
import 'package:tapkat/screens/store/component/store_list_item.dart';
import 'package:tapkat/screens/store/store_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:label_marker/label_marker.dart';

import 'package:tapkat/utilities/application.dart' as application;
import 'package:tapkat/widgets/tapkat_map.dart';
import 'package:toggle_switch/toggle_switch.dart';

class StoreListScreen extends StatefulWidget {
  const StoreListScreen({Key? key}) : super(key: key);

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  final _storeBloc = StoreBloc();
  final _authBloc = AuthBloc();
  final _storePageController =
      PagingController<int, StoreModel>(firstPageKey: 0);
  StoreModel? lastStore;
  List<StoreModel> _list = [];
  int currentPage = 0;
  String _selectedView = 'grid';
  Set<Marker> _markers = {};
  final _userRepo = UserRepository();
  double mapZoomLevel = 11;

  late LatLng _currentCenter;

  final barterRef = FirebaseFirestore.instance.collection('userstore_likes');

  LatLng? googleMapsCenter;
  late GoogleMapController googleMapsController;

  @override
  void initState() {
    application.currentScreen = 'Store List Screen';
    super.initState();

    setOriginalCenter();
    _storeBloc.add(GetFirstTopStores());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener(
            bloc: _storeBloc,
            listener: (context, state) {
              if (state is GetFirstTopStoresSuccess) {
                lastStore = null;
                _list.clear();
                if (state.list.isNotEmpty) {
                  _list = state.list;

                  lastStore = state.list.last;

                  if (state.list.length == productCount) {
                    _storePageController.appendPage(
                        state.list, currentPage + 1);
                  } else {
                    _storePageController.appendLastPage(state.list);
                  }
                } else {
                  _storePageController.appendLastPage([]);
                }

                // _refreshController.refreshCompleted();

                _storePageController.addPageRequestListener((pageKey) {
                  if (lastStore != null) {
                    _storeBloc.add(
                      GetNextTopStores(
                        lastUserId: lastStore!.userid!,
                        lastUserRating: lastStore!.rating!,
                      ),
                    );
                  } else {
                    _storePageController.refresh();
                  }
                });
              }

              if (state is GetNextTopStoresSuccess) {
                if (state.list.isNotEmpty) {
                  lastStore = state.list.last;
                  if (state.list.length == productCount) {
                    _storePageController.appendPage(
                        state.list, currentPage + 1);
                  } else {
                    _storePageController.appendLastPage(state.list);
                  }
                } else {
                  _storePageController.appendLastPage([]);
                }
              }
            },
          ),
        ],
        child: Column(
          children: [
            CustomAppBar(
              label: 'Top Stores',
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20.0,
              ),
              child: CustomSearchBar(
                controller: TextEditingController(),
                hintText: 'Search store name',
                backgroundColor: kBackgroundColor,
                textColor: Colors.white,
                margin: EdgeInsets.zero,
              ),
            ),
            FittedBox(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.0,
                ),
                child: ToggleSwitch(
                  activeBgColor: [kBackgroundColor],
                  initialLabelIndex: _selectedView == 'grid' ? 0 : 1,
                  minWidth: SizeConfig.screenWidth,
                  minHeight: 20.0,
                  borderColor: [Color(0xFFEBFBFF)],
                  totalSwitches: 2,
                  customTextStyles: [
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.textScaleFactor * 15,
                      color: Colors.white,
                    ),
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.textScaleFactor * 15,
                      color: Colors.white,
                    ),
                  ],
                  icons: [
                    Icons.grid_view,
                    Icons.map,
                  ],
                  inactiveFgColor: Colors.white60,
                  labels: [
                    'Grid',
                    'Map',
                  ],
                  onToggle: (index) {
                    setState(() {
                      _selectedView = index == 0 ? 'grid' : 'map';
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child:
                  _selectedView == 'map' ? _buildMapView() : _buildGridView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10.0),
      child: Stack(
        children: [
          TapkatGoogleMap(
            // circles: {
            //   _currentCircle!,
            // },
            onTap: (latLng) {},
            onCameraMove: (camPos) {},
            onCameraIdle: (latLng) => googleMapsCenter = latLng,
            initialZoom: mapZoomLevel,
            initialLocation: _currentCenter,
            onMapCreated: (controller) {
              googleMapsController = controller;
            },
            showLocation: false,
            showZoomControls: false,
            markers: _markers.toSet(),
          ),
          Positioned(
            right: 5.0,
            top: 10.0,
            child: FloatingActionButton.small(
              backgroundColor: kBackgroundColor.withOpacity(0.7),
              onPressed: () {
                setOriginalCenter();
                googleMapsController
                    .animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(
                      target: _currentCenter, zoom: mapZoomLevel + 2),
                ));
              },
              child: Icon(
                Icons.my_location,
              ),
            ),
          ),
          Positioned(
            right: 15.0,
            bottom: 30.0,
            child: Column(
              children: [
                InkWell(
                  onTap: () async {
                    setState(() {
                      mapZoomLevel += 1;
                    });
                    googleMapsController
                        .animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                          target: _currentCenter, zoom: mapZoomLevel),
                    ));
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    child: Icon(
                      FontAwesomeIcons.plus,
                      size: 22,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ),
                Divider(
                  color: Colors.black,
                  height: 1,
                ),
                InkWell(
                  onTap: () async {
                    setState(() {
                      mapZoomLevel -= 1;
                    });
                    googleMapsController
                        .animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _currentCenter,
                        zoom: mapZoomLevel,
                      ),
                    ));
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    child: Icon(
                      FontAwesomeIcons.minus,
                      size: 22,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // _buildMarkers() async {
  //   if (_list.isNotEmpty) {
  //     setState(
  //       () {
  //         _list.forEach(
  //           (store) {
  //             _markers
  //                 .addLabelMarker(
  //                   LabelMarker(
  //                     label: store.display_name ?? '',
  //                     markerId: MarkerId(store.userid ?? DateTime.now().millisecondsSinceEpoch.toString()),
  //                     position: LatLng(
  //                       store.address != null &&
  //                               store.address!.location != null
  //                           ? store.address!.location!.latitude!.toDouble()
  //                           : 0.00,
  //                       store.address != null &&
  //                               store.address!.location != null
  //                           ? store.address!.location!.longitude!.toDouble()
  //                           : 0.00,
  //                     ),
  //                     backgroundColor: kBackgroundColor,
  //                     textStyle: TextStyle(
  //                       color: Colors.white,
  //                       fontWeight: FontWeight.w600,
  //                       fontSize: 27.0,
  //                       letterSpacing: 1.0,
  //                       fontFamily: 'Poppins',
  //                       leadingDistribution: TextLeadingDistribution.even,
  //                       inherit: false,
  //                       decorationStyle: TextDecorationStyle.solid,
  //                     ),
  //                   ),
  //                 )
  //                 .then(
  //                   (value) => setState(() {}),
  //                 );
  //           },
  //         );
  //       },
  //     );
  //   } else {
  //     setState(() {
  //       _markers.clear();
  //     });
  //   }

  //   setState(() {
  //     _markers.add(Marker(
  //       markerId: MarkerId(application.currentUser!.uid),
  //       position: _currentCenter,
  //     ));
  //   });

  //   // if (markers.isNotEmpty) {
  //   //   setState(() {
  //   //     _markers = markers;
  //   //   });
  //   // }
  // }

  void setOriginalCenter() {
    setState(() {
      _currentCenter = LatLng(
          application.currentUserLocation!.latitude!.toDouble(),
          application.currentUserLocation!.longitude!.toDouble());
    });
  }

  PagedGridView<int, StoreModel> _buildGridView() {
    return PagedGridView<int, StoreModel>(
      pagingController: _storePageController,
      showNewPageProgressIndicatorAsGridChild: false,
      showNewPageErrorIndicatorAsGridChild: false,
      showNoMoreItemsIndicatorAsGridChild: false,
      padding: EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 10.0,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 10,
        crossAxisSpacing: 16,
        crossAxisCount: 2,
      ),
      builderDelegate: PagedChildBuilderDelegate<StoreModel>(
        itemBuilder: (context, store, index) {
          return StreamBuilder<bool>(
            stream: _userRepo.streamUserOnlineStatus(store.userid!),
            builder: (context, snapshot) {
              bool online = false;
              if (snapshot.hasData) {
                online = snapshot.data ?? false;
              }
              return FittedBox(
                child: Stack(
                  children: [
                    StoreListItem(
                      StoreModel(
                        display_name: store.display_name,
                        userid: store.userid,
                        photo_url: store.photo_url,
                      ),
                      removeLike: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoreScreen(
                            userId: store.userid!,
                            userName: store.display_name!,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 5,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 12.0,
                            width: 12.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            height: 10.0,
                            width: 10.0,
                            decoration: BoxDecoration(
                              color: online ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
          // return FittedBox(
          //   child: StoreListItem(
          //     StoreModel(
          //       display_name: store.display_name,
          //       userid: store.userid,
          //       photo_url: store.photo_url,
          //     ),
          //     onTap: () => Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => StoreScreen(
          //           userId: store.userid!,
          //           userName: store.display_name!,
          //         ),
          //       ),
          //     ),
          //   ),
          // );
        },
      ),
    );
  }
}

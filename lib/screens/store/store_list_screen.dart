import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/store.dart';
import 'package:tapkat/models/top_store.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/repositories/user_repository.dart';
import 'package:tapkat/screens/store/bloc/store_bloc.dart';
import 'package:tapkat/screens/store/component/store_list_item.dart';
import 'package:tapkat/screens/store/store_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:label_marker/label_marker.dart';

import 'package:tapkat/utilities/application.dart' as application;
import 'package:tapkat/widgets/tapkat_map.dart';
import 'package:toggle_switch/toggle_switch.dart';

class StoreListScreen extends StatefulWidget {
  final String initialView;
  const StoreListScreen({
    Key? key,
    this.initialView = 'grid',
  }) : super(key: key);

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  final _storeBloc = StoreBloc();
  final _authBloc = AuthBloc();
  final _storePageController =
      PagingController<int, TopStoreModel>(firstPageKey: 0);
  TopStoreModel? lastStore;
  List<TopStoreModel> _list = [];
  int currentPage = 0;
  String _selectedView = 'grid';
  Set<Marker> _markers = {};
  final _userRepo = UserRepository();
  double mapZoomLevel = 11;
  late String initialView;

  late LatLng _currentCenter;

  final barterRef = FirebaseFirestore.instance.collection('userstore_likes');

  LatLng? googleMapsCenter;
  late GoogleMapController googleMapsController;

  double _selectedRadius = 5000;
  String _selectedSortBy = 'distance';

  List<String> sortByOptions = [
    'Distance',
    'Rating',
  ];

  @override
  void initState() {
    application.currentScreen = 'Store List Screen';
    super.initState();
    if (widget.initialView == 'map') {
      _selectedView = 'map';
    }

    setOriginalCenter();
    _storeBloc.add(GetFirstTopStores(
      sortBy: _selectedSortBy,
      radius: _selectedRadius,
    ));
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

                  if (state.list.length == 10) {
                    _storePageController.appendPage(
                        state.list, currentPage + 1);
                  } else {
                    _storePageController.appendLastPage(state.list);
                  }
                } else {
                  _list.clear();
                  _storePageController.appendLastPage([]);
                }
                _buildMarkers();

                // _refreshController.refreshCompleted();

                _storePageController.addPageRequestListener((pageKey) {
                  if (lastStore != null) {
                    _storeBloc.add(
                      GetNextTopStores(
                        radius: _selectedRadius,
                        sortBy: _selectedSortBy,
                        userId: lastStore!.userid!,
                        startAfterVal: _selectedSortBy == 'distance'
                            ? lastStore!.distance!
                            : lastStore!.rating!,
                      ),
                    );
                  }
                });
              }

              if (state is GetNextTopStoresSuccess) {
                if (state.list.isNotEmpty) {
                  _list.addAll(state.list);
                  lastStore = state.list.last;
                  if (state.list.length == 10) {
                    _storePageController.appendPage(
                        state.list, currentPage + 1);
                  } else {
                    _storePageController.appendLastPage(state.list);
                  }
                } else {
                  _list.clear();
                  _storePageController.appendLastPage([]);
                }
                _buildMarkers();
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
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20.0,
              ),
              margin: EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distance',
                          style: TextStyle(
                            fontSize: SizeConfig.textScaleFactor * 12,
                          ),
                        ),
                        SizedBox(height: 5.0),
                        InkWell(
                          onTap: _onSelectDistance,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: kBackgroundColor,
                                  width: 0.6,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _displayRadius(),
                                  style: Style.subtitle2.copyWith(
                                    color: kBackgroundColor,
                                    fontSize: SizeConfig.textScaleFactor * 12,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  FontAwesomeIcons.chevronDown,
                                  color: kBackgroundColor,
                                  size: SizeConfig.textScaleFactor * 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  VerticalDivider(),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sort by',
                          style: TextStyle(
                            fontSize: SizeConfig.textScaleFactor * 12,
                            color: _selectedView == 'map'
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                        SizedBox(height: 5.0),
                        InkWell(
                          onTap: _selectedView != 'map' ? _onSortBy : null,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedView == 'map'
                                      ? Colors.grey
                                      : kBackgroundColor,
                                  width: 0.6,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${_selectedSortBy[0].toUpperCase()}${_selectedSortBy.substring(1).toLowerCase()}',
                                  style: Style.subtitle2.copyWith(
                                    color: _selectedView != 'map'
                                        ? kBackgroundColor
                                        : Colors.grey,
                                    fontSize: SizeConfig.textScaleFactor * 12,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  FontAwesomeIcons.chevronDown,
                                  color: _selectedView == 'map'
                                      ? Colors.grey
                                      : kBackgroundColor,
                                  size: SizeConfig.textScaleFactor * 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

  _onSortBy() async {
    final sortBy = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sort by',
                        style: Style.subtitle2.copyWith(
                            color: kBackgroundColor,
                            fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context, null),
                        child: Icon(
                          FontAwesomeIcons.times,
                          color: kBackgroundColor,
                          size: 20.0,
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    shrinkWrap: true,
                    // mainAxisSize: MainAxisSize.min,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0),
                      ...sortByOptions.map(
                        (item) => ListTile(
                          title: Text(item),
                          contentPadding: EdgeInsets.zero,
                          onTap: () => Navigator.pop(context, item),
                          selectedColor: Color(0xFFBB3F03),
                          selected: _selectedSortBy.toLowerCase() ==
                              item.toLowerCase(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });

    if (sortBy != null) {
      setState(() {
        _selectedSortBy = sortBy;
      });
      _storePageController.refresh();
      _storeBloc.add(GetFirstTopStores(
        sortBy: _selectedSortBy,
        radius: _selectedRadius,
      ));
    }
  }

  String _displayRadius() {
    final radius = _selectedRadius;
    final ave = ((radius / 1000) * 2).round() / 2;
    print('X---> $ave');
    return '${ave.toStringAsFixed(2)} km';
  }

  Widget _buildMapView() {
    _buildMarkers();
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

  _buildMarkers() async {
    if (_list.isNotEmpty) {
      setState(
        () {
          _list.forEach(
            (store) {
              _markers
                  .addLabelMarker(
                    LabelMarker(
                      label: store.display_name ?? '',
                      markerId: MarkerId(store.userid ??
                          DateTime.now().millisecondsSinceEpoch.toString()),
                      position: LatLng(
                        store.geo_location != null
                            ? store.geo_location!.lat!
                            : 0.00,
                        store.geo_location != null
                            ? store.geo_location!.lng!
                            : 0.00,
                      ),
                      backgroundColor: kBackgroundColor,
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 27.0,
                        letterSpacing: 1.0,
                        fontFamily: 'Poppins',
                        leadingDistribution: TextLeadingDistribution.even,
                        inherit: false,
                        decorationStyle: TextDecorationStyle.solid,
                      ),
                    ),
                  )
                  .then(
                    (value) => setState(() {}),
                  );
            },
          );
        },
      );
    } else {
      setState(() {
        _markers.clear();
      });
    }

    setState(() {
      _markers.add(Marker(
        markerId: MarkerId(application.currentUser!.uid),
        position: _currentCenter,
      ));
    });
  }

  _onSelectDistance() async {
    final distance = await showDialog<double?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          double radiusSelected = _selectedRadius.toDouble();
          final radiusTextController = TextEditingController();
          radiusTextController.text =
              (radiusSelected / 1000).toStringAsFixed(2);
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return Dialog(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Search radius distance',
                          style: Style.subtitle2.copyWith(
                              color: kBackgroundColor,
                              fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context, null),
                          child: Icon(
                            FontAwesomeIcons.times,
                            color: kBackgroundColor,
                            size: 20.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      controller: radiusTextController,
                      autovalidateMode: AutovalidateMode.always,
                      decoration: InputDecoration(
                        isDense: true,
                        border: UnderlineInputBorder(),
                        suffixIcon: Text('km'),
                        suffixIconConstraints:
                            BoxConstraints(maxHeight: 50.0, maxWidth: 50.0),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val != null) {
                          if (val.isEmpty) return null;

                          final radius = double.parse(val.trim()) * 1000;

                          if (radius < 500 || radius > 30000) {
                            return 'Distance should be between 0.5km and 30km';
                          }
                        }

                        return null;
                      },
                      onChanged: (val) {
                        if (val.isEmpty) return;
                        final radius = double.parse(val) * 1000;
                        if (radius < 500 || radius > 30000) {
                          return;
                        } else {
                          setState(() {
                            radiusSelected = radius;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (radiusSelected > 1000) {
                                radiusSelected -= 500;
                              } else {
                                radiusSelected = 500;
                              }
                            });
                            print(radiusSelected);
                            radiusTextController.text =
                                (radiusSelected / 1000).toStringAsFixed(2);
                          },
                          child: Icon(Icons.remove, size: 20),
                        ),
                        SizedBox(width: 5.0),
                        Expanded(
                          child: Slider(
                            activeColor: kBackgroundColor,
                            thumbColor: kBackgroundColor,
                            value: radiusSelected,
                            onChanged: (val) {
                              setState(() {
                                radiusSelected = val;
                              });
                              radiusTextController.text =
                                  (radiusSelected / 1000).toStringAsFixed(2);
                            },
                            min: 0,
                            max: 30000,
                            divisions: 60,
                          ),
                        ),
                        SizedBox(width: 5.0),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (radiusSelected < 29500) {
                                radiusSelected += 500;
                              } else {
                                radiusSelected = 30000;
                              }
                            });
                            radiusTextController.text =
                                (radiusSelected / 1000).toStringAsFixed(2);
                          },
                          child: Icon(Icons.add, size: 20),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.0),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            removeMargin: true,
                            label: 'Cancel',
                            onTap: () => Navigator.pop(context, null),
                            bgColor: kBackgroundColor,
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Expanded(
                          child: CustomButton(
                            removeMargin: true,
                            label: 'Apply',
                            onTap: () => Navigator.pop(context, radiusSelected),
                            bgColor: Style.secondaryColor,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          });
        });

    if (distance == null) {
      return;
    }

    setState(() {
      _selectedRadius = distance;
    });
    _storePageController.refresh();

    _storeBloc.add(GetFirstTopStores(
      sortBy: _selectedSortBy,
      radius: _selectedRadius,
    ));
  }

  void setOriginalCenter() {
    setState(() {
      _currentCenter = LatLng(
          application.currentUserLocation!.latitude!.toDouble(),
          application.currentUserLocation!.longitude!.toDouble());
    });
  }

  PagedGridView<int, TopStoreModel> _buildGridView() {
    return PagedGridView<int, TopStoreModel>(
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
      builderDelegate: PagedChildBuilderDelegate<TopStoreModel>(
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
                      store,
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

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/product/product_add_screen.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/screens/settings/settings_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  UserModel? _userModel;
  SelectedMedia? _selectedMedia;
  final _profileBloc = ProfileBloc();
  late AuthBloc _authBloc;
  List<ProductModel> _list = [];
  bool editProfile = false;
  final _displayNameTextController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _phoneTextController = TextEditingController();
  PlaceDetails? _selectedLocation;
  final _locationTextController = TextEditingController();
  final iOSGoogleMapsApiKey = 'AIzaSyBCyNgeJDA8_nwdGrPf5ecuIsVFRXSF0mQ';
  final androidGoogleMapsApiKey = 'AIzaSyAH4fWM5IbEO0X-Txkm6HNsFAQ3KOfW20I';
  final webGoogleMapsApiKey = 'AIzaSyAzPjfTTLzdfp-56tarHguvLXgdw7QAGkg';

  @override
  void initState() {
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _profileBloc.add(InitializeProfileScreen());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
        barrierEnabled: false,
        indicatorColor: kBackgroundColor,
        backgroundColor: Colors.white,
        child: MultiBlocListener(
          listeners: [
            BlocListener(
              bloc: _profileBloc,
              listener: (context, state) {
                if (state is ProfileLoading) {
                  ProgressHUD.of(context)!.show();
                } else {
                  ProgressHUD.of(context)!.dismiss();
                }

                if (state is ProfileScreenInitialized) {
                  setState(() {
                    _user = state.user;
                    _list = state.list;
                    _userModel = state.userModel;
                  });

                  _displayNameTextController.text =
                      _user!.displayName ?? 'Unknown';
                  _emailTextController.text = _userModel!.email ?? 'Unknown';
                  _phoneTextController.text =
                      _userModel!.mobilenum ?? 'Unknown';
                  _locationTextController.text = 'Unknown';
                }
              },
            ),
          ],
          child: Container(
            color: Color(0xFFEBFBFF),
            child: Column(
              children: [
                CustomAppBar(
                  label: 'Your Store',
                  hideBack: true,
                  leading: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(),
                      ),
                    ),
                    child: Icon(
                      FontAwesomeIcons.cog,
                      color: Colors.white,
                    ),
                  ),
                  action: GestureDetector(
                    onTap: _onSignOut,
                    child: Icon(
                      FontAwesomeIcons.signOutAlt,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: _user != null
                        ? Column(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: kBackgroundColor,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 10.0,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Info',
                                      style: Style.subtitle2
                                          .copyWith(color: Colors.white),
                                    ),
                                    Spacer(),
                                    Visibility(
                                      visible: editProfile,
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                editProfile = !editProfile;
                                              });
                                            },
                                            child: Icon(
                                              FontAwesomeIcons.times,
                                              color: Colors.white,
                                              size: 18.0,
                                            ),
                                          ),
                                          SizedBox(width: 10.0),
                                          GestureDetector(
                                            onTap: () {
                                              //
                                            },
                                            child: Icon(
                                              FontAwesomeIcons.solidSave,
                                              color: Colors.white,
                                              size: 18.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Visibility(
                                      visible: !editProfile,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            editProfile = !editProfile;
                                          });
                                        },
                                        child: Icon(
                                          FontAwesomeIcons.solidEdit,
                                          color: Colors.white,
                                          size: 18.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _buildPhoto(),
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: 10.0,
                                      ),
                                      width: double.infinity,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          _buildInfoItem(
                                            label: 'Display name',
                                            controller:
                                                _displayNameTextController,
                                          ),
                                          _buildInfoItem(
                                            label: 'Email',
                                            controller: _emailTextController,
                                          ),
                                          _buildInfoItem(
                                            label: 'Phone number',
                                            controller: _phoneTextController,
                                          ),
                                          _buildInfoItem(
                                            label: 'Location',
                                            controller: _locationTextController,
                                            suffix: Icon(
                                              FontAwesomeIcons.mapMarked,
                                              color: kBackgroundColor,
                                              size: 12.0,
                                            ),
                                            onTap: _onSelectLocation,
                                            readOnly: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: kBackgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.0,
                                          horizontal: 10.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Products',
                                              style: Style.subtitle2.copyWith(
                                                  color: Colors.white),
                                            ),
                                            Spacer(),
                                            GestureDetector(
                                              onTap: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ProductAddScreen(),
                                                  ),
                                                );

                                                _profileBloc.add(
                                                    InitializeProfileScreen());
                                              },
                                              child: Icon(
                                                FontAwesomeIcons.plus,
                                                color: Colors.white,
                                                size: 18.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          child: _list.isNotEmpty
                                              ? GridView.count(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10.0,
                                                      vertical: 10.0),
                                                  crossAxisCount: 2,
                                                  mainAxisSpacing: 14.0,
                                                  crossAxisSpacing: 12.0,
                                                  children: _list
                                                      .map(
                                                        (product) => Center(
                                                          child: BarterListItem(
                                                            hideLikeBtn: true,
                                                            itemName: product
                                                                    .productname ??
                                                                '',
                                                            itemPrice: product
                                                                        .price !=
                                                                    null
                                                                ? product.price!
                                                                    .toStringAsFixed(
                                                                        2)
                                                                : '0',
                                                            imageUrl: product
                                                                            .mediaPrimary !=
                                                                        null &&
                                                                    product.mediaPrimary!
                                                                            .url !=
                                                                        null &&
                                                                    product
                                                                        .mediaPrimary!
                                                                        .url!
                                                                        .isNotEmpty
                                                                ? product
                                                                    .mediaPrimary!
                                                                    .url!
                                                                : '',
                                                            onTapped: () =>
                                                                Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        ProductDetailsScreen(
                                                                  ownItem: true,
                                                                  productId:
                                                                      product.productid ??
                                                                          '',
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                )
                                              : Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 30.0),
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          'No products found',
                                                          style: Style.subtitle2
                                                              .copyWith(
                                                                  color: Colors
                                                                      .grey),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container _buildInfoItem({
    required String label,
    required TextEditingController controller,
    Widget? suffix,
    Function()? onTap,
    bool readOnly = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.0),
      padding: EdgeInsets.symmetric(
        horizontal: 20.0,
      ),
      child: Column(
        children: [
          TextFormField(
            controller: controller,
            style: Style.fieldText,
            textAlign: TextAlign.center,
            readOnly: !editProfile || readOnly,
            onTap: onTap,
            enabled: editProfile,
            decoration: InputDecoration(
              isDense: true,
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
              hintText: '',
              disabledBorder: InputBorder.none,
              border: !editProfile
                  ? null
                  : UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: kBackgroundColor.withOpacity(0.5),
                      ),
                    ),
              focusedBorder: !editProfile
                  ? null
                  : UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: kBackgroundColor.withOpacity(0.5),
                      ),
                    ),
              enabledBorder: !editProfile
                  ? null
                  : UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: kBackgroundColor.withOpacity(0.5),
                      ),
                    ),
              errorBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.red,
                ),
              ),
              suffixIconConstraints:
                  BoxConstraints(maxHeight: 25, maxWidth: 25),
              suffixIcon: editProfile ? suffix : null,
            ),
          ),
          Text(
            label,
            style: Style.fieldTitle.copyWith(color: kBackgroundColor),
          ),
        ],
      ),
    );
  }

  _onSignOut() {
    DialogMessage.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to log out?',
      buttonText: 'Yes',
      firstButtonClicked: () => _authBloc.add(SignOut()),
      secondButtonText: 'No',
      hideClose: true,
    );
  }

  Stack _buildPhoto() {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100.0),
            image: DecorationImage(
              image: _selectedMedia == null
                  ? _userModel != null &&
                          (_userModel!.photo_url != null &&
                              _userModel!.photo_url != '')
                      ? CachedNetworkImageProvider(_userModel!.photo_url!)
                      : AssetImage('assets/images/profile_placeholder.png')
                          as ImageProvider<Object>
                  : FileImage(
                      File(_selectedMedia!.rawPath!),
                    ),
              scale: 1.0,
              fit: BoxFit.cover,
            ),
          ),
          height: 115.0,
          width: 115.0,
        ),
        Positioned(
          bottom: 0,
          right: 10,
          child: InkWell(
            onTap: _onPhotoTapped,
            child: Container(
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(50.0),
                // border: Border.all(color: Colors.black45),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 0),
                    blurRadius: 3.0,
                  ),
                ],
              ),
              height: 30.0,
              width: 30.0,
              child: Icon(
                Icons.photo_camera,
                color: Colors.white,
                size: 20.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<Null> displayPrediction(Prediction? p) async {
    if (p != null) {
      // get detail (lat/lng)
      GoogleMapsPlaces _places = GoogleMapsPlaces(
        apiKey: googleMapsApiKey,
        apiHeaders: await GoogleApiHeaders().getHeaders(),
      );
      PlacesDetailsResponse detail =
          await _places.getDetailsByPlaceId(p.placeId!);
      setState(() {
        _selectedLocation = detail.result;
      });
      _locationTextController.text = _selectedLocation!.formattedAddress!;
    }
  }

  String get googleMapsApiKey {
    if (kIsWeb) {
      return webGoogleMapsApiKey;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return '';
      case TargetPlatform.iOS:
        return iOSGoogleMapsApiKey;
      case TargetPlatform.android:
        return androidGoogleMapsApiKey;
      default:
        return webGoogleMapsApiKey;
    }
  }

  Future<void> _onSelectLocation() async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: googleMapsApiKey,
      onError: (response) => print('Error occured when getting places response:'
          '\n${response.errorMessage}'),
      mode: Mode.overlay,
      types: [],
      components: [],
      strictbounds: false,
    );

    if (p != null && p.placeId != null) displayPrediction(p);
  }

  _onPhotoTapped() {
    //
  }
}

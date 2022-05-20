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
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/request/update_user.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_add_screen.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/reviews/user_review_list_screen.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/screens/root/profile/edit_profile_screen.dart';
import 'package:tapkat/screens/root/profile/notification_list_screen.dart';
import 'package:tapkat/screens/root/profile/user_ratings_screen.dart';
import 'package:tapkat/screens/settings/settings_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/utilities/application.dart' as application;
import 'package:tapkat/widgets/custom_button.dart';

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
  final _productBloc = ProductBloc();
  late AuthBloc _authBloc;
  List<ProductModel> _list = [];
  bool editProfile = false;
  final _displayNameTextController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _phoneTextController = TextEditingController();
  PlaceDetails? _selectedLocation;
  final _locationTextController = TextEditingController();
  int currentPage = 0;

  final _refreshController = RefreshController();

  ProductModel? lastProduct;

  final _pagingController =
      PagingController<int, ProductModel>(firstPageKey: 0);

  @override
  void initState() {
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _profileBloc.add(InitializeProfileScreen());
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return ProgressHUD(
      barrierEnabled: false,
      indicatorColor: kBackgroundColor,
      backgroundColor: Colors.white,
      child: MultiBlocListener(
        listeners: [
          BlocListener(
            bloc: _profileBloc,
            listener: (context, state) {
              print('current state profile: $state');
              if (state is ProfileLoading) {
                ProgressHUD.of(context)!.show();
              } else {
                ProgressHUD.of(context)!.dismiss();
              }

              if (state is UpdateUserInfoSuccess) {
                setState(() {
                  editProfile = !editProfile;
                });

                _profileBloc.add(InitializeProfileScreen());
              }

              if (state is ProfileScreenInitialized) {
                setState(() {
                  _user = state.user;
                  _list = state.list;
                  _userModel = state.userModel;
                });

                _displayNameTextController.text =
                    _userModel!.display_name ?? 'Unknown';
                _emailTextController.text = _userModel!.email ?? 'Unknown';
                _phoneTextController.text =
                    _userModel!.phone_number ?? 'Unknown';
                _locationTextController.text = (_userModel!.address != null &&
                        _userModel!.city != null &&
                        _userModel!.country != null)
                    ? (_userModel!.address ?? '') +
                        ', ' +
                        (_userModel!.city ?? '') +
                        ', ' +
                        (_userModel!.country ?? '')
                    : '';

                _refreshController.refreshCompleted();
                _pagingController.refresh();

                if (state.list.isNotEmpty) {
                  lastProduct = state.list.last;
                  if (state.list.length == productCount) {
                    _pagingController.appendPage(state.list, currentPage + 1);
                  } else {
                    _pagingController.appendLastPage(state.list);
                  }
                } else {
                  _pagingController.appendLastPage([]);
                }
                _pagingController.addPageRequestListener((pageKey) {
                  if (lastProduct != null) {
                    _productBloc.add(
                      GetNextProducts(
                        listType: 'user',
                        lastProductId: lastProduct!.productid!,
                        startAfterVal: lastProduct!.price.toString(),
                        sortBy: 'distance',
                        userId: _user!.uid,
                        distance: 50000,
                      ),
                    );
                  }
                });
              }
            },
          ),
          BlocListener(
            bloc: _productBloc,
            listener: (context, state) {
              if (state is GetProductsSuccess) {
                if (state.list.isNotEmpty) {
                  lastProduct = state.list.last;
                  if (state.list.length == productCount) {
                    _pagingController.appendPage(state.list, currentPage + 1);
                  } else {
                    _pagingController.appendLastPage(state.list);
                  }
                } else {
                  _pagingController.appendLastPage([]);
                }
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
                  onTap: () {
                    if (_userModel != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SettingsScreen(user: _userModel!),
                        ),
                      );
                    }
                  },
                  child: Icon(
                    FontAwesomeIcons.cog,
                    color: Colors.white,
                  ),
                ),
                action: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationListScreen(),
                    ),
                  ),
                  child: Icon(
                    FontAwesomeIcons.bell,
                    color: Colors.white,
                  ),
                ),
              ),
              Visibility(
                visible: !application.currentUser!.emailVerified &&
                    !application.currentUserModel!.verifiedByPhone!,
                child: Container(
                  width: double.infinity,
                  color: Style.secondaryColor,
                  padding: EdgeInsets.all(5.0),
                  child: Center(
                    child: Text(
                      'Your email is not yet verified\nSome features will not be available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.textScaleFactor * 12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SmartRefresher(
                  controller: _refreshController,
                  onRefresh: () => _profileBloc.add(InitializeProfileScreen()),
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
                                  vertical: 5.0,
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
                                    GestureDetector(
                                      onTap: _userModel != null
                                          ? () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditProfileScreen(
                                                    user: _userModel!,
                                                  ),
                                                ),
                                              );

                                              _profileBloc.add(
                                                  InitializeProfileScreen());
                                            }
                                          : () {},
                                      child: Icon(
                                        FontAwesomeIcons.solidEdit,
                                        color: Colors.white,
                                        size: SizeConfig.textScaleFactor * 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        InkWell(
                                          onTap: _onPhotoTapped,
                                          child: _buildPhoto(),
                                        ),
                                        _userModel != null
                                            ? Container(
                                                margin: EdgeInsets.only(
                                                    bottom: 3.0),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10.0),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.people_alt,
                                                      size: SizeConfig
                                                              .textScaleFactor *
                                                          12,
                                                    ),
                                                    SizedBox(width: 5.0),
                                                    Text(
                                                      _userModel!.likes != null
                                                          ? _userModel!.likes
                                                              .toString()
                                                          : '0',
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: Style.fieldText.copyWith(
                                                          fontSize: SizeConfig
                                                                  .textScaleFactor *
                                                              12),
                                                    ),
                                                    VerticalDivider(),
                                                    InkWell(
                                                      onTap: () =>
                                                          Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              UserReviewListScreen(
                                                                  userId: _userModel!
                                                                      .userid!),
                                                        ),
                                                      ),
                                                      child: Container(
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.star,
                                                              size: SizeConfig
                                                                      .textScaleFactor *
                                                                  12,
                                                            ),
                                                            SizedBox(
                                                                width: 5.0),
                                                            Text(
                                                              _userModel!.rating !=
                                                                      null
                                                                  ? _userModel!
                                                                      .rating!
                                                                      .toStringAsFixed(
                                                                          1)
                                                                  : '0',
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                              style: Style
                                                                  .fieldText
                                                                  .copyWith(
                                                                      fontSize:
                                                                          SizeConfig.textScaleFactor *
                                                                              12),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Container(),
                                      ],
                                    ),
                                    Expanded(
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          vertical: 5.0,
                                        ),
                                        width: double.infinity,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            _buildInfoItem(
                                              label: 'Name',
                                              controller:
                                                  _displayNameTextController,
                                            ),
                                            _buildInfoItem(
                                              label: 'Email',
                                              controller: _emailTextController,
                                            ),
                                            _buildInfoItem(
                                              label: 'Phone',
                                              controller: _phoneTextController,
                                            ),
                                            _buildInfoItem(
                                              label: 'Location',
                                              controller:
                                                  _locationTextController,
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
                              ),
                              Visibility(
                                visible:
                                    !application.currentUser!.emailVerified &&
                                        !application
                                            .currentUserModel!.verifiedByPhone!,
                                child: CustomButton(
                                  label: 'Verify your account',
                                  onTap: () {
                                    DialogMessage.show(
                                      context,
                                      message:
                                          'Click on the verification link sent to your email address: ${application.currentUser!.email}',
                                      buttonText: 'Resend',
                                      firstButtonClicked: () =>
                                          _authBloc.add(ResendEmail()),
                                    );
                                    return;
                                  },
                                ),
                              ),
                              Visibility(
                                visible:
                                    application.currentUser!.emailVerified ||
                                        application
                                            .currentUserModel!.verifiedByPhone!,
                                child: Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  UserRatingsScreen(
                                                      user: _userModel!),
                                            ),
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            margin:
                                                EdgeInsets.only(bottom: 8.0),
                                            decoration: BoxDecoration(
                                              color: kBackgroundColor,
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 5.0,
                                              horizontal: 10.0,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Reviewed Products & Users',
                                                  style: Style.subtitle2
                                                      .copyWith(
                                                          color: Colors.white),
                                                ),
                                                Spacer(),
                                                Icon(
                                                  FontAwesomeIcons.chevronRight,
                                                  color: Colors.white,
                                                  size: 18.0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: kBackgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 5.0,
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
                                                  if (!application.currentUser!
                                                          .emailVerified &&
                                                      !application
                                                          .currentUserModel!
                                                          .verifiedByPhone!) {
                                                    DialogMessage.show(
                                                      context,
                                                      message:
                                                          'Click on the verification link sent to your email address: ${application.currentUser!.email}',
                                                      buttonText: 'Resend',
                                                      firstButtonClicked: () =>
                                                          _authBloc.add(
                                                              ResendEmail()),
                                                    );
                                                    return;
                                                  }
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
                                            child: _buildGridView(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _onUpdateUserInfo() {
    if (_userModel != null) {
      var updateData = UpdateUserModel(
        userid: _userModel!.userid,
        display_name: _displayNameTextController.text.trim(),
        email: _emailTextController.text.trim(),
        phone_number: _phoneTextController.text.trim(),
      );

      if (_selectedLocation != null) {
        updateData.city = _selectedLocation!.addressComponents[1] != null
            ? _selectedLocation!.addressComponents[1]!.longName
            : null;
        updateData.address = _selectedLocation!.addressComponents[0] != null
            ? _selectedLocation!.addressComponents[0]!.longName
            : null;
        updateData.country = _selectedLocation!.addressComponents.last != null
            ? _selectedLocation!.addressComponents.last!.longName
            : null;
        updateData.location = LocationModel(
          longitude: _selectedLocation!.geometry!.location.lng,
          latitude: _selectedLocation!.geometry!.location.lat,
        );
      }

      _profileBloc.add(UpdateUserInfo(updateData));
    }
  }

  Widget _buildGridView() {
    return PagedGridView<int, ProductModel>(
      pagingController: _pagingController,
      showNewPageProgressIndicatorAsGridChild: false,
      showNewPageErrorIndicatorAsGridChild: false,
      showNoMoreItemsIndicatorAsGridChild: false,
      padding: EdgeInsets.symmetric(vertical: 10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
      ),
      builderDelegate: PagedChildBuilderDelegate<ProductModel>(
        itemBuilder: (context, product, index) {
          return FittedBox(
            child: BarterListItem(
              hideDistance: true,
              showRating: false,
              product: product,
              hideLikeBtn: true,
              onTapped: () async {
                final changed = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(
                      ownItem: true,
                      productId: product.productid ?? '',
                    ),
                  ),
                );

                if (changed == true) {
                  _profileBloc.add(InitializeProfileScreen());
                }
              },
            ),
          );
        },
      ),
    );
  }

  Container _buildInfoItem({
    required String label,
    required TextEditingController controller,
    Widget? suffix,
    Function()? onTap,
    bool readOnly = false,
    bool center = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.0),
      padding: EdgeInsets.symmetric(
        horizontal: 20.0,
      ),
      child: Column(
        crossAxisAlignment:
            center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Style.fieldTitle.copyWith(color: kBackgroundColor),
          ),
          TextFormField(
            textAlign: center ? TextAlign.center : TextAlign.start,
            controller: controller,
            style: Style.fieldText,
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
        ],
      ),
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
        Visibility(
          visible: editProfile,
          child: Positioned(
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 25.0,
        ),
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: SizedBox(
                      height: SizeConfig.screenWidth * .23,
                      width: SizeConfig.screenWidth * .23,
                      child: _buildPhoto(),
                    ),
                  ),
                  SizedBox(height: 15),
                  _buildInfoItem(
                    center: true,
                    label: 'Name',
                    controller: TextEditingController(
                        text: _userModel!.display_name ?? '-'),
                  ),
                  _buildInfoItem(
                    center: true,
                    label: 'Email Address',
                    controller:
                        TextEditingController(text: _userModel!.email ?? '-'),
                  ),
                  _buildInfoItem(
                    center: true,
                    label: 'Phone',
                    controller: TextEditingController(
                        text: _userModel!.phone_number ?? '-'),
                  ),
                  _buildInfoItem(
                    center: true,
                    label: 'Address',
                    controller:
                        TextEditingController(text: _userModel!.address ?? '-'),
                  ),
                  _buildInfoItem(
                    center: true,
                    label: 'Postcode',
                    controller: TextEditingController(
                        text: _userModel!.postcode ?? '-'),
                  ),
                  _buildInfoItem(
                    center: true,
                    label: 'Country',
                    controller:
                        TextEditingController(text: _userModel!.country ?? '-'),
                  ),
                  Divider(
                    height: 10.0,
                    color: kBackgroundColor,
                  ),
                  _buildInfoItem(
                    center: true,
                    label: 'Facebook',
                    controller: TextEditingController(
                        text: _userModel!.fb_profile ?? '-'),
                  ),
                  _buildInfoItem(
                    center: true,
                    label: 'Instagram',
                    controller: TextEditingController(
                        text: _userModel!.ig_profile ?? '-'),
                  ),
                  _buildInfoItem(
                    center: true,
                    label: 'Youtube',
                    controller: TextEditingController(
                        text: _userModel!.yt_profile ?? '-'),
                  ),
                  _buildInfoItem(
                    center: true,
                    label: 'Twitter',
                    controller: TextEditingController(
                        text: _userModel!.tw_profile ?? '-'),
                  ),
                  _buildInfoItem(
                    center: true,
                    label: 'Tiktok',
                    controller: TextEditingController(
                        text: _userModel!.tt_profile ?? '-'),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10.0,
              right: 10.0,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

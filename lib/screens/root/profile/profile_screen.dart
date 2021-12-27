import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/screens/product/product_details_screen.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
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
  SelectedMedia? _selectedMedia;
  final _profileBloc = ProfileBloc();
  late AuthBloc _authBloc;
  List<ProductModel> _list = [];
  bool editProfile = false;

  @override
  void initState() {
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
                  });
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
                    onTap: () {},
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
                                    GestureDetector(
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
                                            controller: TextEditingController(
                                              text:
                                                  _user!.displayName!.isNotEmpty
                                                      ? _user!.displayName
                                                      : 'Unknown',
                                            ),
                                          ),
                                          _buildInfoItem(
                                            label: 'Email',
                                            controller: TextEditingController(
                                              text: _user!.email,
                                            ),
                                          ),
                                          _buildInfoItem(
                                            label: 'Phone number',
                                            controller: TextEditingController(
                                              text:
                                                  _user!.phoneNumber!.isNotEmpty
                                                      ? _user!.phoneNumber
                                                      : '123456789',
                                            ),
                                          ),
                                          _buildInfoItem(
                                            label: 'Location',
                                            controller: TextEditingController(
                                                text:
                                                    'Naga City, Camarines Sur, Philippines'),
                                            suffix: Icon(
                                              FontAwesomeIcons.mapMarked,
                                              color: kBackgroundColor,
                                              size: 12.0,
                                            ),
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
                                                            imageUrl:
                                                                product.imgUrl !=
                                                                        null
                                                                    ? product
                                                                        .imgUrl!
                                                                    : '',
                                                            onTapped: () =>
                                                                Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        ProductDetailsScreen(
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
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 5.0),
      padding: EdgeInsets.symmetric(
        horizontal: 20.0,
      ),
      child: Column(
        children: [
          TextFormField(
            controller: controller,
            style: Style.fieldText,
            textAlign: TextAlign.center,
            readOnly: !editProfile,
            enabled: editProfile,
            decoration: InputDecoration(
              isDense: true,
              isCollapsed: true,
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
                  ? AssetImage('assets/images/profile_placeholder.png')
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

  _onPhotoTapped() {
    //
  }
}

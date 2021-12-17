import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/upload_media.dart';
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

  @override
  void initState() {
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _authBloc.add(GetCurrentuser());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
          indicatorColor: kBackgroundColor,
          backgroundColor: Colors.white,
          child: MultiBlocListener(
            listeners: [
              BlocListener(
                bloc: _authBloc,
                listener: (context, state) {
                  if (state is AuthLoading) {
                    ProgressHUD.of(context)!.show();
                  } else {
                    ProgressHUD.of(context)!.dismiss();
                  }

                  if (state is GetCurrentUsersuccess) {
                    setState(() {
                      _user = state.user;
                    });
                  }
                },
              ),
              BlocListener(
                bloc: _profileBloc,
                listener: (context, state) {
                  if (state is ProfileLoading) {
                    ProgressHUD.of(context)!.show();
                  } else {
                    ProgressHUD.of(context)!.dismiss();
                  }

                  if (state is ProfileScreenInitialized) {
                    _user = state.user;
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: _user != null
                          ? SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildPhoto(),
                                  Container(
                                    width: double.infinity,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          _user!.displayName ?? '',
                                          style: Style.subtitle1.copyWith(
                                            color: kBackgroundColor,
                                          ),
                                        ),
                                        Text(
                                          _user!.email ?? '',
                                          style: Style.subtitle2.copyWith(
                                            color: kBackgroundColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                    ),
                  ),
                ],
              ),
            ),
          )),
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
          height: 130.0,
          width: 130.0,
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

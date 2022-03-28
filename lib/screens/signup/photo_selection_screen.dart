import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/root/profile/interests_selection_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/custom_button.dart';

class SignUpPhotoSelectionScreen extends StatefulWidget {
  const SignUpPhotoSelectionScreen({Key? key}) : super(key: key);

  @override
  _SignUpPhotoSelectionScreenState createState() =>
      _SignUpPhotoSelectionScreenState();
}

class _SignUpPhotoSelectionScreenState
    extends State<SignUpPhotoSelectionScreen> {
  late AuthBloc _authBloc;
  SelectedMedia? _selectedMedia;
  UserModel? _user;

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
        barrierEnabled: false,
        child: BlocListener(
          bloc: _authBloc,
          listener: (context, state) {
            if (state is AuthLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is AuthSignedIn) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }

            if (state is GetCurrentUsersuccess) {
              setState(() {
                _user = state.userModel;
              });
            }

            if (state is SaveUserPhotoSuccess) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InterestSelectionScreen(
                    user: _user!,
                    signingUp: true,
                  ),
                ),
              );
            }

            // if (state is ShowSignUpSocialMedia) {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => SignUpSocialMediaAccounts(),
            //     ),
            //   );
            // }
          },
          child: Stack(
            children: [
              Container(
                width: SizeConfig.screenWidth,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(
                      'assets/images/splashscreen_bg.png',
                    ),
                  ),
                ),
                height: SizeConfig.screenHeight * .4,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: FractionalOffset.topCenter,
                    end: FractionalOffset.bottomCenter,
                    colors: [
                      Colors.transparent,
                      kBackgroundColor,
                      kBackgroundColor,
                      kBackgroundColor,
                    ],
                    stops: [0.1, 0.4, 1, 1],
                  ),
                ),
                height: SizeConfig.screenHeight,
                width: SizeConfig.screenWidth,
              ),
              Positioned(
                top: SizeConfig.screenHeight * .45,
                child: Container(
                  height: SizeConfig.screenHeight * .6,
                  padding: EdgeInsets.symmetric(
                    horizontal: 50.0,
                  ),
                  width: SizeConfig.screenWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          'Thanks for Joining!',
                          style: Style.subtitle2.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          'You may now upload a profile photo',
                          textAlign: TextAlign.center,
                          style: Style.bodyText1.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(100.0),
                                image: DecorationImage(
                                  image: _selectedMedia == null
                                      ? AssetImage(
                                              'assets/images/profile_placeholder.png')
                                          as ImageProvider<Object>
                                      : FileImage(
                                          File(_selectedMedia!.rawPath!),
                                        ),
                                  scale: 1.0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              height: 180.0,
                              width: 180.0,
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
                                  height: 50.0,
                                  width: 50.0,
                                  child: Icon(
                                    Icons.photo_camera,
                                    color: Colors.white,
                                    size: 30.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32.0),
                        CustomButton(
                          label: 'Save & Continue',
                          onTap: () {
                            print('save/continue');
                            if (_selectedMedia != null)
                              BlocProvider.of<AuthBloc>(context)
                                  .add(SaveUserPhoto(context, _selectedMedia!));
                          },
                        ),
                        CustomButton(
                          label: 'Skip',
                          onTap: () {
                            print('skip');
                            // BlocProvider.of<AuthBloc>(context)
                            //     .add(SkipSignUpPhoto());

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InterestSelectionScreen(
                                  user: _user!,
                                  signingUp: true,
                                ),
                              ),
                            );
                          },
                          bgColor: Color(0xFFBB3F03),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _onPhotoTapped() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
    );

    if (selectedMedia != null &&
        validateFileFormat(selectedMedia.storagePath, context)) {
      setState(() {
        _selectedMedia = selectedMedia;
      });
    }
  }
}

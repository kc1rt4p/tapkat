import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/screens/root/profile/interests_selection_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';
import 'package:tapkat/utilities/application.dart' as application;

class UserSocialMediaAccountsScreen extends StatefulWidget {
  final UserModel user;
  final String op;
  const UserSocialMediaAccountsScreen({
    Key? key,
    required this.user,
    required this.op,
  }) : super(key: key);

  @override
  _UserSocialMediaAccountsScreenState createState() =>
      _UserSocialMediaAccountsScreenState();
}

class _UserSocialMediaAccountsScreenState
    extends State<UserSocialMediaAccountsScreen> {
  late AuthBloc _authBloc;
  final _profileBloc = ProfileBloc();
  final fbTextEditingController = TextEditingController();
  final igTextEditingController = TextEditingController();
  final ytTextEditingController = TextEditingController();
  final ttTextEditingController = TextEditingController();
  final twTextEditingController = TextEditingController();
  String fbEmail = '';
  String googleEmail = '';

  @override
  void initState() {
    application.currentScreen = 'Social Media Screen';
    _authBloc = BlocProvider.of<AuthBloc>(context);
    if (widget.op == 'edit') {
      fbEmail = widget.user.fb_profile ?? '';
      googleEmail = widget.user.yt_profile ?? '';
      igTextEditingController.text = widget.user.ig_profile ?? '';
      // ytTextEditingController.text = widget.user.yt_profile ?? '';
      ttTextEditingController.text = widget.user.tt_profile ?? '';
      twTextEditingController.text = widget.user.tw_profile ?? '';
    }
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

                if (state is AuthSignedIn) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
            BlocListener(
              bloc: _profileBloc,
              listener: (context, state) {
                print('profile current state:: $state');
                if (state is ProfileLoading) {
                  ProgressHUD.of(context)!.show();
                } else {
                  ProgressHUD.of(context)!.dismiss();
                }
                if (state is LinkAccToSocialMediaSuccess) {
                  final platform = state.platform;
                  setState(() {
                    if (platform == 'facebook')
                      fbEmail = state.email;
                    else if (platform == 'google') googleEmail = state.email;
                  });
                }

                if (state is ProfileError) {
                  print('error on profile:: ${state.message}');
                }
              },
            ),
          ],
          child: widget.op == 'edit'
              ? Container(
                  child: Column(
                    children: [
                      CustomAppBar(
                        label: 'Edit Profile',
                      ),
                      Expanded(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 500.0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 16.0),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                SizeConfig.screenWidth > 500
                                    ? SizedBox(
                                        height: SizeConfig.screenHeight * 0.1)
                                    : SizedBox(),
                                Container(
                                  margin: EdgeInsets.only(bottom: 16.0),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.black),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Facebook'),
                                      fbEmail.isNotEmpty
                                          ? RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  color: kBackgroundColor,
                                                  fontFamily: 'Poppins',
                                                ),
                                                children: [
                                                  TextSpan(text: 'Linked to '),
                                                  TextSpan(
                                                    text: fbEmail,
                                                    style: TextStyle(
                                                      color: kBackgroundColor,
                                                      fontFamily: 'Poppins',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : TextButton(
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size(50, 30),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              onPressed: () => _profileBloc.add(
                                                  LinkAccToSocialMedia(
                                                      'facebook')),
                                              child: Text(
                                                'Link your Facebook account',
                                                style: TextStyle(
                                                  decoration:
                                                      TextDecoration.underline,
                                                  color: kBackgroundColor,
                                                ),
                                              )),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(bottom: 16.0),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.black),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Google'),
                                      googleEmail.isNotEmpty
                                          ? Row(
                                              children: [
                                                RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(
                                                      color: kBackgroundColor,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                          text: 'Linked to '),
                                                      TextSpan(
                                                        text: googleEmail,
                                                        style: TextStyle(
                                                          color:
                                                              kBackgroundColor,
                                                          fontFamily: 'Poppins',
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Spacer(),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      googleEmail = '';
                                                    });
                                                  },
                                                  child: Icon(Icons.delete),
                                                ),
                                              ],
                                            )
                                          : TextButton(
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size(50, 30),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              onPressed: () => _profileBloc.add(
                                                  LinkAccToSocialMedia(
                                                      'google')),
                                              child: Text(
                                                'Link your Google account',
                                                style: TextStyle(
                                                  decoration:
                                                      TextDecoration.underline,
                                                  color: kBackgroundColor,
                                                ),
                                              )),
                                    ],
                                  ),
                                ),
                                _buildUnderlineInput(
                                  label: 'Instagram',
                                  controller: igTextEditingController,
                                ),
                                // _buildUnderlineInput(
                                //   label: 'Youtube',
                                //   controller: ytTextEditingController,
                                // ),
                                _buildUnderlineInput(
                                  label: 'Tiktok',
                                  controller: ttTextEditingController,
                                ),
                                _buildUnderlineInput(
                                  label: 'Twitter',
                                  controller: twTextEditingController,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(maxWidth: 500.0),
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            CustomButton(
                              bgColor: kBackgroundColor,
                              label: 'Next',
                              onTap: _onSave,
                            ),
                            // CustomButton(
                            //   label: 'Skip',
                            //   onTap: () => Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) => InterestSelectionScreen(
                            //         user: widget.user,
                            //       ),
                            //     ),
                            //   ),
                            //   bgColor: Color(0xFFBB3F03),
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
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
                      height: SizeConfig.screenHeight * .3,
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
                          stops: [0.1, 0.3, 1, 1],
                        ),
                      ),
                      height: SizeConfig.screenHeight,
                      width: SizeConfig.screenWidth,
                    ),
                    Positioned(
                      top: SizeConfig.screenHeight * .33,
                      child: Container(
                        height: SizeConfig.screenHeight * .7,
                        padding: EdgeInsets.symmetric(
                          horizontal: 50.0,
                        ),
                        width: SizeConfig.screenWidth,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Text(
                                'You can also share your social media accounts',
                                textAlign: TextAlign.center,
                                style: Style.bodyText1.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 16.0),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.black),
                                  ),
                                ),
                                child: fbEmail.isNotEmpty
                                    ? RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(text: 'Linked to '),
                                            TextSpan(text: fbEmail),
                                          ],
                                        ),
                                      )
                                    : TextButton(
                                        onPressed: () {}, child: Text('')),
                              ),
                              CustomTextFormField(
                                label: 'Facebook',
                                hintText: 'Enter your Facebook Link',
                                controller: fbTextEditingController,
                              ),
                              CustomTextFormField(
                                label: 'Google',
                                hintText: 'Enter your Youtube Link',
                                controller: ytTextEditingController,
                              ),
                              CustomTextFormField(
                                label: 'Instagram',
                                hintText: 'Enter your Instagram Link',
                                controller: igTextEditingController,
                              ),
                              CustomTextFormField(
                                label: 'Tiktok',
                                hintText: 'Enter your Tiktok Link',
                                controller: ttTextEditingController,
                              ),
                              CustomTextFormField(
                                label: 'Twitter',
                                hintText: 'Enter your Twitter link',
                                controller: twTextEditingController,
                              ),
                              CustomButton(
                                label: 'Save & Continue',
                                onTap: _onSave,
                              ),
                              CustomButton(
                                label: 'Skip',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          InterestSelectionScreen(
                                        user: widget.user,
                                        signingUp: widget.op != 'edit',
                                      ),
                                    )),
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

  _onSave() {
    final user = widget.user;

    user.fb_profile = fbEmail.isNotEmpty ? fbEmail : null;
    user.ig_profile = igTextEditingController.text.isNotEmpty
        ? igTextEditingController.text.trim()
        : null;
    user.yt_profile = googleEmail.isNotEmpty ? googleEmail : null;
    user.tt_profile = ttTextEditingController.text.isNotEmpty
        ? ttTextEditingController.text.trim()
        : null;

    user.tw_profile = twTextEditingController.text.isNotEmpty
        ? twTextEditingController.text.trim()
        : null;

    print(user.toJson());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterestSelectionScreen(
          user: user,
          signingUp: widget.op != 'edit',
        ),
      ),
    );
  }

  Container _buildUnderlineInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              suffixIconConstraints: BoxConstraints(
                maxHeight: SizeConfig.textScaleFactor * 17,
                maxWidth: SizeConfig.textScaleFactor * 17,
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 5.0, horizontal: 3.0),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: kBackgroundColor,
                ),
              ),
              isDense: true,
              errorBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: kDangerColor,
                ),
              ),
              suffixIcon: Icon(
                Icons.paste,
                size: SizeConfig.textScaleFactor * 17,
                color: kBackgroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

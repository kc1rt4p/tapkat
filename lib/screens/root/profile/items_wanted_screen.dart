import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/request/update_user.dart';
import 'package:tapkat/screens/login/email_verification_screen.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/utilities/application.dart' as application;

class ItemsWantedScreen extends StatefulWidget {
  final UpdateUserModel user;
  final bool signingUp;
  const ItemsWantedScreen({
    Key? key,
    required this.user,
    this.signingUp = false,
  }) : super(key: key);

  @override
  State<ItemsWantedScreen> createState() => _ItemsWantedScreenState();
}

class _ItemsWantedScreenState extends State<ItemsWantedScreen> {
  List<String> _list = [];

  final inputTextController = TextEditingController();
  final focusNode = FocusNode();

  final _profileBloc = ProfileBloc();
  late AuthBloc _authBloc;
  bool _textIsEmpty = false;

  @override
  void initState() {
    application.currentScreen = 'Items Wanted Screen';
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _list = widget.user.items_wanted ?? [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return ProgressHUD(
      child: Scaffold(
        body: Column(
          children: [
            CustomAppBar(
              label: 'Sign Up',
            ),
            Expanded(
              child: BlocListener(
                bloc: _profileBloc,
                listener: (context, state) {
                  if (state is ProfileLoading) {
                    ProgressHUD.of(context)!.show();
                  } else {
                    ProgressHUD.of(context)!.dismiss();
                  }

                  if (state is UpdateUserInfoSuccess) {
                    if (!widget.signingUp) {
                      var count = 0;
                      Navigator.popUntil(context, (route) {
                        return count++ == 4;
                      });
                      //
                    } else {
                      if (!application.currentUser!.emailVerified &&
                          application.currentUserModel!.signin_method ==
                              'EMAIL') {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EmailVerificationScreen(
                                      signingUp: true,
                                    )),
                            (route) => route.isFirst);
                      } else {
                        _authBloc.add(SkipSignUpPhoto());
                      }
                    }
                  }
                },
                child: Container(
                  constraints: BoxConstraints(maxWidth: 500.0),
                  width: SizeConfig.screenWidth,
                  height: SizeConfig.screenHeight,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: SizeConfig.screenHeight * 0.1),
                        Text('What products or services are you looking for?',
                            style: Style.subtitle2),
                        SizedBox(height: 25.0),
                        TextFormField(
                          focusNode: focusNode,
                          controller: inputTextController,
                          onChanged: (val) {
                            setState(() {
                              _textIsEmpty = val.isEmpty;
                            });
                          },
                          decoration: InputDecoration(
                            border: UnderlineInputBorder(),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: kBackgroundColor),
                            ),
                            suffixIcon: GestureDetector(
                              onTap: !_textIsEmpty
                                  ? () {
                                      setState(() {
                                        _list.add(
                                            inputTextController.text.trim());
                                      });
                                      inputTextController.clear();
                                      focusNode.requestFocus();
                                    }
                                  : null,
                              child: Icon(
                                FontAwesomeIcons.plus,
                                color: _textIsEmpty
                                    ? Colors.grey
                                    : kBackgroundColor,
                                size: 15.0,
                              ),
                            ),
                          ),
                          onFieldSubmitted: (val) {
                            if (val.isNotEmpty) {
                              setState(() {
                                _list.add(val);
                              });
                              inputTextController.clear();
                              focusNode.requestFocus();
                            }
                          },
                        ),
                        SizedBox(height: 25.0),
                        Visibility(
                          visible: _list.isNotEmpty,
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.0),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  runSpacing: 8.0,
                                  spacing: 8.0,
                                  children: [
                                    ..._list
                                        .map(
                                          (val) => InkWell(
                                            onTap: () {
                                              setState(() {
                                                _list.remove(val);
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10.0,
                                                vertical: 5.0,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    val,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: SizeConfig
                                                              .textScaleFactor *
                                                          15,
                                                    ),
                                                  ),
                                                  SizedBox(width: 5.0),
                                                  Icon(
                                                    Icons.close,
                                                    size: SizeConfig
                                                            .textScaleFactor *
                                                        13,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(15.0),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _list.clear();
                                    });
                                  },
                                  child: Padding(
                                    padding:
                                        EdgeInsets.fromLTRB(0.0, 5.0, 5.0, 0.0),
                                    child: Text(
                                      'Clear items',
                                      style: TextStyle(
                                        color: kBackgroundColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(maxWidth: 500.0),
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 3.0),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      bgColor: kBackgroundColor,
                      label: 'Submit',
                      onTap: () => _onSaveTapped(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _onSaveTapped() {
    var user = widget.user;
    user.items_wanted = _list;

    _profileBloc.add(UpdateUserInfo(user));
  }
}

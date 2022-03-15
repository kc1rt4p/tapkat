import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/models/request/update_user.dart';
import 'package:tapkat/models/user.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/root/profile/bloc/profile_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';

class InterestSelectionScreen extends StatefulWidget {
  final UserModel user;
  final bool signingUp;
  const InterestSelectionScreen({
    Key? key,
    required this.user,
    this.signingUp = false,
  }) : super(key: key);

  @override
  State<InterestSelectionScreen> createState() =>
      _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  late UserModel _user;
  late AuthBloc _authBloc;
  final _profileBloc = ProfileBloc();
  final _productBloc = ProductBloc();
  List<ProductCategoryModel> _categories = [];
  List<ProductCategoryModel> _selectedCategories = [];

  @override
  void initState() {
    _user = widget.user;
    _productBloc.add(InitializeAddUpdateProduct());
    if (widget.signingUp) _authBloc = BlocProvider.of<AuthBloc>(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
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

                if (state is UpdateUserInfoSuccess) {
                  if (!widget.signingUp) {
                    var count = 0;
                    Navigator.popUntil(context, (route) {
                      return count++ == 2;
                    });
                  } else {
                    _authBloc.add(SkipSignUpPhoto());
                  }
                }
              },
            ),
            BlocListener(
              bloc: _productBloc,
              listener: (context, state) {
                if (state is ProductLoading) {
                  ProgressHUD.of(context)!.show();
                } else {
                  ProgressHUD.of(context)!.dismiss();
                }

                if (state is InitializeAddUpdateProductSuccess) {
                  setState(() {
                    _categories = state.categories
                        .where((cat) =>
                            cat.type == 'PT1' &&
                            cat.name!.toLowerCase() != 'others')
                        .toList();
                  });

                  if (_user.interests != null && _user.interests!.isNotEmpty) {
                    _categories.forEach((cat) {
                      if (_user.interests!.contains(cat.code)) {
                        _selectedCategories.add(cat);
                      }
                    });
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
                  label: widget.signingUp ? 'Sign Up' : 'Edit Profile',
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Select your interests, this will help us show you offers from other users that you might be interested',
                          textAlign: TextAlign.center,
                        ),
                        _categories.isNotEmpty
                            ? Expanded(
                                child: GridView.count(
                                  padding: EdgeInsets.only(top: 20.0),
                                  shrinkWrap: true,
                                  childAspectRatio: 3 / 2,
                                  mainAxisSpacing: 5.0,
                                  crossAxisCount: 3,
                                  children: _categories
                                      .where((cat) => cat.type == 'PT1')
                                      .map((cat) => Center(
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  // _selectedCategory = cat;
                                                  if (_selectedCategories
                                                      .contains(cat))
                                                    _selectedCategories
                                                        .remove(cat);
                                                  else
                                                    _selectedCategories
                                                        .add(cat);
                                                });
                                              },
                                              child: Container(
                                                height:
                                                    SizeConfig.screenHeight *
                                                        .08,
                                                width: SizeConfig.screenWidth *
                                                    .25,
                                                padding: EdgeInsets.all(10.0),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                  color: _selectedCategories
                                                          .contains(cat)
                                                      ? kBackgroundColor
                                                      : Color(0xFFEBFBFF),
                                                  border: _selectedCategories
                                                          .contains(cat)
                                                      ? null
                                                      : Border.all(
                                                          color:
                                                              kBackgroundColor),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    cat.name ?? '',
                                                    style: TextStyle(
                                                      color: _selectedCategories
                                                              .contains(cat)
                                                          ? Colors.white
                                                          : kBackgroundColor,
                                                      fontSize: SizeConfig
                                                              .textScaleFactor *
                                                          13,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                  ),
                  child: CustomButton(
                    removeMargin: true,
                    label: 'Save',
                    onTap: _onSaveTapped,
                  ),
                ),
                Visibility(
                  visible: widget.signingUp,
                  child: Column(
                    children: [
                      SizedBox(height: 10.0),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.0,
                        ),
                        child: CustomButton(
                          bgColor: Color(0xFFBB3F03),
                          label: 'Skip',
                          onTap: () => _authBloc.add(SkipSignUpPhoto()),
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
    );
  }

  _onSaveTapped() {
    var user = UpdateUserModel(
      userid: _user.userid,
      display_name: _user.display_name,
      phone_number: _user.phone_number,
      interests: _selectedCategories.map((scat) => scat.code!).toList(),
    );

    _profileBloc.add(UpdateUserInfo(user));
  }
}

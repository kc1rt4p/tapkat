import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart' as geoCoding;
import 'package:geolocator/geolocator.dart' as geoLocator;
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:tapkat/bloc/auth_bloc/auth_bloc.dart';
import 'package:tapkat/models/address.dart';
import 'package:tapkat/models/localization.dart';
import 'package:tapkat/models/location.dart';
import 'package:tapkat/models/media_primary_model.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/product_category.dart';
import 'package:tapkat/models/product_type.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/screens/product/product_select_categories_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/constants.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:tapkat/utilities/application.dart' as application;

class ProductAddEditScreen extends StatefulWidget {
  final ProductModel? product;
  const ProductAddEditScreen({
    Key? key,
    this.product,
  }) : super(key: key);

  @override
  _ProductAddEditScreenState createState() => _ProductAddEditScreenState();
}

class _ProductAddEditScreenState extends State<ProductAddEditScreen> {
  final _productBloc = ProductBloc();
  late AuthBloc _authBloc;

  List<SelectedMedia> _selectedMedia = [];

  final _nameTextController = TextEditingController();
  final _priceTextController = TextEditingController();
  final _offerTypeTextController = TextEditingController();
  final _descTextController = TextEditingController();
  final _locationTextController = TextEditingController();
  final _quantityTextController = TextEditingController();

  final inputTextController = TextEditingController();
  final focusNode = FocusNode();

  List<String> _tradeForlist = [];

  bool showImageError = false;
  bool showOfferTypeError = false;
  String? _selectedOfferType;
  PlaceDetails? _selectedLocation;

  List<LocalizationModel> _locList = [];
  List<AddressModel> _meetUpList = [];
  LocalizationModel? _selectedLocalization;
  String _selectedStatus = 'available';

  final _formKey = GlobalKey<FormState>();

  User? _user;
  int _currentCarouselIndex = 0;
  final _carouselController = CarouselController();
  geoCoding.Placemark? _currentUserLoc;
  geoLocator.Position? _currentUserPosition;

  List<ProductTypeModel> _productTypes = [];
  List<ProductCategoryModel> _productCategories = [];
  bool isFree = false;
  bool trackStock = true;
  List<MediaPrimaryModel> _media = [];

  final _scrollController = AutoScrollController();
  ProductCategoryModel? _selectedCategory;
  bool _textIsEmpty = true;
  bool showCategoryError = false;
  // bool showTradeForError = false;
  bool showMeetUpError = false;

  @override
  void initState() {
    application.currentScreen = 'Product Add Screen';
    _authBloc = BlocProvider.of<AuthBloc>(context);
    _authBloc.add(GetCurrentuser());
    _loadUserLocation();
    super.initState();

    // on edit
    if (widget.product != null) {
      final _product = widget.product!;
      _media = _product.media ?? [];
      _nameTextController.text = _product.productname ?? '';
      _priceTextController.text =
          _product.price != null ? _product.price.toString() : '0.00';
      _offerTypeTextController.text = _product.type ?? '';
      _descTextController.text = _product.productdesc ?? '';
      // _locationTextController.text =
      //     '${_product.address!.address ?? ''}, ${_product.address!.city ?? ''}, ${_product.address!.country ?? ''}';
      isFree = _product.free ?? false;
      _selectedStatus = _product.status != null
          ? _product.status!.toLowerCase()
          : 'available';
      trackStock = _product.track_stock;
      _quantityTextController.text = _product.stock_count.toString();

      _tradeForlist = widget.product!.tradeFor ?? [];
      _meetUpList = List.from(widget.product!.meet_location ?? []);
    } else {
      if (application.currentUserModel!.city != null &&
          application.currentUserModel!.country != null &&
          application.currentUserModel!.address != null &&
          application.currentUserModel!.location != null) {
        _meetUpList.add(AddressModel(
          city: application.currentUserModel!.city,
          country: application.currentUserModel!.country,
          address: application.currentUserModel!.address,
          location: application.currentUserModel!.location,
        ));
      }
      _quantityTextController.text = '1';
    }
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

                  _productBloc.add(InitializeAddUpdateProduct());
                }
              },
            ),
            BlocListener(
              bloc: _productBloc,
              listener: (context, state) async {
                if (state is ProductLoading) {
                  ProgressHUD.of(context)!.show();
                } else {
                  ProgressHUD.of(context)!.dismiss();
                }

                if (state is SaveProductSuccess) {
                  await DialogMessage.show(
                    context,
                    message: 'An offer has been added',
                    firstButtonClicked: () => DialogMessage.dismiss(),
                  );

                  Navigator.pop(context);
                }

                if (state is EditProductSuccess) {
                  await DialogMessage.show(context,
                      message: 'The product has been updated.');
                  Navigator.pop(context);
                }

                if (state is InitializeAddUpdateProductSuccess) {
                  setState(() {
                    _productCategories = state.categories;
                    _productTypes = state.types;
                    _selectedOfferType = _productTypes[0].code;
                    _locList = state.locList;

                    if (widget.product != null) {
                      if (widget.product!.category != null) {
                        _selectedCategory = _productCategories.firstWhere(
                            (cat) => cat.code == widget.product!.category);
                      }
                    }

                    if (application.currentUserModel!.currency != null &&
                        application.currentUserModel!.currency!
                            .isNotEmpty) if (_locList.any((loc) =>
                        loc.currency == application.currentUserModel!.currency))
                      _selectedLocalization = _locList.firstWhere((loc) =>
                          loc.currency ==
                          application.currentUserModel!.currency);
                    else if (_locList.any((loc) =>
                        loc.country_code == application.currentCountry))
                      _selectedLocalization = _locList.firstWhere((loc) =>
                          loc.country_code == application.currentCountry);
                  });
                }
                if (state is AddProductImageSuccess) {
                  ProgressHUD.of(context)!.show();
                  await Future.delayed(Duration(milliseconds: 2000), () {
                    setState(() {
                      if (state.result.media != null) {
                        // final newMedia = state.result.media!
                        //     .where((m) => !_media
                        //         .any((n) => n.url != m.url || n.url_t != m.url_t))
                        //     .toList();
                        // _media.addAll(newMedia);
                        _media = state.result.media!;
                      }
                    });
                  });
                  ProgressHUD.of(context)!.dismiss();
                  await DialogMessage.show(context,
                      message: 'An image has been uploaded for this product.');
                  setState(() {
                    _currentCarouselIndex += 1;
                    _carouselController.nextPage();
                  });
                }
                if (state is DeleteImagesSuccess) {
                  await DialogMessage.show(context,
                      message: 'An image has been deleted.');

                  await Future.delayed(Duration(milliseconds: 500), () {
                    setState(() {
                      if (_media.length > 1) {
                        _media.removeAt(_currentCarouselIndex);
                      } else {
                        _media.clear();
                      }
                      if (_media.isNotEmpty && _currentCarouselIndex > 0) {
                        _currentCarouselIndex = _currentCarouselIndex - 1;
                      }
                    });
                  });
                }

                if (state is ProductError) {
                  print('====ERROR PRODUCT BLOC: ${state.message}');
                }
              },
            ),
          ],
          child: Container(
            // color: Color(0xFFEBFBFF),
            child: Column(
              children: [
                CustomAppBar(
                  label: widget.product != null
                      ? 'Edit Product'
                      : 'Add to Your Store',
                  onBackTapped: () => Navigator.pop(context, false),
                ),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 500.0),
                    width: double.infinity,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          AutoScrollTag(
                              key: ValueKey(0),
                              index: 0,
                              controller: _scrollController,
                              child: _buildDetailsForm()),
                          AutoScrollTag(
                            key: ValueKey(1),
                            index: 1,
                            controller: _scrollController,
                            child: _buildCategoryForm(),
                          ),
                          AutoScrollTag(
                            key: ValueKey(2),
                            index: 2,
                            controller: _scrollController,
                            child: _buildTradeForForm(),
                          ),
                          AutoScrollTag(
                            key: ValueKey(3),
                            index: 3,
                            controller: _scrollController,
                            child: _buildMeetUpForm(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Cancel',
                          bgColor: Colors.red.shade400,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: CustomButton(
                          label: 'Submit',
                          onTap: () => _onSubmitTapped(),
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

  Container _buildTradeForForm() {
    return Container(
      color: Color(0xFFEBFBFF),
      padding: EdgeInsets.symmetric(
        horizontal: 30.0,
        vertical: 10.0,
      ),
      child: Column(
        children: [
          Text('What do you want to get in return for this item?',
              style: Style.subtitle2),
          // Visibility(
          //   visible: showTradeForError,
          //   child: Text(
          //     'Required',
          //     style: TextStyle(
          //       fontSize: 12.0,
          //       color: Colors.red.shade400,
          //       fontStyle: FontStyle.italic,
          //     ),
          //   ),
          // ),
          SizedBox(height: 16.0),
          TextFormField(
            focusNode: focusNode,
            controller: inputTextController,
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: kBackgroundColor),
              ),
              suffixIcon: GestureDetector(
                onTap: !_textIsEmpty
                    ? () {
                        setState(() {
                          _tradeForlist.add(inputTextController.text.trim());
                        });
                        inputTextController.clear();
                        focusNode.requestFocus();
                      }
                    : null,
                child: Icon(
                  FontAwesomeIcons.plus,
                  color: _textIsEmpty ? Colors.grey : kBackgroundColor,
                  size: 15.0,
                ),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _textIsEmpty = val.isEmpty;
              });
            },
            onFieldSubmitted: (val) {
              if (val.isNotEmpty) {
                setState(() {
                  _tradeForlist.add(val);
                });
                inputTextController.clear();
                focusNode.requestFocus();
              }
            },
          ),
          SizedBox(height: 25.0),
          Visibility(
            visible: _tradeForlist.isNotEmpty,
            child: Container(
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
                  ..._tradeForlist
                      .map(
                        (val) => InkWell(
                          onTap: () {
                            setState(() {
                              _tradeForlist.remove(val);
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
                                Icon(
                                  Icons.close,
                                  size: SizeConfig.textScaleFactor * 13,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5.0),
                                Text(
                                  val,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: SizeConfig.textScaleFactor * 15,
                                  ),
                                ),
                              ],
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),
          Visibility(
            visible: _tradeForlist.isNotEmpty,
            child: Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _tradeForlist.clear();
                  });
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 5.0, 5.0, 0.0),
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
          ),
        ],
      ),
    );
  }

  Container _buildCategoryForm() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 30.0,
        vertical: 10.0,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Text('Select category of your product'),
          Visibility(
            visible: showCategoryError,
            child: Text(
              'Required',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.red.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          _productCategories.isNotEmpty
              ? GridView.count(
                  padding: EdgeInsets.only(top: 20.0),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  childAspectRatio: 3 / 2,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  crossAxisCount: 3,
                  children: _productCategories
                      .where((cat) => cat.type == _selectedOfferType)
                      .map((cat) => Center(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = cat;
                                  // if (_selectedCategories
                                  //     .contains(cat))
                                  //   _selectedCategories
                                  //       .remove(cat);
                                  // else
                                  //   _selectedCategories
                                  //       .add(cat);
                                });
                              },
                              child: Container(
                                height: SizeConfig.screenHeight * .08,
                                width: SizeConfig.screenWidth * .25,
                                padding: EdgeInsets.all(3.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: _selectedCategory == cat
                                      ? kBackgroundColor
                                      : Color(0xFFEBFBFF),
                                  border: _selectedCategory == cat
                                      ? null
                                      : Border.all(color: kBackgroundColor),
                                ),
                                child: Center(
                                  child: Text(
                                    cat.name ?? '',
                                    style: TextStyle(
                                      color: _selectedCategory == cat
                                          ? Colors.white
                                          : kBackgroundColor,
                                      fontSize: SizeConfig.screenWidth > 500
                                          ? SizeConfig.textScaleFactor * 16
                                          : SizeConfig.textScaleFactor * 11,
                                      height: 1.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                )
              : Container(),
          SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Container _buildMeetUpForm() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 30.0,
        vertical: 10.0,
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You may add up to 3 meet up locations', style: Style.subtitle2),
          Visibility(
            visible: showMeetUpError,
            child: Text(
              'Required',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.red.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(height: 10.0),
          CustomTextFormField(
            label: 'Location',
            hintText: 'Tap to search location',
            controller: _locationTextController,
            isReadOnly: true,
            color: kBackgroundColor,
            suffixIcon: Icon(
              Icons.location_on,
              color: Colors.white,
            ),
            onTap: () => _onSelectLocation(),
          ),
          Container(
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    enabled: _selectedLocation != null,
                    removeMargin: true,
                    bgColor: kBackgroundColor,
                    label: 'Add location',
                    onTap: _onAddLocation,
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          _meetUpList.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    children: _meetUpList
                        .where((item) =>
                            item.city != null &&
                            item.country != null &&
                            item.address != null &&
                            item.location != null)
                        .map(
                          (address) => Container(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${address.address ?? ''} ${address.city ?? ''}, ${address.country ?? ''}'),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                        onTap: () => setState(
                                            () => _meetUpList.remove(address)),
                                        child: Icon(Icons.close, size: 18.0)),
                                  ],
                                ),
                                Divider(),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
              : Center(
                  child: Text('No locations added'),
                ),
        ],
      ),
    );
  }

  Container _buildDetailsForm() {
    return Container(
      color: Color(0xFFEBFBFF),
      padding: EdgeInsets.symmetric(
        horizontal: 30.0,
        vertical: 10.0,
      ),
      child: Column(
        children: [
          Visibility(
            visible: widget.product == null,
            child: Text(
              'Add a product, event or service you want to offer',
              style: Style.bodyText2,
            ),
          ),
          SizedBox(height: 10.0),
          widget.product != null ? _buildPhotoForEdit() : _buildPhotoForAdd(),
          Visibility(
            visible: showImageError,
            child: Text(
              'Please select image(s) of your offer',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.red.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(height: 16.0),
          CustomTextFormField(
            label: 'Name',
            hintText: 'Enter your offer\'s name',
            controller: _nameTextController,
            color: kBackgroundColor,
            validator: (val) => val != null && val.isEmpty ? 'Required' : null,
          ),
          Container(
            margin: EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text('FREE',
                        style: TextStyle(
                          fontSize: SizeConfig.textScaleFactor * 13,
                          color: kBackgroundColor,
                          fontWeight: FontWeight.w600,
                        )),
                    SizedBox(height: 5.0),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isFree = !isFree;
                        });

                        _priceTextController.text = isFree ? '0' : '';
                      },
                      child: Icon(
                        isFree
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: kBackgroundColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10.0),
                Expanded(
                  child: CustomTextFormField(
                    label: 'Price',
                    hintText: 'Enter the price you want',
                    controller: _priceTextController,
                    color: kBackgroundColor,
                    maxLength: 14,
                    validator: (val) {
                      if (val != null && val.isEmpty)
                        return 'Required';
                      else if (val != null && val.isNotEmpty) {
                        final amount = double.parse(val.replaceAll(',', ''));
                        if (amount > 100000000) {
                          return 'Max amount is 100,000,000.00';
                        }
                      }

                      return null;
                    },
                    keyboardType: TextInputType.number,
                    isReadOnly: isFree,
                    removeMargin: true,
                    prefix: InkWell(
                      onTap: _onCurrencySelect,
                      child: Container(
                        margin: EdgeInsets.only(right: 8.0),
                        child: Text(
                            _selectedLocalization != null
                                ? _selectedLocalization!.currency!
                                : 'PHP',
                            style: TextStyle(
                              color: Colors.white,
                            )),
                      ),
                    ),
                    inputFormatters: [
                      CurrencyTextInputFormatter(symbol: ''),
                      // FilteringTextInputFormatter.allow(
                      //     RegExp(r'[0-9]')),
                      // FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      'Track Quantity',
                      style: TextStyle(
                        fontSize: SizeConfig.textScaleFactor * 13,
                        color: kBackgroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5.0),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          trackStock = !trackStock;
                        });

                        _quantityTextController.text = trackStock ? '1' : '0';
                      },
                      child: Icon(
                        trackStock
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: kBackgroundColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10.0),
                Expanded(
                  child: CustomTextFormField(
                    label: 'Quantity',
                    hintText: 'Enter quantity of your',
                    controller: _quantityTextController,
                    color: kBackgroundColor,
                    validator: trackStock
                        ? (val) {
                            if (val != null && val.isEmpty) return 'Required';

                            return null;
                          }
                        : null,
                    keyboardType: TextInputType.number,
                    isReadOnly: !trackStock,
                    removeMargin: true,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
// for version 2 and greater youcan also use this
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                ),
              ],
            ),
          ),
          CustomTextFormField(
            label: 'Description',
            hintText: 'Enter a description',
            textInputAction: TextInputAction.done,
            controller: _descTextController,
            color: kBackgroundColor,
            maxLines: 3,
            maxLength: 2000,
            keyboardType: TextInputType.text,
            validator: (val) => val != null && val.isEmpty ? 'Required' : null,
          ),
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 16.0),
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: kBackgroundColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offer Type',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12.0),
                _productTypes.length > 0
                    ? FittedBox(
                        child: ToggleSwitch(
                          activeBgColor: [
                            kBackgroundColor,
                          ],
                          initialLabelIndex: 0,
                          minWidth: double.infinity,
                          minHeight: 25.0,
                          borderColor: [Color(0xFFEBFBFF)],
                          totalSwitches: _productTypes.length,
                          labels: _productTypes.map((pt) => pt.name!).toList(),
                          onToggle: (index) {
                            _selectedOfferType = _productTypes[index!].code;
                          },
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
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
          Visibility(
            visible: showOfferTypeError,
            child: Text(
              'Required',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.red.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          // CustomTextFormField(
          //   label: 'Location',
          //   hintText: 'Tap to search location',
          //   controller: _locationTextController,
          //   isReadOnly: true,
          //   color: kBackgroundColor,
          //   suffixIcon: Icon(
          //     Icons.location_on,
          //     color: Colors.white,
          //   ),
          //   onTap: () => _onSelectLocation(),
          //   validator: (val) => val != null && val.isEmpty ? 'Required' : null,
          // ),
          Visibility(
            visible: widget.product != null,
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 16.0),
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: kBackgroundColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12.0),
                  productStatusList.length > 0 && widget.product != null
                      ? FittedBox(
                          child: ToggleSwitch(
                            initialLabelIndex: productStatusList
                                .map((s) => s.toLowerCase())
                                .toList()
                                .indexOf(_selectedStatus),
                            minWidth: double.infinity,
                            minHeight: 25.0,
                            activeBgColor: [
                              kBackgroundColor,
                            ],
                            borderColor: [Color(0xFFEBFBFF)],
                            totalSwitches: productStatusList.length,
                            labels: productStatusList
                                .map((pt) => pt.toUpperCase())
                                .toList(),
                            onToggle: (index) {
                              setState(() {
                                _selectedStatus = productStatusList[index ?? 0];
                              });
                              print(productStatusList
                                  .map((s) => s.toLowerCase())
                                  .toList()
                                  .indexOf(widget.product!.status != null
                                      ? widget.product!.status!.toLowerCase()
                                      : _selectedStatus));
                            },
                            fontSize: SizeConfig.textScaleFactor * 12,
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _onCurrencySelect() async {
    final localization = await showDialog<LocalizationModel?>(
        context: context,
        barrierDismissible: false,
        builder: (dContext) {
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
                        'Currency',
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
                      ..._locList.map(
                        (item) => ListTile(
                          title: Text(item.currency ?? ''),
                          contentPadding: EdgeInsets.zero,
                          onTap: () => Navigator.pop(dContext, item),
                          selectedColor: Color(0xFFBB3F03),
                          selected: _selectedLocalization == item,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });

    if (localization != null) {
      setState(() {
        _selectedLocalization = localization;
      });
    }
  }

  _loadUserLocation() async {
    // if (await Permission.location.isDenied) return;
    // if (!(await geoLocator.GeolocatorPlatform.instance
    //     .isLocationServiceEnabled())) return;

    if (await Permission.location.isDenied ||
        !(await geoLocator.GeolocatorPlatform.instance
            .isLocationServiceEnabled())) {
      _selectedLocation = PlaceDetails(
        placeId: '',
        name: '',
        geometry: Geometry(
          location: Location(
            lat: application.currentUserModel!.location!.latitude!.toDouble(),
            lng: application.currentUserModel!.location!.longitude!.toDouble(),
          ),
        ),
        addressComponents: [
          AddressComponent(
            longName: application.currentUserModel!.address ?? '',
            types: [],
            shortName: '',
          ),
          AddressComponent(
            longName: application.currentUserModel!.city ?? '',
            types: [],
            shortName: '',
          ),
          AddressComponent(
            longName: application.currentUserModel!.country ?? '',
            types: [],
            shortName: '',
          ),
        ],
      );
      // _locationTextController.text =
      //     '${application.currentUserModel!.address ?? ''} ${application.currentUserModel!.city ?? ''}, ${application.currentUserModel!.country ?? ''}';
    } else {
      try {
        List<geoCoding.Placemark> placemarks =
            await geoCoding.placemarkFromCoordinates(
                application.currentUserLocation!.latitude!.toDouble(),
                application.currentUserLocation!.longitude!.toDouble());
        if (placemarks.isNotEmpty) {
          placemarks.forEach((placemark) => print(placemark.toJson()));
          setState(() {
            _currentUserLoc = placemarks.first;
            _selectedLocation = PlaceDetails(
              placeId: '',
              name: _currentUserLoc!.name ?? '',
              geometry: Geometry(
                location: Location(
                  lat: application.currentUserLocation!.latitude!.toDouble(),
                  lng: application.currentUserLocation!.longitude!.toDouble(),
                ),
              ),
              addressComponents: [
                AddressComponent(
                  longName: _currentUserLoc!.street ?? '',
                  types: [],
                  shortName: '',
                ),
                AddressComponent(
                  longName: _currentUserLoc!.locality ?? '',
                  types: [],
                  shortName: '',
                ),
                AddressComponent(
                  longName: _currentUserLoc!.subAdministrativeArea ?? '',
                  types: [],
                  shortName: '',
                ),
                AddressComponent(
                  longName: _currentUserLoc!.country ?? '',
                  types: [],
                  shortName: '',
                ),
              ],
            );
            _locationTextController.text =
                '${_currentUserLoc!.street ?? ''}, ${_currentUserLoc!.locality ?? ''}, ${_currentUserLoc!.subAdministrativeArea ?? ''}, ${_currentUserLoc!.country ?? ''}';
          });
        }
      } catch (e) {}
    }
  }

  void _onUpdateTapped() {
    print(_media.length);
    if (_media.length < 1) {
      setState(() {
        showImageError = true;
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedOfferType == null) {
      setState(() {
        showOfferTypeError = true;
      });
      return;
    } else {
      setState(() {
        showOfferTypeError = false;
      });
    }

    var productRequest = ProductRequestModel.fromProduct(widget.product!);

    productRequest.productname = _nameTextController.text.trim();
    productRequest.productdesc = _descTextController.text.trim();
    productRequest.track_stock = trackStock;
    productRequest.stock_count = int.parse(
        _quantityTextController.text.trim().isNotEmpty
            ? _quantityTextController.text.trim()
            : '0');
    productRequest.price =
        double.parse(_priceTextController.text.trim().replaceAll(',', ''));
    productRequest.status = _selectedStatus;
    productRequest.free = isFree;

    if (_selectedLocation != null) {
      productRequest.address =
          _selectedLocation!.addressComponents[0]!.longName;
      productRequest.city = _selectedLocation!.addressComponents[1]!.longName;
      productRequest.country =
          _selectedLocation!.addressComponents.last!.longName;
      productRequest.location!.latitude =
          _selectedLocation!.geometry!.location.lat;
      productRequest.location!.longitude =
          _selectedLocation!.geometry!.location.lng;
    }

    if (_selectedLocalization != null) {
      productRequest.currency = _selectedLocalization!.currency;
    }

    if (_selectedOfferType != null) productRequest.type = _selectedOfferType;

    _productBloc.add(EditProduct(productRequest));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectProductCategoryScreen(
          productRequest: productRequest,
          categories: _productCategories,
          updating: true,
        ),
      ),
    );
  }

  _onSubmitTapped() async {
    if (widget.product == null) {
      if (_selectedMedia.isEmpty) {
        setState(() {
          showImageError = true;
        });
        _scrollController.scrollToIndex(0);
        return;
      }
    } else {
      if (_media.isEmpty) {
        setState(() {
          showImageError = true;
        });
        _scrollController.scrollToIndex(0);
        return;
      }
    }

    print('image passed');

    if (!_formKey.currentState!.validate()) {
      _scrollController.scrollToIndex(0);
      return;
    }

    print('1st form passed');

    if (_selectedOfferType == null) {
      setState(() {
        showOfferTypeError = true;
      });

      _scrollController.scrollToIndex(0);
      return;
    } else {
      print('offer type passed');
      setState(() {
        showOfferTypeError = false;
      });
    }

    if (_selectedCategory == null) {
      setState(() {
        showCategoryError = true;
      });

      _scrollController.scrollToIndex(1);
      return;
    } else {
      print('category passed');
      setState(() {
        showCategoryError = false;
      });
    }

    // if (_tradeForlist.isEmpty) {
    //   setState(() {
    //     showTradeForError = true;
    //   });

    //   _scrollController.scrollToIndex(2);
    //   return;
    // } else {
    //   print('trade for passed');
    //   setState(() {
    //     showTradeForError = false;
    //   });
    // }

    if (_meetUpList.isEmpty) {
      setState(() {
        showMeetUpError = true;
      });

      _scrollController.scrollToIndex(3);
      return;
    } else {
      print('meetup passed');
      setState(() {
        showMeetUpError = false;
      });
    }

    if (widget.product == null) {
      final proceed = await DialogMessage.show(
        context,
        message:
            'You are about to add ${_nameTextController.text.trim()} to your store for ${application.currentUserModel!.currency ?? 'PHP'} ${_priceTextController.text.trim()}',
        buttonText: 'Confirm',
        secondButtonText: 'Cancel',
        result1: true,
        result2: false,
      );

      if (proceed == null || proceed == false) return;
    }

    ProductRequestModel productRequest = ProductRequestModel();
    if (widget.product != null) {
      productRequest = ProductRequestModel.fromProduct(widget.product!);
    }
    productRequest.userid = application.currentUser!.uid;
    productRequest.productname = _nameTextController.text.trim();
    productRequest.price =
        double.parse(_priceTextController.text.trim().replaceAll(',', ''));
    productRequest.free = isFree;
    productRequest.track_stock = trackStock;
    productRequest.stock_count =
        trackStock ? int.parse(_quantityTextController.text.trim()) : 0;
    productRequest.productdesc = _descTextController.text.trim();
    productRequest.type = _selectedOfferType!;
    productRequest.location = LocationModel(
      longitude: _meetUpList.first.location!.longitude,
      latitude: _meetUpList.first.location!.latitude,
    );
    productRequest.address =
        _meetUpList.first.address != null ? _meetUpList.first.address : null;
    productRequest.city =
        _meetUpList.first.city != null ? _meetUpList.first.city : null;
    productRequest.country =
        _meetUpList.first.country != null ? _meetUpList.first.country : null;
    productRequest.category = _selectedCategory!.code;
    productRequest.tradefor = _tradeForlist;
    productRequest.meet_location = _meetUpList;

    if (widget.product != null)
      _productBloc.add(EditProduct(productRequest));
    else
      _productBloc.add(
          SaveProduct(productRequest: productRequest, media: _selectedMedia));
  }

  _onSaveTapped() {
    if (_selectedMedia.length < 1) {
      setState(() {
        showImageError = true;
      });
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_selectedOfferType == null) {
      setState(() {
        showOfferTypeError = true;
      });
      return;
    } else {
      setState(() {
        showOfferTypeError = false;
      });
    }
    if (_selectedLocation!.addressComponents.isNotEmpty) {
      var newProduct = ProductRequestModel(
        track_stock: trackStock,
        stock_count: int.parse(_quantityTextController.text.trim()),
        userid: _user!.uid,
        productname: _nameTextController.text.trim(),
        productdesc: _descTextController.text.trim(),
        free: isFree,
        price:
            double.parse(_priceTextController.text.trim().replaceAll(',', '')),
        type: _selectedOfferType!,
        location: LocationModel(
          longitude: _selectedLocation!.geometry!.location.lng,
          latitude: _selectedLocation!.geometry!.location.lat,
        ),
        address: _selectedLocation!.addressComponents[0] != null
            ? _selectedLocation!.addressComponents[0]!.longName
            : null,
        city: _selectedLocation!.addressComponents[1] != null
            ? _selectedLocation!.addressComponents[1]!.longName
            : null,
        country: _selectedLocation!.addressComponents.last != null
            ? _selectedLocation!.addressComponents.last!.longName
            : null,
        media_type: 'image',
      );

      if (_selectedLocalization != null) {
        newProduct.currency = _selectedLocalization!.currency;
      }

      if (_selectedLocation != null) {
        newProduct.address = _selectedLocation!.addressComponents[0] != null
            ? _selectedLocation!.addressComponents[0]!.longName
            : null;
        newProduct.city = _selectedLocation!.addressComponents[1] != null
            ? _selectedLocation!.addressComponents[1]!.longName
            : null;
        newProduct.country = _selectedLocation!.addressComponents.last != null
            ? _selectedLocation!.addressComponents.last!.longName
            : null;
        newProduct.location = LocationModel(
          longitude: _selectedLocation!.geometry!.location.lng,
          latitude: _selectedLocation!.geometry!.location.lat,
        );
      } else {
        if (_currentUserLoc != null && _currentUserPosition != null) {
          newProduct.address = _currentUserLoc!.street ?? '';
          newProduct.city = _currentUserLoc!.locality ?? '';
          newProduct.country = _currentUserLoc!.country ?? '';
          newProduct.location = LocationModel(
            longitude: _currentUserPosition!.longitude,
            latitude: _currentUserPosition!.latitude,
          );
        }
      }

      print('product request: ${newProduct.toJson()}');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectProductCategoryScreen(
            productRequest: newProduct,
            media: _selectedMedia,
            categories: _productCategories,
          ),
        ),
      );
    }
  }

  _onPhotoTapped() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
    );
    if (selectedMedia != null) {
      setState(() {
        showImageError = false;
        if (widget.product != null) {
          _productBloc
              .add(AddProductImage(widget.product!.productid!, selectedMedia));
        } else
          _selectedMedia.addAll(selectedMedia);
      });
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

  Widget _buildPhotoForEdit() {
    if (_media.isEmpty)
      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Colors.grey,
              image: DecorationImage(
                image: AssetImage('assets/images/image_placeholder.jpg'),
                scale: 1.0,
                fit: BoxFit.cover,
              ),
            ),
            child: Text(''),
            height: 160.0,
            width: double.infinity,
          ),
          Visibility(
            visible: _media.length < 10,
            child: Positioned(
              bottom: 5,
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
                    _media.length > 0 ? Icons.add_a_photo : Icons.photo_camera,
                    color: Colors.white,
                    size: 20.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      );

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CarouselSlider(
                carouselController: _carouselController,
                options: CarouselOptions(
                    height: 160.0,
                    enableInfiniteScroll: false,
                    aspectRatio: 1,
                    viewportFraction: 1,
                    onPageChanged: (index, _) {
                      setState(() {
                        _currentCarouselIndex = index;
                      });
                    }),
                items: _media.map((media) {
                  return Stack(
                    children: [
                      // Image(
                      //   image: NetworkImage(
                      //     media.url != null && media.url!.isNotEmpty
                      //         ? media.url!
                      //         : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
                      //     scale: 1,
                      //   ),
                      //   height: 160.0,
                      //   width: double.infinity,
                      //   fit: BoxFit.cover,
                      // ),
                      CachedNetworkImage(
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          padding: EdgeInsets.all(10.0),
                          child: Container(
                            child: Center(
                              child: SizedBox(
                                height: 50.0,
                                width: 50.0,
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        height: 160.0,
                        width: double.infinity,
                        imageUrl: (media.url != null && media.url!.isNotEmpty
                            ? media.url!
                            : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg'),
                      ),
                      // Container(
                      //   decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(20.0),
                      //     color: Colors.white,
                      //     image: DecorationImage(
                      //       image: CachedNetworkImageProvider(
                      //         media.url != null && media.url!.isNotEmpty
                      //             ? media.url!
                      //             : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg',
                      //         errorListener: () => print('error img'),
                      //       ),
                      //       scale: 1.0,
                      //       fit: BoxFit.cover,
                      //     ),
                      //   ),
                      //   height: 160.0,
                      //   width: double.infinity,
                      // ),
                      Positioned(
                        top: 5,
                        right: 10,
                        child: InkWell(
                          onTap: () {
                            if (widget.product == null) {
                              setState(() {
                                _selectedMedia.remove(media);
                              });
                              Future.delayed(Duration(milliseconds: 300),
                                  () => setState(() {}));
                            } else {
                              _productBloc.add(DeleteImages(
                                  [media.url!], widget.product!.productid!));
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
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
                              Icons.delete,
                              color: Colors.white,
                              size: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              Positioned(
                bottom: 8,
                child: Container(
                  width: SizeConfig.screenWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _media.asMap().keys.map((key) {
                      return Container(
                        margin: _media.length > 1
                            ? key < 5
                                ? EdgeInsets.only(right: 8.0)
                                : null
                            : null,
                        height: 8.0,
                        width: 8.0,
                        decoration: BoxDecoration(
                          color: _currentCarouselIndex == key
                              ? Colors.white
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: _media.length < 10,
          child: Positioned(
            bottom: 5,
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
                  _media.length > 0 ? Icons.add_a_photo : Icons.photo_camera,
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

  Stack _buildPhotoForAdd() {
    return Stack(
      children: [
        _selectedMedia.length > 0
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CarouselSlider(
                      carouselController: _carouselController,
                      options: CarouselOptions(
                          height: 160.0,
                          enableInfiniteScroll: false,
                          aspectRatio: 1,
                          viewportFraction: 1,
                          onPageChanged: (index, _) {
                            setState(() {
                              _currentCarouselIndex = index;
                            });
                          }),
                      items: _selectedMedia.map((media) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                color: Colors.white,
                                image: DecorationImage(
                                  image: FileImage(File(media.rawPath!)),
                                  scale: 1.0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              height: 160.0,
                              width: double.infinity,
                            ),
                            Positioned(
                              top: 5,
                              right: 10,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedMedia.remove(media);
                                  });
                                  Future.delayed(Duration(milliseconds: 300),
                                      () => setState(() {}));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
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
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 20.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    Positioned(
                      bottom: 8,
                      child: Container(
                        width: SizeConfig.screenWidth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _selectedMedia.asMap().keys.map((key) {
                            return Container(
                              margin: _selectedMedia.length > 1
                                  ? key < 5
                                      ? EdgeInsets.only(right: 8.0)
                                      : null
                                  : null,
                              height: 8.0,
                              width: 8.0,
                              decoration: BoxDecoration(
                                color: _currentCarouselIndex == key
                                    ? Colors.white
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.grey,
                  image: DecorationImage(
                    image: AssetImage('assets/images/image_placeholder.jpg'),
                    scale: 1.0,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Text(''),
                height: 160.0,
                width: double.infinity,
              ),
        Visibility(
          visible: _selectedMedia.length < 5,
          child: Positioned(
            bottom: 5,
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
                  _selectedMedia.length > 0
                      ? Icons.add_a_photo
                      : Icons.photo_camera,
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

  void _onAddLocation() {
    final loc = AddressModel(
      city: _selectedLocation!.addressComponents[1]!.longName,
      country: _selectedLocation!.addressComponents.last!.longName,
      address: _selectedLocation!.formattedAddress,
      location: LocationModel(
        latitude: _selectedLocation!.geometry!.location.lat,
        longitude: _selectedLocation!.geometry!.location.lng,
      ),
    );

    setState(() {
      _meetUpList.add(loc);
      _selectedLocation = null;
      _locationTextController.clear();
    });
  }
}

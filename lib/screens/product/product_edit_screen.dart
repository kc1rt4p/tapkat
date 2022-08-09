import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:tapkat/models/localization.dart';
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

class ProductEditScreen extends StatefulWidget {
  final ProductModel product;

  const ProductEditScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  _ProductEditScreenState createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _productBloc = ProductBloc();
  late ProductModel _product;
  List<MediaPrimaryModel> _media = [];
  int _currentCarouselIndex = 0;
  final _carouselController = CarouselController();
  String? _selectedOfferType;
  PlaceDetails? _selectedLocation;

  final _formKey = GlobalKey<FormState>();
  final iOSGoogleMapsApiKey = 'AIzaSyBCyNgeJDA8_nwdGrPf5ecuIsVFRXSF0mQ';
  final androidGoogleMapsApiKey = 'AIzaSyAH4fWM5IbEO0X-Txkm6HNsFAQ3KOfW20I';
  final webGoogleMapsApiKey = 'AIzaSyAzPjfTTLzdfp-56tarHguvLXgdw7QAGkg';

  final _nameTextController = TextEditingController();
  final _priceTextController = TextEditingController();
  final _offerTypeTextController = TextEditingController();
  final _descTextController = TextEditingController();
  final _locationTextController = TextEditingController();
  final _statusTextController = TextEditingController();
  List<ProductCategoryModel> _categories = [];
  List<ProductTypeModel> _types = [];
  int _initialTypeIndex = 0;
  String _selectedStatus = 'available';
  bool isFree = false;
  List<LocalizationModel> _locList = [];
  LocalizationModel? _selectedLocalization;

  bool showImageError = false;
  bool showOfferTypeError = false;

  int _deleteIndex = 0;

  @override
  void initState() {
    application.currentScreen = 'Product Edit Screen';
    _product = widget.product;
    print(_product.toJson());
    _selectedOfferType = _product.type;
    _init();
    _productBloc.add(InitializeAddUpdateProduct());
    _selectedStatus =
        _product.status != null ? _product.status!.toLowerCase() : 'available';
    super.initState();
  }

  void _init() {
    _media = _product.media ?? [];
    _nameTextController.text = _product.productname ?? '';
    _priceTextController.text =
        _product.price != null ? _product.price.toString() : '0.00';
    _offerTypeTextController.text = _product.type ?? '';
    _descTextController.text = _product.productdesc ?? '';
    _locationTextController.text =
        '${_product.address!.address ?? ''}, ${_product.address!.city ?? ''}, ${_product.address!.country ?? ''}';
    isFree = _product.free ?? false;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: ProgressHUD(
        backgroundColor: Colors.white,
        indicatorColor: kBackgroundColor,
        child: BlocListener(
          bloc: _productBloc,
          listener: (context, state) async {
            print('X----> CURRENT STATE:: $state');
            if (state is ProductLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
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

            if (state is InitializeAddUpdateProductSuccess) {
              print('X=..==> ${application.currentCountry}');
              setState(() {
                _locList = state.locList;

                if (_product.currency != null &&
                    _product.currency!.isNotEmpty) {
                  _selectedLocalization = _locList.firstWhere(
                      (loc) => loc.currency == _product.currency,
                      orElse: () => _locList[0]);
                } else {
                  if (_locList.isNotEmpty) {
                    if (application.currentUserModel!.currency != null &&
                        application.currentUserModel!.currency!.isNotEmpty)
                      _selectedLocalization = _locList.firstWhere((loc) =>
                          loc.currency ==
                          application.currentUserModel!.currency);
                    else {
                      if (application.currentCountry != null &&
                          _locList.any((loc) =>
                              loc.country_code == application.currentCountry)) {
                        _selectedLocalization = _locList.firstWhere((loc) =>
                            loc.country_code == application.currentCountry);
                      }
                    }
                  }
                }

                _categories = state.categories;
                _types = state.types;
                _selectedOfferType = _types
                    .firstWhere((typ) => typ.code == _product.type,
                        orElse: () => _types.first)
                    .code;
                print('==== types: $_selectedOfferType');
                _initialTypeIndex = _types.indexOf(_types.firstWhere(
                    (pt) =>
                        pt.code == _selectedOfferType ||
                        pt.name!.toLowerCase() ==
                            _selectedOfferType!.toLowerCase(),
                    orElse: () => _types[0]));
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
          },
          child: Container(
            child: Column(
              children: [
                CustomAppBar(
                  label: 'Edit Product',
                ),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 500.0),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizeConfig.screenWidth > 500
                                ? SizedBox(
                                    height: SizeConfig.screenHeight * 0.1)
                                : SizedBox(),
                            _buildPhoto(),
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
                              validator: (val) => val != null && val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            Container(
                              margin: EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
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
                                        else if (val != null &&
                                            val.isNotEmpty) {
                                          final amount = double.parse(
                                              val.replaceAll(',', ''));
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
                                                  ? _selectedLocalization!
                                                      .currency!
                                                  : 'PHP',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize:
                                                    SizeConfig.textScaleFactor *
                                                        12,
                                                fontWeight: FontWeight.w500,
                                              )),
                                        ),
                                      ),
                                      inputFormatters: [
                                        CurrencyTextInputFormatter(symbol: ''),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 10.0),
                                  Column(
                                    children: [
                                      Text('FREE',
                                          style: TextStyle(
                                            fontSize:
                                                SizeConfig.textScaleFactor * 13,
                                            color: kBackgroundColor,
                                            fontWeight: FontWeight.w600,
                                          )),
                                      SizedBox(height: 5.0),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isFree = !isFree;
                                          });

                                          _priceTextController.text = isFree
                                              ? '0'
                                              : _product.price.toString();
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
                                ],
                              ),
                            ),
                            // CustomTextFormField(
                            //   label: 'Offer Type',
                            //   hintText: 'Tap to select type',
                            //   controller: _offerTypeTextController,
                            //   isReadOnly: true,
                            //   color: kBackgroundColor,
                            //   suffixIcon: Icon(
                            //     FontAwesomeIcons.chevronDown,
                            //     color: Colors.white,
                            //   ),
                            //   onTap: () => _onSelectOfferType(context),
                            //   validator: (val) =>
                            //       val != null && val.isEmpty ? 'Required' : null,
                            // ),
                            CustomTextFormField(
                              label: 'Description',
                              hintText: 'Enter a description',
                              controller: _descTextController,
                              color: kBackgroundColor,
                              maxLines: 3,
                              maxLength: 120,
                              validator: (val) => val != null && val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),

                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 16.0),
                              padding:
                                  EdgeInsets.fromLTRB(10.0, 2.0, 10.0, 10.0),
                              // EdgeInsets.symmetric(
                              //     vertical: 10.0, horizontal: 10.0),
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
                                      fontSize: 11.0,
                                    ),
                                  ),
                                  SizedBox(height: 8.0),
                                  _types.isNotEmpty
                                      ? FittedBox(
                                          child: ToggleSwitch(
                                            initialLabelIndex:
                                                _initialTypeIndex,
                                            minWidth: double.infinity,
                                            minHeight: 25.0,
                                            borderColor: [Color(0xFFEBFBFF)],
                                            activeBgColor: [
                                              kBackgroundColor,
                                            ],
                                            totalSwitches: _types.length,
                                            labels: _types
                                                .map((pt) => pt.name!)
                                                .toList(),
                                            onToggle: (index) {
                                              _selectedOfferType =
                                                  _types[index!].code!;
                                            },
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
                              validator: (val) => val != null && val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 16.0),
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 10.0),
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
                                  productStatusList.length > 0
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
                                            totalSwitches:
                                                productStatusList.length,
                                            labels: productStatusList
                                                .map((pt) => pt.toUpperCase())
                                                .toList(),
                                            onToggle: (index) {
                                              setState(() {
                                                _selectedStatus =
                                                    productStatusList[
                                                        index ?? 0];
                                              });
                                              print(productStatusList
                                                  .map((s) => s.toLowerCase())
                                                  .toList()
                                                  .indexOf(
                                                      _product.status != null
                                                          ? _product.status!
                                                              .toLowerCase()
                                                          : _selectedStatus));
                                            },
                                            fontSize:
                                                SizeConfig.textScaleFactor * 12,
                                          ),
                                        )
                                      : Container(),
                                ],
                              ),
                            ),
                            Container(
                              child: CustomButton(
                                removeMargin: true,
                                label: 'Next',
                                onTap: _onUpdateTapped,
                              ),
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

    var productRequest = ProductRequestModel.fromProduct(_product);

    productRequest.productname = _nameTextController.text.trim();
    productRequest.productdesc = _descTextController.text.trim();
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
          categories: _categories,
          updating: true,
        ),
      ),
    );
  }

  _onSelectOfferType(BuildContext context) async {
    final type = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
              child: ListView(
                shrinkWrap: true,
                // mainAxisSize: MainAxisSize.min,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Offer Type',
                        style: Style.subtitle2.copyWith(
                          color: kBackgroundColor,
                          fontSize: 12.0,
                        ),
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
                  SizedBox(height: 8.0),
                  ListTile(
                    title: Text('Product'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Navigator.pop(context, 'product'),
                    selectedColor: Color(0xFFBB3F03),
                    selected: _selectedOfferType == 'product',
                  ),
                  ListTile(
                    title: Text('Service'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Navigator.pop(context, 'service'),
                    selectedColor: Color(0xFFBB3F03),
                    selected: _selectedOfferType == 'service',
                  ),
                  ListTile(
                    title: Text('Event'),
                    contentPadding: EdgeInsets.zero,
                    onTap: () => Navigator.pop(context, 'event'),
                    selectedColor: Color(0xFFBB3F03),
                    selected: _selectedOfferType == 'event',
                  ),
                ],
              ),
            ),
          );
        });

    if (type != null) {
      setState(() {
        _selectedOfferType = type;
      });

      _offerTypeTextController.text = type[0].toUpperCase() + type.substring(1);
    }
  }

  Widget _buildPhoto() {
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
                            _productBloc.add(DeleteImages(
                                [media.url!], _product.productid!));
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

  _onPhotoTapped() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
    );

    if (selectedMedia != null &&
        validateFileFormat(selectedMedia.storagePath, context)) {
      showImageError = false;
      _productBloc.add(AddProductImage(_product.productid!, [selectedMedia]));
    }
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
      components: [
        Component(Component.country, 'ph'),
        Component(Component.country, 'sg')
      ],
      strictbounds: false,
    );

    if (p != null && p.placeId != null) displayPrediction(p);
  }
}

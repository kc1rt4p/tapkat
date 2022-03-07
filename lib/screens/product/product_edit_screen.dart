import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:tapkat/models/media_primary_model.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/models/request/add_product_request.dart';
import 'package:tapkat/screens/product/bloc/product_bloc.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/dialog_message.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/utilities/upload_media.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_textformfield.dart';

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

  @override
  void initState() {
    _product = widget.product;
    _init();
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
            if (state is ProductLoading) {
              ProgressHUD.of(context)!.show();
            } else {
              ProgressHUD.of(context)!.dismiss();
            }

            if (state is DeleteImagesSuccess) {
              await DialogMessage.show(context,
                  message: 'An image has been deleted.');

              setState(() {
                state.urls.forEach((url) {
                  _media.removeWhere((media) => media.url == url);
                });
              });
            }

            if (state is EditProductSuccess) {
              await DialogMessage.show(context,
                  message: 'The product has been updated.');

              Navigator.pop(context);
            }

            if (state is AddProductImageSuccess) {
              await DialogMessage.show(context,
                  message: 'An image has been uploaded for this product.');
              setState(() {
                _media.addAll(state.result.media!
                    .where((media) => !_media.any((m) => m.url == media.url))
                    .toList());
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
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        children: [
                          _buildPhoto(),
                          // Visibility(
                          //       visible: showImageError,
                          //       child: Text(
                          //         'Please select image(s) of your offer',
                          //         style: TextStyle(
                          //           fontSize: 12.0,
                          //           color: Colors.red.shade400,
                          //           fontStyle: FontStyle.italic,
                          //         ),
                          //       ),
                          //     ),
                          SizedBox(height: 16.0),
                          CustomTextFormField(
                            label: 'Name',
                            hintText: 'Enter your offer\'s name',
                            controller: _nameTextController,
                            color: kBackgroundColor,
                            validator: (val) =>
                                val != null && val.isEmpty ? 'Required' : null,
                          ),
                          CustomTextFormField(
                            label: 'Price',
                            hintText: 'Enter the price you want',
                            controller: _priceTextController,
                            color: kBackgroundColor,
                            validator: (val) =>
                                val != null && val.isEmpty ? 'Required' : null,
                            keyboardType: TextInputType.number,
                          ),
                          CustomTextFormField(
                            label: 'Offer Type',
                            hintText: 'Tap to select type',
                            controller: _offerTypeTextController,
                            isReadOnly: true,
                            color: kBackgroundColor,
                            suffixIcon: Icon(
                              FontAwesomeIcons.chevronDown,
                              color: Colors.white,
                            ),
                            onTap: () => _onSelectOfferType(context),
                            validator: (val) =>
                                val != null && val.isEmpty ? 'Required' : null,
                          ),
                          CustomTextFormField(
                            label: 'Description',
                            hintText: 'Enter a description',
                            controller: _descTextController,
                            color: kBackgroundColor,
                            maxLines: 3,
                            validator: (val) =>
                                val != null && val.isEmpty ? 'Required' : null,
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
                            validator: (val) =>
                                val != null && val.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: CustomButton(
                    label: 'Update',
                    onTap: _onUpdateTapped,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onUpdateTapped() {
    var productRequest = ProductRequestModel(
      productname: _nameTextController.text.trim(),
      productdesc: _descTextController.text.trim(),
      price: double.parse(_priceTextController.text.trim()),
      productid: _product.productid,
    );

    if (_selectedLocation != null) {
      productRequest.address =
          _selectedLocation!.addressComponents[0]!.longName;
      productRequest.city = _selectedLocation!.addressComponents[1]!.longName;
      productRequest.country =
          _selectedLocation!.addressComponents.last!.longName;
    }

    if (_selectedOfferType != null) productRequest.type = _selectedOfferType;

    _productBloc.add(EditProduct(productRequest));
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

  Stack _buildPhoto() {
    return Stack(
      children: [
        _media.length > 0
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
                      items: _media.map((media) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                color: Colors.white,
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(media.url !=
                                              null &&
                                          media.url!.isNotEmpty
                                      ? media.url!
                                      : 'https://storage.googleapis.com/map-surf-assets/noimage.jpg'),
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
      components: [],
      strictbounds: false,
    );

    if (p != null && p.placeId != null) displayPrediction(p);
  }
}

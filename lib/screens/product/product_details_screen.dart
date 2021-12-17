import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tapkat/screens/barter/barter_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';

class ProductDetailsScreen extends StatefulWidget {
  final bool ownItem;
  final String productId;
  final String productName;
  final String price;
  final String imgUrl;
  final String desc;
  final String owner;
  final Map<String, dynamic> address;
  final String rating;
  final String likes;

  const ProductDetailsScreen({
    Key? key,
    this.ownItem = false,
    required this.productId,
    required this.productName,
    required this.price,
    required this.imgUrl,
    required this.desc,
    required this.address,
    required this.owner,
    required this.rating,
    required this.likes,
  }) : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _carouselController = CarouselController();
  int _currentCarouselIndex = 0;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            CustomAppBar(
              label: 'Product Details',
            ),
            Expanded(
              child: Container(
                child: Column(
                  children: [
                    Container(
                      color: Colors.grey,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CarouselSlider(
                            carouselController: _carouselController,
                            options: CarouselOptions(
                                height: SizeConfig.screenHeight * .3,
                                enableInfiniteScroll: false,
                                aspectRatio: 1,
                                viewportFraction: 1,
                                onPageChanged: (index, _) {
                                  setState(() {
                                    _currentCarouselIndex = index;
                                  });
                                }),
                            items: List.generate(5, (index) {
                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: widget.imgUrl.isEmpty
                                        ? AssetImage(
                                                'assets/images/image_placeholder.jpg')
                                            as ImageProvider<Object>
                                        : CachedNetworkImageProvider(
                                            widget.imgUrl),
                                  ),
                                ),
                              );
                            }),
                          ),
                          Positioned(
                            bottom: 8,
                            child: Container(
                              width: SizeConfig.screenWidth,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return Container(
                                    margin: index < 5
                                        ? EdgeInsets.only(right: 8.0)
                                        : null,
                                    height: 8.0,
                                    width: 8.0,
                                    decoration: BoxDecoration(
                                      color: _currentCarouselIndex == index
                                          ? Colors.white
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 20.0,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  widget.productName,
                                  style: Style.subtitle1
                                      .copyWith(color: Colors.black),
                                ),
                              ), // Item Description
                              Container(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.price,
                                        style: TextStyle(
                                          fontSize: 24.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Listed by:',
                                          style: TextStyle(
                                            fontSize: 13.0,
                                            color: Color(0xFF414141),
                                          ),
                                        ),
                                        Text(
                                          widget.owner,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 16.0),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20.0, vertical: 10.0),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFBB3F03),
                                        borderRadius:
                                            BorderRadius.circular(9.0),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'View Store',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.0,
                                ),
                                child: Divider(
                                  thickness: 0.3,
                                  color: kBackgroundColor,
                                ),
                              ),
                              Container(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_pin,
                                              size: 16.0,
                                            ),
                                            Text(
                                              widget.address['city'] ?? '',
                                              style: TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          ],
                                        ),
                                        Row(
                                          children: List.generate(5, (i) {
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                  right: i != 5 ? 5.0 : 0.0),
                                              child: Icon(
                                                i < int.parse(widget.rating)
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Color(0xFFFFC107),
                                                size: 20.0,
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      widget.rating,
                                      style: TextStyle(fontSize: 16.0),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                FontAwesomeIcons.solidHeart,
                                                color: Color(0xFF94D2BD),
                                              ),
                                              SizedBox(width: 5.0),
                                              Text(widget.likes),
                                              SizedBox(width: 20.0),
                                              Icon(
                                                FontAwesomeIcons.share,
                                                color: Color(0xFF94D2BD),
                                              ),
                                              SizedBox(width: 20.0),
                                              Icon(
                                                FontAwesomeIcons
                                                    .solidCommentDots,
                                                color: Color(0xFF94D2BD),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.0,
                                ),
                                child: Divider(
                                  thickness: 0.3,
                                  color: kBackgroundColor,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(bottom: 16.0),
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(bottom: 16.0),
                                      child: Text(
                                        'Product Description',
                                        style: Style.subtitle2,
                                      ),
                                    ),
                                    Container(
                                      child: Text(widget.desc),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                      child: CustomButton(
                        label: 'BARTER',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BarterScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/barter_list_item.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';

class BarterScreen extends StatefulWidget {
  const BarterScreen({Key? key}) : super(key: key);

  @override
  _BarterScreenState createState() => _BarterScreenState();
}

class _BarterScreenState extends State<BarterScreen> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: Color(0xFFEBFBFF),
      body: Container(
        child: Column(
          children: [
            CustomAppBar(label: 'Barter with Joe'),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Tap the (+) icon to add items on your barter, you can select multiple items from your gallery.',
                            style: Style.bodyText1,
                          ),
                        ),
                        _buildBarterList(
                          label: 'You want this item(s) from Joe',
                          items: [
                            _buildBarterListItem(
                              itemName: 'Sample 1',
                              itemPrice: '100',
                              imgUrl: '',
                            ),
                          ],
                          addBtnTapped: () => _showItems(
                            label: 'Select item(s) from Joe',
                            items: [
                              _buildBarterListItem(
                                itemName: 'Sample 1',
                                itemPrice: '100',
                                imgUrl: '',
                              ),
                              _buildBarterListItem(
                                itemName: 'Sample 2',
                                itemPrice: '200',
                                imgUrl: '',
                              ),
                              _buildBarterListItem(
                                itemName: 'Sample 3',
                                itemPrice: '300',
                                imgUrl: '',
                              ),
                            ],
                          ),
                        ),
                        _buildBarterList(
                          label: 'Your offer',
                          labelAction: Text(
                            '0 Item(s) Offered',
                          ),
                          items: [
                            _buildBarterListItem(
                              itemName: 'Sample 1',
                              itemPrice: '100',
                              imgUrl: '',
                            ),
                          ],
                          addBtnTapped: () => _showItems(
                            label: 'Select your offer(s)',
                            items: [
                              _buildBarterListItem(
                                itemName: 'Sample 1',
                                itemPrice: '100',
                                imgUrl: '',
                              ),
                              _buildBarterListItem(
                                itemName: 'Sample 2',
                                itemPrice: '200',
                                imgUrl: '',
                              ),
                              _buildBarterListItem(
                                itemName: 'Sample 3',
                                itemPrice: '300',
                                imgUrl: '',
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
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                children: [
                  CustomButton(
                    label: 'Send Proposal to Joe',
                    bgColor: Color(0xFFBB3F03),
                    textColor: Colors.white,
                    onTap: () {},
                    removeMargin: true,
                  ),
                  SizedBox(height: 8.0),
                  Text('Joe will be notified once you send this proposal'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _buildBarterList({
    required String label,
    required List<Widget> items,
    Widget? labelAction,
    bool showAddBtn = true,
    Function()? addBtnTapped,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.0),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: Style.subtitle2.copyWith(
                    color: kBackgroundColor, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              labelAction ?? Container(),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 10.0),
                  ...items,
                  Visibility(
                    visible: showAddBtn,
                    child: _buildAddItemBtn(
                      onTap: addBtnTapped ?? () {},
                    ),
                  ),
                  SizedBox(width: 10.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _showItems({required String label, required List<Widget> items}) {
    showMaterialModalBottomSheet(
        isDismissible: false,
        context: context,
        builder: (context) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(30),
                topLeft: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBarterList(
                  label: label,
                  labelAction: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      FontAwesomeIcons.times,
                      color: kBackgroundColor,
                    ),
                  ),
                  items: items,
                  showAddBtn: false,
                ),
                CustomButton(
                  label: 'Add Items',
                  bgColor: Color(0xFFBB3F03),
                  textColor: Colors.white,
                  onTap: () {},
                  removeMargin: true,
                ),
              ],
            ),
          );
        });
  }

  InkWell _buildAddItemBtn({
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 190.0,
        width: 170.0,
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              offset: Offset(1, 1),
              color: Colors.grey,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            FontAwesomeIcons.plus,
            color: Colors.white,
            size: 40.0,
          ),
        ),
      ),
    );
  }

  Widget _buildBarterListItem({
    required String itemName,
    required String itemPrice,
    required String imgUrl,
    Function()? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2, right: 16.0),
      child: Stack(
        children: [
          BarterListItem(
            itemName: itemName,
            itemPrice: itemPrice,
            imageUrl: imgUrl,
            hideLikeBtn: true,
          ),
          Positioned(
            top: 0.0,
            right: 0.0,
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 30.0,
                width: 30.0,
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FontAwesomeIcons.times,
                  color: Colors.white,
                  size: 20.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

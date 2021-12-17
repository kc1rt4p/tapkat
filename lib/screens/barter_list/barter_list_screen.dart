import 'package:flutter/material.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';
import 'package:tapkat/widgets/custom_search_bar.dart';

class BarterListScreen extends StatefulWidget {
  final String title;
  final List<Widget> items;
  final bool showAdd;

  const BarterListScreen({
    Key? key,
    required this.title,
    required this.items,
    this.showAdd = false,
  }) : super(key: key);

  @override
  _BarterListScreenState createState() => _BarterListScreenState();
}

class _BarterListScreenState extends State<BarterListScreen> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: Color(0xFFEBFBFF),
      body: Container(
        child: Column(
          children: [
            CustomAppBar(
              label: widget.title,
            ),
            CustomSearchBar(
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              controller: TextEditingController(),
              backgroundColor: Color(0xFF005F73).withOpacity(0.3),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 8.0),
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Text('Sort by:'),
                  SizedBox(width: 5.0),
                  _buildSortOption(),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9.0),
                          color: Colors.white),
                      child: Center(
                          child: Text(
                        'Most Recent',
                        style: TextStyle(
                          fontSize: 12.0,
                        ),
                      )),
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9.0),
                          color: Colors.white),
                      child: Row(
                        children: [
                          Text(
                            'Price',
                            style: TextStyle(
                              fontSize: 12.0,
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 14.0,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                child: widget.items.isNotEmpty
                    ? GridView.count(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 10.0),
                        crossAxisCount: 2,
                        mainAxisSpacing: 14.0,
                        crossAxisSpacing: 12.0,
                        children: widget.items
                            .map((item) => Center(child: item))
                            .toList(),
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: 30.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No products found',
                                style: Style.subtitle2
                                    .copyWith(color: Colors.grey),
                              ),
                              SizedBox(height: 16.0),
                              Visibility(
                                visible: widget.showAdd,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30.0),
                                  child: CustomButton(
                                    label: 'Add Product',
                                    onTap: () {},
                                  ),
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
    );
  }

  Expanded _buildSortOption() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.0),
          color: Colors.white,
        ),
        child: Center(
            child: Text(
          'Relevance',
          style: TextStyle(
            fontSize: 12.0,
          ),
        )),
      ),
    );
  }
}

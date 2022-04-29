import 'package:flutter/material.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/utilities/style.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';
import 'package:tapkat/widgets/custom_button.dart';

class ProductTradeForScreen extends StatefulWidget {
  final List<String> list;
  final bool updating;
  const ProductTradeForScreen({
    Key? key,
    required this.list,
    required this.updating,
  }) : super(key: key);

  @override
  State<ProductTradeForScreen> createState() => _ProductTradeForScreenState();
}

class _ProductTradeForScreenState extends State<ProductTradeForScreen> {
  List<String> _list = [];
  final inputTextController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void initState() {
    _list = widget.list;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          CustomAppBar(
            label: widget.updating ? 'Edit Product' : 'Add to Your Store',
          ),
          Expanded(
            child: Container(
              width: SizeConfig.screenWidth,
              height: SizeConfig.screenHeight,
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  SizedBox(height: SizeConfig.screenHeight * 0.1),
                  Text('What do you want to get in return for this item?',
                      style: Style.subtitle2),
                  SizedBox(height: 25.0),
                  TextFormField(
                    focusNode: focusNode,
                    controller: inputTextController,
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: kBackgroundColor),
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
                                            fontSize:
                                                SizeConfig.textScaleFactor * 15,
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
                  SizedBox(height: 25.0),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Skip',
                          onTap: () => Navigator.pop(context, 'skip'),
                          bgColor: Style.secondaryColor,
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: CustomButton(
                          enabled: _list.isNotEmpty,
                          bgColor: Colors.red.shade400,
                          label: 'Clear',
                          onTap: () {
                            setState(() {
                              _list.clear();
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: CustomButton(
                          enabled: _list.isNotEmpty,
                          bgColor: kBackgroundColor,
                          label: 'Submit',
                          onTap: () => Navigator.pop(context, _list),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

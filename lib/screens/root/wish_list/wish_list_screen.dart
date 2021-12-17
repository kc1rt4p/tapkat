import 'package:flutter/material.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/widgets/custom_app_bar.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({Key? key}) : super(key: key);

  @override
  _WishListScreenState createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: Container(
        color: Color(0xFFEBFBFF),
        child: Column(
          children: [
            CustomAppBar(
              label: 'Your Wish List',
              hideBack: true,
            ),
          ],
        ),
      ),
    );
  }
}

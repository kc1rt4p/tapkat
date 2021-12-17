import 'package:flutter/material.dart';
import 'package:tapkat/screens/product/product_add_screen.dart';
import 'package:tapkat/screens/root/barter/barter_transactions_screen.dart';
import 'package:tapkat/screens/root/home/home_screen.dart';
import 'package:tapkat/screens/root/profile/profile_screen.dart';
import 'package:tapkat/screens/root/wish_list/wish_list_screen.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({Key? key}) : super(key: key);

  @override
  _RootScreenState createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final _screens = [
    HomeScreen(),
    WishListScreen(),
    BarterTransactionsScreen(),
    ProfileScreen(),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool showFab = MediaQuery.of(context).viewInsets.bottom == 0.0;
    SizeConfig().init(context);
    return Scaffold(
      body: Container(
        color: kBackgroundColor,
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: kBackgroundColor,
                child: _screens[_currentIndex],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: showFab && _currentIndex == 0 || _currentIndex == 3
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50.0),
              ),
              padding: EdgeInsets.all(5.0),
              child: FloatingActionButton(
                heroTag: 'addProductBtn',
                backgroundColor: Color(0xFFBB3F03),
                child: Icon(Icons.add, size: 30.0),
                onPressed: _onAddTapped,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  _onAddTapped() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductAddScreen(),
      ),
    );

    setState(() {
      _currentIndex = 1;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _currentIndex = 0;
      });
    });
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: kToolbarHeight,
      color: Color(0xFFEBFBFF),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBottomNavItem(
              isActive: _currentIndex == 0,
              icon: Icons.home,
              index: 0,
            ),
            _buildBottomNavItem(
              isActive: _currentIndex == 1,
              icon: Icons.favorite,
              index: 1,
            ),
            Visibility(
              visible: _currentIndex == 0 || _currentIndex == 3,
              child: SizedBox(
                width: 50.0,
              ),
            ),
            _buildBottomNavItem(
              isActive: _currentIndex == 2,
              icon: Icons.repeat_outlined,
              index: 2,
            ),
            _buildBottomNavItem(
              isActive: _currentIndex == 3,
              icon: Icons.person,
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Expanded _buildBottomNavItem({
    required IconData icon,
    required bool isActive,
    required int index,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          child: Icon(
            icon,
            color: isActive ? Color(0xFF94D2BD) : Colors.grey,
            size: isActive ? 30.0 : null,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../buttons/nav_bar_button.dart';

class CustomBottomAppBarProfile extends StatelessWidget {
  const CustomBottomAppBarProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      height: 80,
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 12,
      shadowColor: Colors.black,
      elevation: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          NavBarButton(
            icon: Icons.home,
            label: 'Terjemah',
            isActive: false,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/report');
            },
          ),
          NavBarButton(
            icon: Icons.person_outline,
            label: 'Pengaturan',
            isActive: true,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/profile');
            },
          ),
        ],
      ),
    );
  }
}
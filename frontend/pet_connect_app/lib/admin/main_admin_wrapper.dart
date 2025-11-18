/// Autor: Wilbert López Veras 
/// Fecha de creación: 17 de noviembre de 2025
/// Descripción:
/// Pantalla principal del administrador en la aplicación.
/// 

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'screens/admin_user_list_screen.dart';
import '../shared/profile/profile_screen.dart';


class MainAdminWrapper extends StatefulWidget {
  final int initialIndex;
  const MainAdminWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainAdminWrapper> createState() => _MainAdminWrapperState();
}

class _MainAdminWrapperState extends State<MainAdminWrapper> {
  late int _currentIndex;
  late final PageController _pageController;

  final List<Widget> _screens = const [
    AdminUserListScreen(),
    AdminUserListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _onNavTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.report),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Yo',
          
          ),
        ],
      ),
    );
  }
}
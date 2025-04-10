import 'package:fasumku/view/loading/loading_screen.dart';
import 'package:fasumku/view/register/register_screen.dart';
import 'package:fasumku/view/register/register_screen_coba.dart';
import 'package:fasumku/view/report/facility_report_screen.dart';
import 'package:fasumku/view/report/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:fasumku/view/dashboard/dahsboard_screen.dart';
import 'package:fasumku/view/login/login_screen_new.dart';
import 'package:fasumku/view/login/login_screen.dart';
import 'package:fasumku/view/profile/profile_screen_new.dart';

class PageRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/registercoba':
        return _buildPageRoute(RegisterScreenCoba());
      case '/logincoba':
        return _buildPageRoute(LoginScreenCoba());
      case '/login':
        return _buildPageRoute(LoginScreen());
      case '/loading':
        return _buildPageRoute(LoadingScreen());
      case '/register':
        return _buildPageRoute(RegisterScreen());
      case "/scan":
        return _buildPageRoute(FacilityReportScreen());
      case '/report':
        return _buildPageRoute(ReportsScreen());
      case '/dashboard':
        return _buildPageRoute(DashboardScreen());
      case '/profile':
        return _buildPageRoute(ProfileScreen());
      default:
        return _buildPageRoute(LoadingScreen());
    }
  }

  static PageRouteBuilder _buildPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

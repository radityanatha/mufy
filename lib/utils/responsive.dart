import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 || 
      Platform.isWindows || 
      Platform.isLinux || 
      Platform.isMacOS;

  static bool isAndroid(BuildContext context) {
    return Platform.isAndroid;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static double getMaxWidth(BuildContext context) {
    if (isDesktop(context)) {
      final screenWidth = MediaQuery.of(context).size.width;
      return isLandscape(context) ? screenWidth * 0.8 : 1200;
    }
    return double.infinity;
  }

  static double getPadding(BuildContext context) {
    if (isDesktop(context)) {
      final screenWidth = MediaQuery.of(context).size.width;
      return isLandscape(context) 
          ? screenWidth * 0.02 
          : 32;
    }
    return 16;
  }
}


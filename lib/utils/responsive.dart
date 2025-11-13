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

  static double getMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    return double.infinity;
  }

  static double getPadding(BuildContext context) {
    if (isDesktop(context)) return 32;
    return 16;
  }
}


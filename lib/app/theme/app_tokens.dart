import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppRadius {
  static const input = 12.0;
  static const button = 12.0;
  static const card = 16.0;
  static const sheet = 24.0;
}

abstract final class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0D17221E), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

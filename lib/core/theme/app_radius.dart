import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double card = 12;
  static const double button = 10;
  static const double input = 10;
  static const double bottomSheet = 16;
  static const double dialog = 16;
  static const double badge = 8;

  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get buttonRadius => BorderRadius.circular(button);
  static BorderRadius get inputRadius => BorderRadius.circular(input);
  static const BorderRadius bottomSheetRadius = BorderRadius.vertical(
    top: Radius.circular(bottomSheet),
  );
  static BorderRadius get dialogRadius => BorderRadius.circular(dialog);
  static BorderRadius get badgeRadius => BorderRadius.circular(badge);
}

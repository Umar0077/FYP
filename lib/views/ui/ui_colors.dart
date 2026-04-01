import 'package:flutter/material.dart';

Color foregroundOnBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0A0F2E);

Color secondaryTextColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF7C86B2);

Color containerColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B0F4E) : const Color(0xFFF2F4FF);

Color borderColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);

Color chipSelectedColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFF131964) : const Color(0xFFE9ECFF);

Color progressBg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFF27308A) : const Color(0xFFE0E5FF);

BoxDecoration filledBoxDecoration(BuildContext context) => BoxDecoration(
      color: containerColor(context),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor(context)),
    );

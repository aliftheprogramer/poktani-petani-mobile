import 'package:flutter/material.dart';

// Shared theme constants
const Color kPrimaryColor = Color(0xFF2D6A4F);
const Color kBackgroundColor = Color(0xFFEEEEEE);
const Color kTextColor = Color(0xFF171717);

InputDecoration themedInput(
  String label, {
  Widget? suffixIcon,
  Widget? prefixIcon,
}) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: kTextColor),
  filled: true,
  fillColor: Colors.white,
  suffixIcon: suffixIcon,
  prefixIcon: prefixIcon,
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: kPrimaryColor, width: 1),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: kPrimaryColor, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.red),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.red, width: 2),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);

ButtonStyle primaryButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: kPrimaryColor,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  textStyle: const TextStyle(fontWeight: FontWeight.w600),
);

BoxDecoration cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: kPrimaryColor, width: 1),
  boxShadow: const [
    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
  ],
);

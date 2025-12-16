import 'package:flutter/material.dart';

final buttonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.transparent,
  shadowColor: Colors.transparent,
  foregroundColor: Color(0xFF222222),
  textStyle: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w400),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(40),
    side: const BorderSide(color: Color(0xFF0068B7), width: 0.5)
  ),
  minimumSize: const Size(300, 50), // width, height
);

final uploadStyle = ElevatedButton.styleFrom(
  backgroundColor: Color(0xFF0068B7),
  shadowColor: Colors.transparent,
  foregroundColor: Colors.white,
  textStyle: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(40),
    side: const BorderSide(color: Color(0xFF0068B7), width: 0.5)
  ),
  minimumSize: const Size(300, 50), // width, height
);





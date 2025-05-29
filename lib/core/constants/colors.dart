import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Color primary = Colors.purple; // default

final Map<String, MaterialColor> availableColors = {
  'Blue': Colors.blue,
  'Red': Colors.red,
  'Green': Colors.green,
  'Purple': Colors.purple,
  'Orange': Colors.orange,
};

Future<void> loadPrimaryColor() async {
  final prefs = await SharedPreferences.getInstance();
  final colorName = prefs.getString('primaryColor') ?? 'purple';
  primary = availableColors[colorName] ?? Colors.blue;
}


//font colors
const whiteFont = Color.fromARGB(255, 255, 255, 255);

//dark ui

const darkPrimary = Color.fromARGB(255, 8, 8, 8);
const darkSecondary = Color.fromARGB(255, 34, 32, 32);

//light ui

const lightPrimary = Color.fromARGB(255, 224, 223, 223);
const lightSecondary = Color.fromARGB(255, 255, 255, 255);
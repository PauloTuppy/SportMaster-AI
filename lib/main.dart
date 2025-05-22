import 'package:flutter/material.dart';
import 'package:sportmaster_ai/screens/home_screen.dart';

void main() {
  runApp(SportMasterApp());
}

class SportMasterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SportMaster AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}
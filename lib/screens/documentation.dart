import 'package:flutter/material.dart';
import 'package:incentivesystem/widgets/buttons.dart';

class Documentation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Color(0xffedf0f2);
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsGeometry.directional(top: 1),
            child: Image.asset('assets/icons/logo.png', height: 50, width: 400),
          ),
          Padding(
            padding: const EdgeInsets.all(1),
            child: Text(
              'DOWNLOAD DOCUMENTATION',
              style: TextStyle(
                fontFamily: 'Archivo',
                fontSize: 60,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          SizedBox(height: 30),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: () {},
                      child: Text('DOWNLOAD DOCUMENTATION'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

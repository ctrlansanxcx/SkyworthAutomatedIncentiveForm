import 'package:flutter/material.dart';
import 'package:incentivesystem/widgets/buttons.dart';

class DownloadForm extends StatelessWidget{
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
              'DOWNLOAD FORMAT',
              style: TextStyle(
                fontFamily: 'Archivo',
                fontSize: 50,
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
                      child: Text('DOWNLOAD PRICE'),
                    ),
                  ],
                ),
                SizedBox(width: 20),
                //SECOND COLUMN
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: () {},
                      child: Text('DOWNLOAD QUANTITY'),
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
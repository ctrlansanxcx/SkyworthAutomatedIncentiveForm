import 'package:flutter/material.dart';
import 'package:incentivesystem/screens/insert_branch.dart';
import 'package:incentivesystem/screens/documentation.dart';
import 'package:incentivesystem/screens/download_form.dart';
import 'package:incentivesystem/screens/insertquantity.dart';
import 'package:incentivesystem/screens/updateprice.dart';
import '/widgets/buttons.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    Color(0xffedf0f2);
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Image.asset('assets/icons/logo.png', height: 50, width: 400),
          ),
          Padding(
            padding: const EdgeInsets.all(1),
            child: Text(
              'INCENTIVE FORM',
              style: TextStyle(
                fontFamily: 'Archivo',
                fontSize: 90,
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
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Updateprice()));
                      },
                      child: Text('UPDATED INCENTIVE FORM'),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => InsertBranches()));
                      },
                      child: Text('DEALER DETAILS'),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Documentation()));
                      },
                      child: Text('DOCUMENTATION'),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => InsertQuantity()),
                        );
                      },
                      child: Text('INSERT QUANTITY'),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DownloadForm()),
                        );
                      },
                      child: Text('DOWNLOAD FORMAT'),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: () {},
                      child: Text('HELP'),
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

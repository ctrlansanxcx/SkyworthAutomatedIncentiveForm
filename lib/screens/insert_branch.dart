import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:incentivesystem/endpoints/searchdealers.dart';
import 'package:incentivesystem/model/dealer.dart';
import 'package:incentivesystem/widgets/search_list_widget.dart';
import 'package:incentivesystem/widgets/searchbar.dart';

class InsertBranches extends StatefulWidget {
  const InsertBranches({super.key});

  @override
  State<InsertBranches> createState() => _InsertBranchesState();
}

class _InsertBranchesState extends State<InsertBranches> {
  Dealer? selectedDealer; // Selected dealer
  Dealer? selectedBranch; // Selected branch

  final dealerController = TextEditingController();
  final branchController = TextEditingController();
  final branchCodeController = TextEditingController();
  final coorController = TextEditingController();

  String dealerQuery = '';
  String branchQuery = '';

  bool _isSearching = false;

  List<Dealer> dealers = [];

  @override
  void initState() {
    super.initState();
    _performSearch(''); // fetch all dealers initially
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);

    final results = await searchDealers(query);

    List<Dealer> dealerObjects = results
        .map((e) => Dealer.fromJson(e))
        .toList();

    setState(() {
      dealers = dealerObjects;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color(0xffedf0f2);
    List<Dealer> dealerSuggestions = dealers
        .where(
          (d) => d.dealer.toLowerCase().startsWith(dealerQuery.toLowerCase()),
        )
        .toList();

    // Branch suggestions (filtered by selectedDealer and branchQuery)
    List<Dealer> branchSuggestions = dealers
        .where(
          (d) =>
              d.dealer == selectedDealer?.dealer &&
              d.branch.toLowerCase().contains(branchQuery.toLowerCase()),
        )
        .toList();
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
              'DEALER INFORMATION',
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
              crossAxisAlignment:
                  CrossAxisAlignment.start, // align rows properly
              children: [
                // Labels Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        'DEALER',
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 30,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 45),
                      child: Text(
                        'BRANCH',
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 30,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'BRANCH CODE',
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 30,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'MARKETING\nCOORDINATOR',
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 30,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(width: 40),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //DEALER SEARCH
                    SizedBox(
                      height: 100,
                      width: 400,
                      child: Column(
                        children: [
                          TextField(
                            controller: dealerController,
                            decoration: dealerSearch,
                            onChanged: (value) {
                              setState(() {
                                dealerQuery = value;
                                selectedDealer = null;
                                selectedBranch = null;
                                branchController.clear();
                                branchCodeController.clear();
                                coorController.clear();
                                _performSearch(value); // fetch dealers from API
                              });
                            },
                            textAlign: TextAlign.center,
                          ),
                          if (dealerQuery.isNotEmpty && !_isSearching)
                            SizedBox(
                              height: 40,
                              child: SearchListWidget(
                                query: dealerQuery,
                                type: SearchType.dealer,
                                items: dealerSuggestions,
                                onItemSelected: (dealer) {
                                  setState(() {
                                    selectedDealer = dealer;
                                    dealerController.text = dealer.dealer;
                                    branchController.clear();
                                    branchCodeController.clear();
                                    coorController.clear();
                                    branchQuery = '';
                                    dealerQuery = ''; // <-- hide dropdown
                                  });
                                },
                              ),
                            ),
                          if (_isSearching && dealerQuery.isNotEmpty)
                            const Center(
                              child: CircularProgressIndicator(strokeWidth: 1),
                            ),
                        ],
                      ),
                    ),

                    //BRANCH SEARCH
                    SizedBox(
                      height: 100,
                      width: 400,
                      child: Column(
                        children: [
                          TextField(
                            controller: branchController,
                            decoration: branchSearch,
                            onChanged: (value) =>
                                setState(() => branchQuery = value),
                            textAlign: TextAlign.center,
                            enabled: selectedDealer != null,
                          ),
                          if (branchQuery.isNotEmpty && selectedDealer != null)
                            SizedBox(
                              height: 40,
                              child: SearchListWidget(
                                query: branchQuery,
                                type: SearchType.branch,
                                items: branchSuggestions,
                                onItemSelected: (dealer) {
                                  setState(() {
                                    selectedBranch = dealer;
                                    branchController.text = dealer.branch;
                                    branchCodeController.text =
                                        dealer.branchCode;
                                    coorController.text = dealer.coordinator!;
                                    branchQuery = ''; // <-- hide dropdown
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    //BRANCH CODE SEARCH
                    SizedBox(
                      height: 90,
                      width: 400,
                      child: Column(
                        children: [
                          TextField(
                            controller: branchCodeController,
                            decoration: branchCodeSearch,
                            readOnly: true,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    //COOR SEARCH
                    SizedBox(
                      width: 400,
                      child: TextField(
                        controller: coorController,
                        decoration: coorSearch,
                        readOnly: true,
                        textAlign: TextAlign.center,
                      ),
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

Future<List<Dealer>> fetchDealers(String query) async {
  final url = Uri.parse("http://<SERVER-IP>:5000/branches?search=$query");
  final response = await http.get(url);

  final List data = jsonDecode(response.body);
  return data.map((json) => Dealer.fromJson(json)).toList();
}

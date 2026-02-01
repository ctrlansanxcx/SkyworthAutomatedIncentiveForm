import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:incentivesystem/endpoints/searchdealers.dart';
import 'package:incentivesystem/model/datehelper.dart';
import 'package:incentivesystem/model/dealer.dart';
import 'package:incentivesystem/model/excelholder.dart';
import 'package:incentivesystem/model/quantityholder.dart';
import 'package:incentivesystem/widgets/buttons.dart';
import 'package:incentivesystem/widgets/search_list_widget.dart';
import 'package:incentivesystem/widgets/searchbar.dart';

class InsertQuantity extends StatefulWidget {
  const InsertQuantity({super.key});

  @override
  State<InsertQuantity> createState() => _InsertQuantityPage();
}

class _InsertQuantityPage extends State<InsertQuantity> {
  Dealer? selectedDealer;
  Dealer? selectedBranch;

  PlatformFile? incentiveFormFile;
  PlatformFile? insertQuantity;

  final dealerController = TextEditingController();
  final branchController = TextEditingController();
  final branchCodeController = TextEditingController();
  final coorController = TextEditingController();
  final monthController = TextEditingController();
  final yearController = TextEditingController();
String baseUrl = 'http://192.168.0.110:8000';
  String dealerQuery = '';
  String branchQuery = '';
  String? selectedWorksheet;
  bool _isFetchingSheets = false;
  bool _isSearching = false;

  List<Dealer> dealers = [];
  List<String> quantityWorksheets = [];

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    dealerController.dispose();
    branchController.dispose();
    branchCodeController.dispose();
    coorController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
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

  Future<void> _insertQuantity() async {
    // 1. Validation: Dealer and Branch
    if (selectedDealer == null || selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a dealer and branch")),
      );
      return;
    }

    if (selectedWorksheet == null || selectedWorksheet!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select the quantity worksheet")),
      );
      return;
    }

    // 2. Validation: Files uploaded
    if (incentiveFormFile == null || insertQuantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload both Excel files")),
      );
      return;
    }

    // 3. Validation: Check for file paths (Mandatory for non-web platforms like Windows EXE)
    // We REQUIRE the .path property here for the server to read the file.
    if (insertQuantity!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Error accessing Quantity File path. Please re-upload.",
          ),
        ),
      );
      return;
    }
    if (incentiveFormFile!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Error accessing Incentive File path. Please re-upload.",
          ),
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Processing... Please wait")),
      );

      // 4. Call API - Use validated dealer data and guaranteed file paths
      await callInsertQuantity(
        quantityFile: insertQuantity!.path!,
        incentiveFile: incentiveFormFile!.path!,
        dealer: selectedDealer!.dealer,
        branch: selectedBranch!.branch,
        branchCode: selectedBranch!.branchCode,
        coordinator: selectedBranch!.coordinator!,
        month: monthController.text,
        year: yearController.text,
        sourceSheetName: selectedWorksheet!,
      );

      if (!mounted) return;

      // 5. Show results in AlertDialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Completed Successfully")));
    } catch (e, stackTrace) {
      print("Error: $e\n$stackTrace");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _fetchWorksheets(PlatformFile file) async {
    // 1. START: Set loading state BEFORE the network call
    setState(() {
      _isFetchingSheets = true;
      quantityWorksheets = []; // Clear previous sheets
      selectedWorksheet = null; // Clear previous selection
    });

    try {
      var uri = Uri.parse('$baseUrl/get_worksheets/');
      var request = http.MultipartRequest('POST', uri);

      // 2. Prepare the file data (using bytes is safest for Flutter web/desktop)
      if (file.bytes == null) {
        throw Exception("File bytes not available for upload.");
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'source_file', // Must match the Python parameter name
          file.bytes!,
          filename: file.name,
        ),
      );

      // 3. Send the request and wait for response
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseBody);

        // 4. SUCCESS: Update the state with the real data
        setState(() {
          quantityWorksheets = List<String>.from(data['worksheets']);
        });
      } else {
        // Handle API errors
        var errorData = jsonDecode(responseBody);
        throw Exception(errorData['detail'] ?? 'Failed to fetch worksheets.');
      }
    } catch (e) {
      // 5. ERROR: Show error message
      print("Error fetching worksheets: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Error reading sheet names from file. Please check file format and server connection.",
          ),
        ),
      );
    } finally {
      // 6. END: Stop loading state
      setState(() {
        _isFetchingSheets = false;
      });
    }
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
      appBar: AppBar(title: Text(' ')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(1),
          child: Column(
            children: [
              Image.asset('assets/icons/logo.png', height: 50, width: 400),
              const SizedBox(height: 1),
              const Text(
                'INSERT QUANTITY',
                style: TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: 60,
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Labels Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text(
                          'DEALER',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 30,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: Text(
                          'BRANCH\nCODE',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 30,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 90,
                        width: 250,
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
                                  _performSearch(value);
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 1,
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: 90,
                        width: 250,
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
                    ],
                  ),
                  const SizedBox(width: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text(
                          'BRANCH NAME',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 30,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: Text(
                          'MARKETING\nCOORDINATOR',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 30,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 100,
                        width: 250,
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
                            if (branchQuery.isNotEmpty &&
                                selectedDealer != null)
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
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: coorController,
                          decoration: coorSearch,
                          readOnly: true,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text(
                          'MONTH',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 30,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: Text(
                          'YEAR',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 30,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MonthYearPickerField(
                        controller: monthController,
                        label: 'Select Month',
                        isMonth: true,
                        decoration: yearSearch,
                      ),
                      SizedBox(height: 40),
                      MonthYearPickerField(
                        controller: yearController,
                        label: 'Select Year',
                        isMonth: false,
                        decoration: yearSearch,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text(
                          'WORKSHEET',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 30,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Text(
                          'INCENTIVE FILE',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 30,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 30),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 350,
                        child: ExcelUploadHolder(
                          label:
                              insertQuantity?.name ??
                              "UPLOAD QUANTITY FILE.xlsx",
                          onFilePicked: (file) {
                            setState(() => insertQuantity = file);
                            _fetchWorksheets(file);
                            print("Insert Quantity File: ${file.name}");
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: 350,
                        child: ExcelUploadHolder(
                          label: incentiveFormFile?.name ?? "UPLOAD INCENTIVE FORM.xlsx",
                          onFilePicked: (file) {
                            setState(() => incentiveFormFile = file);
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                        child: Text(
                          '*Utilize the Revised Incentive Form for Branches',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 50),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // WORKSHEET DROPDOWN
                      SizedBox(
                        height: 70,
                        width: 400,
                        child: _isFetchingSheets
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  hintText: 'Select Worksheet',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0068B7),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0068B7),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0068B7),
                                      width: 0.5,
                                    ),
                                  ),

                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                ),
                                value: selectedWorksheet,
                                hint: const Text(
                                  'Select Worksheet',
                                  textAlign: TextAlign.center,
                                ),
                                items: quantityWorksheets
                                    .map(
                                      (sheetName) => DropdownMenuItem(
                                        value: sheetName,
                                        child: Text(sheetName),
                                      ),
                                    )
                                    .toList(),
                                onChanged: quantityWorksheets.isEmpty
                                    ? null
                                    : (String? newValue) {
                                        setState(() {
                                          selectedWorksheet = newValue;
                                        });
                                      },
                                disabledHint: insertQuantity == null
                                    ? const Text('Upload Quantity File First')
                                    : const Text('No worksheets found/Error'),
                                isExpanded: true,
                              ),
                      ),

                      const SizedBox(height: 25),
                      SizedBox(
                        height: 50,
                        width: 400,
                        child: ElevatedButton(
                          style: uploadStyle,
                          // Disable INSERT button if file not uploaded or sheet not selected
                          onPressed:
                              (insertQuantity == null ||
                                  selectedWorksheet == null)
                              ? null
                              : _insertQuantity,
                          child: const Text('INSERT'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

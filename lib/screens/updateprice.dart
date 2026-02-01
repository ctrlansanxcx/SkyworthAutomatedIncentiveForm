import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:incentivesystem/endpoints/searchdealers.dart';
import 'package:incentivesystem/model/datehelper.dart';
import 'package:incentivesystem/model/dealer.dart';
import 'package:incentivesystem/model/excelholder.dart';
import 'package:incentivesystem/widgets/buttons.dart';
import 'package:incentivesystem/widgets/search_list_widget.dart';
import 'package:incentivesystem/widgets/searchbar.dart';
import 'package:incentivesystem/model/priceholder.dart';

class Updateprice extends StatefulWidget {
  const Updateprice({super.key});

  @override
  State<Updateprice> createState() => _UpdatepriceState();
}

class _UpdatepriceState extends State<Updateprice> {
  Dealer? selectedDealer; // Selected dealer
  Dealer? selectedBranch; // Selected branch

  PlatformFile? incentiveFormFile;
  PlatformFile? updatePriceFile;

  final dealerController = TextEditingController();
  final branchController = TextEditingController();
  final branchCodeController = TextEditingController();
  final coorController = TextEditingController();

  // FIX: Moved to class scope so _processPriceUpdate can access them
  final TextEditingController monthController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
String baseUrl = 'http://192.168.0.110:8000';
  String dealerQuery = '';
  String branchQuery = '';
  String? selectedWorksheet;
  bool _isFetchingSheets = false;
  bool _isSearching = false;

  List<Dealer> dealers = [];
  List<String> incentiveLogs = [];
  List<String> updateLogs = [];
  List<String> quantityWorksheets = [];
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

  Future<void> _processPriceUpdate() async {
    // 1. Get Dealer, Month, and Year values
    final dealerName = selectedDealer?.dealer;
    final month = monthController.text;
    final year = yearController.text;

    // 2. Validation Checks (Essential to prevent crashes)
    if (selectedDealer == null || dealerName == null || dealerName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a dealer')));
      return;
    }

    if (incentiveFormFile == null || updatePriceFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both Excel files')),
      );
      return;
    }

    if (month.isEmpty || year.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Month and Year')),
      );
      return;
    }

    if (selectedWorksheet == null || selectedWorksheet!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a worksheet from the Price File'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Processing update...')));

    try {
      // 3. CORRECTED API CALL with all FIVE arguments
      final logs = await callUpdatePrice(
        updatePriceFile!.path!, // 1. Source (Update Price)
        incentiveFormFile!.path!, // 2. Target (Incentive Form)
        dealerName, // 3. Dealer Name
        month, // 4. Month
        year, // 5. Year
        selectedWorksheet!, // 🎯 NEW: Worksheet name
      );

      setState(() {
        updateLogs = logs;
        incentiveLogs = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update Completed Successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
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

      // 2. Prepare the file data
      if (file.bytes == null) {
        // Handle the case where bytes are not available
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
          // This receives the actual list of sheets from Python
          quantityWorksheets = List<String>.from(data['worksheets']);
        });
      } else {
        // Handle API errors (e.g., Python returned an error code)
        var errorData = jsonDecode(responseBody);
        throw Exception(errorData['detail'] ?? 'Failed to fetch worksheets.');
      }
    } catch (e) {
      // 5. ERROR: Show error message
      print("Error fetching worksheets: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error reading sheet names from file. Please check file format and server connection.",
          ),
        ),
      );
    } finally {
      // 6. END: Stop loading state regardless of success or failure
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
    // FIX: Removed the redundant local declarations of monthController and yearController here.
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Column(
              children: [
                Image.asset('assets/icons/logo.png', height: 50, width: 400),
                const SizedBox(height: 1),
                const Text(
                  'UPDATE INCENTIVE FORM',
                  style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 60,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Dealer / Month / Year Row
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
                          padding: EdgeInsets.only(top: 60),
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
                          padding: EdgeInsets.only(top: 20),
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

                    const SizedBox(width: 50),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 90,
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
                                    _performSearch(
                                      value,
                                    ); // fetch dealers from API
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
                        const SizedBox(height: 15),
                        MonthYearPickerField(
                          controller: monthController,
                          label: 'Select Month',
                          isMonth: true,
                          decoration: yearSearch1, // normal month style
                        ),
                        SizedBox(height: 15),

                        MonthYearPickerField(
                          controller: yearController,
                          label: 'Select Year',
                          isMonth: false,
                          decoration: yearSearch1, // alternate year style
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // UPLOAD INCENTIVE FORM
                    SizedBox(
                      width: 350,
                      child: ExcelUploadHolder(
                        label: incentiveFormFile?.name ?? "UPLOAD INCENTIVE FORM.xlsx",
                        onFilePicked: (file) {
                          setState(() => incentiveFormFile = file);
                          
                        },
                      ),
                    ),

                    const SizedBox(width: 40),

                    // UPLOAD UPDATED PRICE
                    SizedBox(
                      width: 350,
                      child: ExcelUploadHolder(
                        label:
                            updatePriceFile?.name ?? "UPLOAD PRICE FILE.xlsx",
                        onFilePicked: (file) {
                          setState(() => updatePriceFile = file);
                          // <<< NEW LINE HERE >>>
                          _fetchWorksheets(file);
                          print("Insert Price File: ${file.name}");
                        },
                      ),
                    ),
                    SizedBox(width: 40),

                    SizedBox(
                      width: 400,
                      child: _isFetchingSheets
                          ? const Center(
                              child: CircularProgressIndicator(),
                            ) // Show loading
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
                                  ? null // Disabled if list is empty
                                  : (String? newValue) {
                                      setState(() {
                                        selectedWorksheet = newValue;
                                      });
                                    },
                              disabledHint: updatePriceFile == null
                                  ? const Text('Upload Quantity File First')
                                  : const Text('No worksheets found/Error'),
                              isExpanded: true,
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: 400,
                  child: ElevatedButton(
                    style: uploadStyle,
                    // Disable INSERT button if file not uploaded or sheet not selected
                    onPressed: (selectedWorksheet == null)
                        ? null
                        : _processPriceUpdate,
                    child: Text('INSERT'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

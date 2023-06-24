import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SplitPdfPage extends StatefulWidget {
  const SplitPdfPage({Key? key}) : super(key: key);

  @override
  State<SplitPdfPage> createState() => _SplitPdfPageState();
}

class _SplitPdfPageState extends State<SplitPdfPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  File? selectedFile;
  bool isLoading = false;
  int? startPage;
  int? endPage;
  String? errorMessage;

  Future<void> splitPDF() async {
    if (selectedFile == null) {
      print('No file selected.');
      return;
    }
    if (startPage == null || endPage == null) {
      print('Invalid start page or end page.');
      return;
    }
    if (startPage! > endPage!) {
      setState(() {
        errorMessage =
            'Invalid page range. Start page must be less than or equal to end page.';
      });
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    String apiUrl = 'http://192.168.0.155:3000/api/split';
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    var bytes = await selectedFile!.readAsBytes();
    print(startPage);
    print(endPage);
    request.fields['startPage'] = startPage.toString();
    request.fields['endPage'] = endPage.toString();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: selectedFile!.path.split('/').last,
      contentType: MediaType('application', 'pdf'),
    ));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final filePath = '${appDocDir.path}/Split.pdf';
        var file = File(filePath);
        await response.stream.pipe(file.openWrite());
        print('File saved at: ${file.path}');
        setState(() {
          isLoading = false;
        });
        downloadSplitFile(file);
      } else {
        print('Failed to split PDF. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('An error occurred while splitting PDF: $error');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = File(result.files.first.path!);
      });
    }
  }

  Future<void> downloadSplitFile(File file) async {
    final savedFile = await file.copy('${file.path}_downloaded.pdf');
    print('File downloaded at: ${savedFile.path}');

    // Show file preview
    OpenFile.open(savedFile.path).then((result) {
      if (result.type == ResultType.done ||
          result.type == ResultType.noAppToOpen) {
        // Display notification
        showNotification('File Downloaded', 'Tap to preview the file');
      } else {
        // File preview failed
        print('Failed to open file for preview');
      }
    });
  }

  Future<void> showNotification(String title, String body) async {
    const iOSPlatformChannelSpecifics = IOSNotificationDetails();
    const platformChannelSpecifics = NotificationDetails(
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Split PDF'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Select PDF File to Split',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: selectFile,
              child: Text('Select File'),
            ),
            if (selectedFile != null) ...[
              SizedBox(height: 16.0),
              Text(
                'Selected File: ${selectedFile!.path.split('/').last}',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 16.0),
              NumberPicker(
                labelText: 'Start Page',
                value: startPage,
                onChanged: (value) {
                  setState(() {
                    startPage = value;
                  });
                },
              ),
              SizedBox(height: 8.0),
              NumberPicker(
                labelText: 'End Page',
                value: endPage,
                onChanged: (value) {
                  setState(() {
                    endPage = value;
                  });
                },
              ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: isLoading ? null : splitPDF,
                child:
                    isLoading ? CircularProgressIndicator() : Text('Split PDF'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NumberPicker extends StatefulWidget {
  final String labelText;
  final int? value;
  final ValueChanged<int>? onChanged;

  NumberPicker({required this.labelText, this.value, this.onChanged});

  @override
  _NumberPickerState createState() => _NumberPickerState();
}

class _NumberPickerState extends State<NumberPicker> {
  late TextEditingController controller;
  late int selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.value ?? 1;
    controller = TextEditingController(text: selectedValue.toString());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              setState(() {
                if (selectedValue > 1) {
                  selectedValue--;
                  controller.text = selectedValue.toString();
                  widget.onChanged?.call(selectedValue);
                }
              });
            },
          ),
          SizedBox(
            width: 8.0,
          ),
          Container(
            width: 150.0,
            child: TextFormField(
              showCursor: true,
              enableInteractiveSelection: false,
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: widget.labelText,
              ),
              onChanged: (value) {
                setState(() {
                  selectedValue = int.tryParse(value) ?? selectedValue;
                  widget.onChanged?.call(selectedValue);
                });
              },
            ),
          ),
          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                selectedValue++;
                controller.text = selectedValue.toString();
                widget.onChanged?.call(selectedValue);
              });
            },
          ),
        ],
      ),
    );
  }
}

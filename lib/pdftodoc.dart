import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class PdftodocxPage extends StatefulWidget {
  const PdftodocxPage({Key? key}) : super(key: key);

  @override
  State<PdftodocxPage> createState() => _PdftodocxPagePageState();
}

class _PdftodocxPagePageState extends State<PdftodocxPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  File? selectedFile;
  bool isLoading = false;
  String? errorMessage;

  Future<void> compressPDF() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String apiUrl = 'http://192.168.0.155:3000/api/pdftodocx';

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    var bytes = await selectedFile!.readAsBytes();

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: selectedFile!.path.split('/').last,
      contentType: MediaType('application', 'pdf'),
    ));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        print('convert to docx');
        final appDocDir = await getApplicationDocumentsDirectory();
        final filePath = '${appDocDir.path}/document.docx';
        var file = File(filePath);
        await response.stream.pipe(file.openWrite());
        print('File saved at: ${file.path}');
        // Handle the compressed PDF file as desired
        downloadSplitFile(file);
      } else {
        print('Failed to compress PDF. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('An error occurred while compressing PDF: $error');
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
    final savedFile = await file.copy('${file.path}_downloaded.docx');
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
        title: const Text('PDF TO DOC'),
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
                'Select PDF File to DOC',
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
                onPressed: isLoading ? null : compressPDF,
                child: isLoading
                    ? CircularProgressIndicator()
                    : Text('PDF To Doc'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

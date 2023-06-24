import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MergePdfPage extends StatefulWidget {
  const MergePdfPage({Key? key}) : super(key: key);

  @override
  State<MergePdfPage> createState() => _MergePdfPageState();
}

class _MergePdfPageState extends State<MergePdfPage> {
  List<File> selectedFiles = [];
  bool isLoading = false;
  String drawerText = "Default Text";
  bool isMerged = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    // Initialize the notification plugin
    final initializationSettingsIOS =
        IOSInitializationSettings(onDidReceiveLocalNotification: null);
    final initializationSettings =
        InitializationSettings(iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<File> saveFileToDocumentDirectory(String data) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDocDir.path}/merged_file.pdf';
    final file = File(filePath);
    await file.writeAsBytes(data.codeUnits);
    return file;
  }

  Future<void> mergePDFs() async {
    setState(() {
      isLoading = true;
    });

    String apiUrl = 'http://192.168.0.155:3000/api/merge';

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    for (var file in selectedFiles) {
      var bytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'files',
        bytes,
        filename: path.basename(file.path),
        contentType: MediaType('application', 'pdf'),
      ));
    }

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final filePath = '${appDocDir.path}/merged_file.pdf';
        var file = File(filePath);
        await response.stream.pipe(file.openWrite());
        print('File saved at: ${file.path}');
        setState(() {
          isMerged = true;
          selectedFiles.clear();
        });
        downloadMergedFile();
      } else {
        print('Failed to merge PDFs. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('An error occurred while merging PDFs: $error');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> selectFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFiles.addAll(result.files.map((file) => File(file.path!)));
      });
    }
  }

  void deleteFile(File file) {
    setState(() {
      selectedFiles.remove(file);
    });
  }

  void updateDrawerText(String value) {
    setState(() {
      drawerText = value;
    });
  }

  void downloadMergedFile() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDocDir.path}/merged_file.pdf';
    var file = File(filePath);

    if (await file.exists()) {
      final savedFile =
          await file.copy('${appDocDir.path}/merged_file_downloaded.pdf');
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
    } else {
      print('Merged file does not exist.');
    }
  }

  Future<void> showNotification(String title, String body) async {
    const iOSPlatformChannelSpecifics = IOSNotificationDetails();
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Widget buildUploadedFileItem(File file) {
    return Card(
      child: ListTile(
        title: Text(
          file.path.split('/').last,
          style: TextStyle(fontSize: 16.0),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => deleteFile(file),
        ),
      ),
    );
  }

  Widget buildUploadedFilesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Uploaded Files:',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        ListView.builder(
          shrinkWrap: true,
          itemCount: selectedFiles.length,
          itemBuilder: (context, index) {
            return buildUploadedFileItem(selectedFiles[index]);
          },
        ),
      ],
    );
  }

  Widget buildAddFilesButton() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.add),
        title: const Text(
          'Add Additional Files',
          style: TextStyle(fontSize: 16.0),
        ),
        onTap: selectFiles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Merge Pdf'),
        backgroundColor: Colors.deepPurpleAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.deepPurpleAccent,
              ),
              child: Text(
                drawerText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: TextFormField(
                initialValue: drawerText,
                onChanged: (value) => updateDrawerText(value),
                decoration: const InputDecoration(
                  labelText: 'Edit Drawer Text',
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Select Files",
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: selectFiles,
              child: Text('Select Files'),
            ),
            SizedBox(height: 16.0),
            if (selectedFiles.isNotEmpty && !isMerged) buildUploadedFilesList(),
            if (selectedFiles.isNotEmpty || !isMerged) buildAddFilesButton(),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: selectedFiles.isEmpty || isLoading
                  ? null
                  : () {
                      if (isMerged) {
                        mergePDFs();
                      }
                    },
              child: isLoading
                  ? CircularProgressIndicator()
                  : isMerged
                      ? Text('Merge PDFs')
                      : Text('Merge PDFs'),
            ),
          ],
        ),
      ),
    );
  }
}

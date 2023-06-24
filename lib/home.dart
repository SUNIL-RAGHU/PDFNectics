import 'package:flutter/material.dart';
import 'package:pdfsshub/SplitPdfPage.dart';
import 'package:pdfsshub/pdftodoc.dart';
import 'package:pdfsshub/widgets/Griditem.dart';

import 'compressPdfPage.dart';

import 'doctopdf.dart';
import 'mergepdfpage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _Homepagestate createState() => _Homepagestate();
}

class _Homepagestate extends State<Homepage> {
  TextEditingController editingController = TextEditingController();

  List<String> pdftypes = [
    "Merge Pdf",
    "Split Pdf",
    "Compress Pdf",
    "Pdf to Doc",
    "DOC to Pdf",
    "Remove Pdf WaterMark"
  ];
  List<String> items = [];
  @override
  void initState() {
    items.addAll(pdftypes);
    super.initState();
  }

  void filterSearchResults(String query) {
    query = query.toLowerCase();
    List<String> dummySearchList = [];
    dummySearchList.addAll(pdftypes);
    if (query.isNotEmpty) {
      List<String> dummyListData = [];
      for (String item in dummySearchList) {
        String check = item.toLowerCase();
        if (check.contains(query)) {
          dummyListData.add(item);
        }
      }
      setState(() {
        items.clear();
        items.addAll(dummyListData);
      });
      return;
    } else {
      setState(() {
        items.clear();
        items.addAll(dummySearchList);
      });
    }
  }

  void _navigateToPage(String item) {
    switch (item) {
      case "Merge Pdf":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MergePdfPage(),
          ),
        );
        break;
      case "Split Pdf":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SplitPdfPage(),
          ),
        );
      case "Compress Pdf":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CompressPdfPage(),
          ),
        );

      case "Pdf to Doc":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PdftodocxPage(),
          ),
        );
      case "DOC to Pdf":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DocxtopdfPage(),
          ),
        );
      // case "Doc to pdf":
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) => DoctoPdfPage(),
      //     ),
      //   );
      // case "Remove pdf WaterMark":
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) => RemoveWatermarkPdfPage(),
      //     ),
      //   );

      // Add cases for other items and their respective page classes
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Home',
          style: TextStyle(fontSize: 20),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    onChanged: (value) {
                      filterSearchResults(value);
                    },
                    controller: editingController,
                    decoration: const InputDecoration(
                      hintText: "Search",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const ScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 7 / 8,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: items.length,
                    itemBuilder: (BuildContext ctx, index) {
                      String key = items[index];
                      return Hero(
                        tag: key,
                        child: Material(
                          color: Colors.transparent,
                          child: GestureDetector(
                            onTap: () {
                              _navigateToPage(key);
                            },
                            child: GridItem(
                              text: key,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class GridItem extends StatefulWidget {
  final String text;

  const GridItem({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  _GridItemState createState() => _GridItemState();
}

class _GridItemState extends State<GridItem> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 236, 232, 232), // Change the card color
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onHover: (value) {},
        child: Center(
          child: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black, // Change the text color
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

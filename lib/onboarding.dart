// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:pdfsshub/home.dart';

class OnBoarding extends StatefulWidget {
  const OnBoarding({super.key});

  @override
  _OnBoardingState createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  int currentPageValue = 0;
  int previousPageValue = 0;
  PageController? controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: currentPageValue);
  }

  Widget _indicator(bool isActive) {
    return AnimatedOpacity(
      opacity: (_page == 2) ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        height: 8.0,
        width: isActive ? 24.0 : 16.0,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFF7B51D3),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    final List<Widget> onBoardingWidgets = [
      IntroWidget(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        image: 'assets/images/onboarding1.png',
        type: "Hey!👋🏻",
        startGradientColor: Theme.of(context).colorScheme.secondary,
        endGradientColor: const Color.fromARGB(255, 32, 7, 7),
        subText: "",
      ),
      IntroWidget(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        // image: 'assets/images/onboarding2.png',
        type: 'Call Now📞',
        startGradientColor: Theme.of(context).colorScheme.secondary,
        endGradientColor: const Color.fromARGB(255, 0, 0, 0),
        subText: "",
      ),
      IntroWidget(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        // image: 'assets/images/onboarding3.png',
        type: 'Connect Easily🤙🏻',
        startGradientColor: Theme.of(context).colorScheme.secondary,
        endGradientColor: const Color.fromARGB(255, 25, 3, 3),
        subText: "",
      ),
    ];

    List<Widget> _buildPageIndicator() {
      List<Widget> list = [];
      for (int i = 0; i < onBoardingWidgets.length; i++) {
        list.add(i == _page ? _indicator(true) : _indicator(false));
      }
      return list;
    }

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  stops: [0.1, 0.9],
                  colors: [Colors.white, Colors.white])),
          child: Stack(
            alignment: AlignmentDirectional.bottomCenter,
            children: <Widget>[
              PageView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: onBoardingWidgets.length,
                onPageChanged: (int page) {
                  setState(() {
                    _page = page;
                  });
                },
                controller: controller,
                itemBuilder: (context, index) {
                  return onBoardingWidgets[index];
                },
              ),
              Align(
                alignment: Alignment.topRight,
                child: AnimatedOpacity(
                  opacity: (_page == 2) ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                  child: TextButton(
                      onPressed: () {
                        _page = 2;
                        controller!.animateToPage(_page,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.ease);
                      },
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                        // style: Theme.of(context).textTheme.headline4,
                      )),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildPageIndicator(),
                  ),
                  SizedBox(
                    height: screenHeight * 0.03,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedOpacity(
                        opacity: (_page == 2) ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.fastOutSlowIn,
                        child: TextButton(
                          onPressed: () async {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Homepage()));
                          },
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: screenHeight * 0.05,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IntroWidget extends StatelessWidget {
  const IntroWidget(
      {Key? key,
      required this.screenWidth,
      required this.screenHeight,
      this.image,
      this.type,
      this.startGradientColor,
      this.endGradientColor,
      this.subText})
      : super(key: key);

  final double screenWidth;
  final double screenHeight;
  final image;
  final type;
  final Color? startGradientColor;
  final Color? endGradientColor;
  final String? subText;

  @override
  Widget build(BuildContext context) {
    final Shader linearGradient = LinearGradient(
      colors: <Color>[startGradientColor!, endGradientColor!],
    ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

    return Container(
      padding: const EdgeInsets.only(top: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Image.asset(
            image,
            width: screenWidth * 0.8,
            height: screenHeight * 0.6,
            fit: BoxFit.contain,
          ),
          Container(
            padding: const EdgeInsets.only(left: 12),
            child: Stack(
              alignment: AlignmentDirectional.bottomStart,
              children: <Widget>[
                Opacity(
                  opacity: 0.10,
                  child: SizedBox(
                    height: screenHeight * 0.10,
                    child: Text(
                      type.toString().toUpperCase(),
                      style: TextStyle(
                          fontSize: 65.0,
                          fontFamily: 'Alata',
                          fontWeight: FontWeight.w900,
                          foreground: Paint()..shader = linearGradient),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -3,
                  left: 10,
                  child: Text(
                    type.toString().toUpperCase(),
                    style: TextStyle(
                        fontSize: 40.0,
                        fontFamily: 'Alata',
                        fontWeight: FontWeight.w900,
                        foreground: Paint()..shader = linearGradient),
                  ),
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              subText!,
              style: const TextStyle(
                  fontWeight: FontWeight.w300,
                  color: Color.fromARGB(255, 26, 10, 10),
                  letterSpacing: 1.0),
            ),
          )
        ],
      ),
    );
  }

  TextStyle buildTextStyle(double size) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      height: 0.5,
    );
  }
}

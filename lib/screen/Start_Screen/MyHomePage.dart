import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/app_screen/HomeScreen.dart';
import 'package:flutter_application_1/screen/app_screen/Quetione.dart';

class Myhomepage extends StatefulWidget {
  const Myhomepage({super.key});

  @override
  State<Myhomepage> createState() => _MyhomepageState();
}
final nevigationKey=GlobalKey<CurvedNavigationBarState>();
int index=0;
final Screen=[
  Homescreen(),
  QuestionScreen()
 
];
final items=[
  Icon(Icons.home,size:30),
  Icon(Icons.question_mark,size:30),
 
];

class _MyhomepageState extends State<Myhomepage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,

      child: Scaffold(
        body: Center(
          child: Screen[index],
        ),
        extendBody: true,
       bottomNavigationBar:Theme(data: Theme.of(context).copyWith(
        iconTheme: IconThemeData(color: Colors.black),
        ),child:CurvedNavigationBar(
        color: Colors.white,
        buttonBackgroundColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      height:  60,
      key: nevigationKey,
      animationCurve: Curves.easeInOut,
      animationDuration: Duration(milliseconds: 300),
      index: index,
      items: items,
      onTap: (newIndex) => setState(() {
              index = newIndex;
        
      
  })
      )
      ),
    )
    );
  }
}
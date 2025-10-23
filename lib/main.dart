import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/Start_Screen/on_boarding_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/screen/Start_Screen/MyHomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool('seenOnboarding') ?? false;

  runApp(MyApp(seen: seen));
}

class MyApp extends StatelessWidget {
  final bool seen;
  const MyApp({required this.seen, super.key});

@override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) =>
      MaterialApp(
        debugShowCheckedModeBanner: false,
        
        home: seen ? Myhomepage() : OnBoardingScreen(),
      ),
    );
  }
}

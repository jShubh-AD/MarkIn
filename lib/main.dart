import 'package:attendence/user/register/presentation/student_register.dart';
import 'package:attendence/user/signin/signin_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Homepage/student_dashboard.dart';
import 'Homepage/teacher_dashboard.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final role = prefs.getString('role');

  runApp(MyApp(
    isLoggedIn: isLoggedIn && role != null,
    role: role ?? '',));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.isLoggedIn, required this.role});

  final bool isLoggedIn;
  final String role;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: //SignInPage()//RegisterStudent()
        isLoggedIn
          ? (role == 'student' ? StudentDashboard() : TeacherDashboard())
          : SignInPage(),
    );
  }
}


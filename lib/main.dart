import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_attendence_app/attendancedetails.dart';
import 'package:flutter_attendence_app/cgpa_calculator.dart';
import 'package:flutter_attendence_app/firebase_api.dart';
import 'package:flutter_attendence_app/firebase_options.dart';
import 'package:flutter_attendence_app/gpa_calculator.dart';
import 'package:flutter_attendence_app/help_page.dart';
import 'package:flutter_attendence_app/homepage.dart';
import 'package:flutter_attendence_app/logo.dart';
import 'package:flutter_attendence_app/loginpage.dart';
import 'package:flutter_attendence_app/attendance.dart';
import 'package:flutter_attendence_app/odrequestpage.dart';
import 'package:flutter_attendence_app/profile_page.dart';
import 'package:flutter_attendence_app/timetable_page.dart';
import 'package:flutter_attendence_app/attendancemark.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize the NotificationService
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase
  await FirebaseApi().initNotifications(); // Initialize Firebase Messaging

  // Retrieve the user's role from SharedPreferences
  final isStaff = await getUserRole();

  runApp(MyApp(isStaff: isStaff));
}

Future<bool> getUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isStaff') ?? false; // Default to false (student)
}

class MyApp extends StatelessWidget {
  final bool isStaff;

  const MyApp({super.key, required this.isStaff});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/logopage', // Ensure this route exists
      routes: {
        '/logopage': (context) => const LogoPage(),
        '/loginpage': (context) => const LoginPage(),
        '/homepage':
            (context) => HomePage(
              name: 'Default Name',
              email: 'default@example.com',
              profile: {'key': 'Default Profile'},
              isStaff: isStaff, // Pass the retrieved role dynamically
            ),
        '/attendancepage': (context) => const AttendanceSelectionPage(),
        '/attendancemark': (context) => const AttendanceScreen(),
        '/attendancedetails':
            (context) => AttendanceDetailsScreen(
              department:
                  'Default Department', // Provide a default or dynamic value
              year: 'Default Year', // Provide a default or dynamic value
              section: 'Default Section', // Provide a default or dynamic value
              presentStudents: [],
              absentStudents: [],
              onDutyStudents: [],
              onEdit: (Map<String, bool> updatedAttendance) {
                // Add your onEdit logic here
                print(updatedAttendance);
              },
            ),
        '/cgpaCalculator': (context) => const CgpaCalculatorPage(),
        '/profilepage': (context) => const ProfilePage(),
        '/gpaCalculator': (context) => const GPACalculatorPage(),
        '/help': (context) => const HelpPage(),
        '/timetablepage': (context) => TimetablePage(),
        '/odrequestpage': (context) => const ODRequestPage(),
      },
    );
  }
}

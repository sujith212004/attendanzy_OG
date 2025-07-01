import 'package:flutter/material.dart';
import 'package:flutter_attendence_app/AnimatedHeader.dart';
import 'package:flutter_attendence_app/UserDetailsPage.dart';
import 'package:flutter_attendence_app/categoryCard.dart';
import 'package:flutter_attendence_app/help_page.dart';
import 'package:flutter_attendence_app/absentees_page.dart';
import 'package:flutter_attendence_app/odrequestadminpage.dart';
import 'package:flutter_attendence_app/odrequestpage.dart'; // <-- Create this page for staff
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  final String name;
  final String email;
  final Map<String, dynamic> profile;
  final bool isStaff;

  const HomePage({
    super.key,
    required this.name,
    required this.email,
    required this.profile,
    required this.isStaff,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A73E8),
        title: Text(
          isStaff ? 'Admin Dashboard' : 'Student Dashboard',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AnimatedHeader(name: name),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CategoryCard(
                          title: isStaff ? 'Mark Attendance' : 'Absentees',
                          icon:
                              isStaff
                                  ? Icons.check_circle_outline
                                  : Icons.people_alt_outlined,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF34A853), Color(0xFF81C784)],
                          ),
                          onTap: () {
                            if (isStaff) {
                              Navigator.pushNamed(context, '/attendancepage');
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AbsenteesPage(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CategoryCard(
                          title: 'Profile',
                          icon: Icons.person_outline,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF009688), Color(0xFF4DB6AC)],
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/profilepage');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: CategoryCard(
                          title: 'Result',
                          icon: Icons.school,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                          ),
                          onTap: () async {
                            const url = 'https://coe.act.edu.in/students/';
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              throw 'Could not launch $url';
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CategoryCard(
                          title: 'Time Table',
                          icon: Icons.schedule,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFA000), Color(0xFFFFC107)],
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/timetablepage');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: CategoryCard(
                          title: 'CGPA Calculator',
                          icon: Icons.calculate,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8E24AA), Color(0xFFBA68C8)],
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/cgpaCalculator');
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CategoryCard(
                          title: 'GPA Calculator',
                          icon: Icons.calculate_outlined,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/gpaCalculator');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpPage()),
          );
        },
        backgroundColor: const Color(0xFF1A73E8),
        child: const Icon(Icons.help_outline),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1A73E8),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            // Home tab selected
          } else if (index == 1) {
            // OD tab pressed: Only students can request, staff see requests
            if (isStaff) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const ODRequestsAdminPage(), // <-- Staff view
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => const ODRequestPage(), // <-- Student view
                ),
              );
            }
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserDetailsPage(name: name, email: email),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'OD',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
        ],
      ),
    );
  }
}

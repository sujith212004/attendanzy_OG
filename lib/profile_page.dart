import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? studentData;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');

    if (email != null) {
      try {
        final db = await mongo.Db.create(
          'mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB',
        );
        await db.open();

        final collection = db.collection('profile');
        final student = await collection.findOne({"College Email": email});

        await db.close();

        setState(() {
          studentData = student;
        });
      } catch (e) {
        print('Error fetching student data: $e');
      }
    } else {
      print('No email found in SharedPreferences');
    }
  }

  Future<void> updateImageInDatabase(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email != null) {
        final db = await mongo.Db.create(
          'mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB',
        );
        await db.open();

        final collection = db.collection('profile');
        await collection.updateOne({
          "College Email ": email,
        }, mongo.modify.set('Photo', imagePath));

        await db.close();
        print('Image updated successfully in MongoDB');
      }
    } catch (e) {
      print('Error updating image in MongoDB: $e');
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imagePath = pickedFile.path;

      // Update the image in MongoDB
      await updateImageInDatabase(imagePath);

      // Fetch the updated data to reflect changes
      await fetchStudentData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: const Color(0xFF1A73E8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body:
          studentData == null
              ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.blueAccent,
                  size: 50,
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Stack(
                      children: [
                        Container(
                          height:
                              300, // Increased height to accommodate name and email
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 50,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              // Name
                              Text(
                                studentData?['Name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              // Email
                              Text(
                                studentData?['College Email'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  // Profile Picture
                                  CircleAvatar(
                                    radius: 70,
                                    backgroundImage: _getImageProvider(
                                      studentData?['Photo'] as String?,
                                    ),
                                    backgroundColor: Colors.white,
                                  ),
                                  // Floating Action Button for Editing
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: pickImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 20,
                                          color: Color(0xFF1A73E8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Details Section
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text(
                            'Student Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A73E8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildProfileCard(
                            'Register Number',
                            studentData?['Register no']?.toString() ?? 'N/A',
                          ),
                          _buildProfileCard(
                            'Department',
                            studentData?['Department'] ?? 'N/A',
                          ),
                          _buildProfileCard(
                            'Section',
                            studentData?['Section'] ?? 'N/A',
                          ),
                          _buildProfileCard(
                            'Year',
                            studentData?['Year'] ?? 'N/A',
                          ),
                          _buildProfileCard(
                            'DOB',
                            studentData?['DOB'] ?? 'N/A',
                          ),
                          _buildProfileCard(
                            'Blood Group',
                            studentData?['Blood Group'] ?? 'N/A',
                          ),
                          _buildProfileCard(
                            'Mother\'s Name',
                            studentData?['Mother\'s Name'] ?? 'N/A',
                          ),
                          _buildProfileCard(
                            'Mother\'s Occupation',
                            studentData?['Mother\'s Occupation'] ?? 'N/A',
                          ),
                          _buildProfileCard(
                            'Father\'s Name',
                            studentData?['Father\'s Name'] ?? 'N/A',
                          ),
                          _buildProfileCard(
                            'Father\'s Occupation',
                            studentData?['Father\'s Occupation'] ?? 'N/A',
                          ),
                          _buildProfileCard(
                            'Address',
                            studentData?['Address'] ?? 'N/A',
                          ),
                          _buildProfileCard(
                            'Phone No',
                            studentData?['Phone no']?.toString() ?? 'N/A',
                          ),
                          _buildProfileCard(
                            'Parent Contact',
                            studentData?['Parent Contact']?.toString() ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String? photo) {
    if (photo == null || photo.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    }

    if (photo.startsWith('http') || photo.startsWith('https')) {
      return NetworkImage(photo);
    } else if (photo.startsWith('file://') || File(photo).existsSync()) {
      return FileImage(File(photo));
    } else {
      return const AssetImage('assets/placeholder.png');
    }
  }
}

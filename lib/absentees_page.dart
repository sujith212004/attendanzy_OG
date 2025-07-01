import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AbsenteesPage extends StatefulWidget {
  const AbsenteesPage({super.key});

  @override
  State<AbsenteesPage> createState() => _AbsenteesPageState();
}

class _AbsenteesPageState extends State<AbsenteesPage> {
  final String mongoUri =
      "mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB";
  final String collectionName = "absentees";

  Map<String, List<Map<String, dynamic>>> groupedAbsentees = {};
  Map<String, GlobalKey> letterKeys = {};

  DateTime selectedDate = DateTime.now();
  ScrollController scrollController = ScrollController();

  final List<Color> avatarColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.indigo,
  ];

  String? selectedLetter;
  bool isLoading = true; // Added loading state

  @override
  void initState() {
    super.initState();
    fetchAbsentees();
  }

  Future<void> fetchAbsentees() async {
    try {
      setState(() {
        isLoading = true; // Show loading animation
      });

      final db = await mongo.Db.create(mongoUri);
      await db.open();
      final collection = db.collection(collectionName);

      final data = await collection.findOne({
        "date": {
          r"$gte":
              DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
              ).toIso8601String(),
          r"$lt":
              DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day + 1,
              ).toIso8601String(),
        },
      });

      if (data != null && data['absentees'] != null) {
        List<Map<String, dynamic>> absentees = List<Map<String, dynamic>>.from(
          data['absentees'],
        );

        Map<String, List<Map<String, dynamic>>> grouped = {};
        for (var absentee in absentees) {
          String firstLetter = (absentee['name'] ?? 'Unknown')[0].toUpperCase();
          grouped.putIfAbsent(firstLetter, () => []).add(absentee);
        }

        setState(() {
          groupedAbsentees = grouped;
          letterKeys = {for (var letter in grouped.keys) letter: GlobalKey()};
        });
      } else {
        setState(() {
          groupedAbsentees = {};
          letterKeys = {};
        });
      }

      await db.close();
    } catch (e) {
      print("Error fetching absentees: $e");
    } finally {
      setState(() {
        isLoading = false; // Hide loading animation
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchAbsentees();
    }
  }

  Color _getColorForLetter(String letter) {
    int index = letter.codeUnitAt(0) % avatarColors.length;
    return avatarColors[index];
  }

  void _scrollToLetter(String letter) {
    final key = letterKeys[letter];
    if (key != null) {
      final context = key.currentContext;
      if (context != null) {
        setState(() {
          selectedLetter = letter;
        });
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Widget buildLoadingAnimation() {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: Colors.blueAccent,
        size: 50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> sortedLetters = List.generate(
      26,
      (i) => String.fromCharCode(65 + i),
    ); // A-Z

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Absentees List",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body:
          isLoading
              ? buildLoadingAnimation() // Show loading animation while fetching data
              : groupedAbsentees.isEmpty
              ? const Center(
                child: Text(
                  "No absentees found for the selected date.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : Stack(
                children: [
                  ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 80, top: 8),
                    children:
                        sortedLetters
                            .where(
                              (letter) => groupedAbsentees.containsKey(letter),
                            )
                            .map((letter) {
                              final absentees = groupedAbsentees[letter]!;
                              return Column(
                                key: letterKeys[letter],
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      letter,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  ...absentees.map((absentee) {
                                    final name = absentee['name'] ?? 'Unknown';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                            leading: CircleAvatar(
                                              radius: 24,
                                              backgroundColor:
                                                  _getColorForLetter(
                                                    name[0].toUpperCase(),
                                                  ),
                                              child: Text(
                                                name[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              name,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              );
                            })
                            .toList(),
                  ),
                  Positioned(
                    right: 0,
                    child: SafeArea(
                      child: SingleChildScrollView(
                        child: Column(
                          children:
                              sortedLetters.map((letter) {
                                final isSelected = selectedLetter == letter;
                                return GestureDetector(
                                  onTap: () {
                                    if (groupedAbsentees.containsKey(letter)) {
                                      _scrollToLetter(letter);
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.black87
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      letter,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

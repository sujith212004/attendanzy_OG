import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class ODRequestsAdminPage extends StatefulWidget {
  const ODRequestsAdminPage({super.key});

  @override
  State<ODRequestsAdminPage> createState() => _ODRequestsAdminPageState();
}

class _ODRequestsAdminPageState extends State<ODRequestsAdminPage> {
  final String mongoUri =
      "mongodb+srv://digioptimized:digi123@cluster0.iuajg.mongodb.net/attendance_DB?retryWrites=true&w=majority";
  final String collectionName = "od_requests";

  List<Map<String, dynamic>> requests = [];
  bool loading = true;
  String? error;
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final db = await mongo.Db.create(mongoUri);
      await db.open();
      final collection = db.collection(collectionName);
      final result = await collection.find().toList();
      await db.close();
      setState(() {
        requests = List<Map<String, dynamic>>.from(result);
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      final db = await mongo.Db.create(mongoUri);
      await db.open();
      final collection = db.collection(collectionName);
      await collection.updateOne(
        mongo.where.id(mongo.ObjectId.parse(id)),
        mongo.modify.set('status', status),
      );
      await db.close();
      await fetchRequests();
      setState(() {
        expandedIndex = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Request $status!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OD Requests'),
        backgroundColor: Colors.blue[700],
        centerTitle: true,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text('Error: $error'))
              : requests.isEmpty
              ? const Center(child: Text('No OD requests found.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  final isExpanded = expandedIndex == index;
                  return _buildExpandableCard(req, index, isExpanded);
                },
              ),
    );
  }

  Widget _buildExpandableCard(
    Map<String, dynamic> req,
    int index,
    bool isExpanded,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isExpanded ? Colors.blue.shade300 : Colors.blue.shade100,
          width: isExpanded ? 2 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              expandedIndex = isExpanded ? null : index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState:
                  isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              firstChild: _buildCollapsedRequest(req),
              secondChild: _buildExpandedRequest(req, index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedRequest(Map<String, dynamic> req) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          req['subject'] ?? 'OD Request',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          'From: ${req['from'] ?? ''}',
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text('To: ${req['to'] ?? ''}', style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 4),
        Text(
          'Status: ${req['status'] ?? 'pending'}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color:
                req['status'] == 'accepted'
                    ? Colors.green
                    : req['status'] == 'rejected'
                    ? Colors.red
                    : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedRequest(Map<String, dynamic> req, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                req['subject'] ?? 'OD Request',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  expandedIndex = null;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "To:\n${req['to'] ?? ''}",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 10),
        Text(
          "From:\n${req['from'] ?? ''}",
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 10),
        Text(
          "Subject: ${req['subject'] ?? ''}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        Text(
          "Respected Sir/Madam,",
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Text(
          req['content'] ?? '',
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        const SizedBox(height: 18),
        if (req['image'] != null && req['image'].toString().isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Proof Image:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Image.memory(
                base64Decode(req['image']),
                height: 120,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 18),
            ],
          ),
        Row(
          children: [
            Text(
              "Status: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              req['status'] ?? 'pending',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    req['status'] == 'accepted'
                        ? Colors.green
                        : req['status'] == 'rejected'
                        ? Colors.red
                        : Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed:
                  req['status'] == 'accepted'
                      ? null
                      : () =>
                          updateStatus(req['_id'].toHexString(), 'accepted'),
              label: const Text(
                'Accept',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.close, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed:
                  req['status'] == 'rejected'
                      ? null
                      : () =>
                          updateStatus(req['_id'].toHexString(), 'rejected'),
              label: const Text(
                'Reject',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AdminPaymentsPage extends StatefulWidget {
  @override
  _AdminPaymentsPageState createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  Future _showExtraInfo(context, payment) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Map data = {};
        bool isLoading = true;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            void loadData(String desc, build, doc_id) async {
              try {
                String type = "";
                if (desc.contains('penalties')) {
                  type = 'penalties';
                }
                if (desc.contains('maintainenance')) {
                  type = 'maintainenance';
                }

                DocumentSnapshot result = await FirebaseFirestore.instance
                    .collection('buildings')
                    .doc(build)
                    .collection(type)
                    .doc(doc_id)
                    .get();
                data['data'] = result.data() as Map;
                isLoading = false;
                setDialogState(() {});
              } catch (e) {
                data['message'] = 'No data available';
                isLoading = false;
                setDialogState(() {});
              }
            }

            if (isLoading) {
              loadData(payment['description'], payment['build_id'],
                  payment['doc_id']);
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              title: Text(
                payment['description'],
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 300,
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE94560),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['message'] == 'No data available')
                              const Center(
                                child: Text(
                                  "No data available",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            else
                              ...data['data'].entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Flexible(
                                          flex: 2,
                                          child: Text(
                                            '${entry.key}: ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFE94560),
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          flex: 3,
                                          child: Text(
                                            entry.value.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: data.toString()));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        backgroundColor: Color(0xFFE94560),
                      ),
                    );
                  },
                  child: const Text(
                    "Copy data",
                    style: TextStyle(color: Color(0xFFE94560)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(80.0),
          child: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: const Color(0xFF1A1A2E),
            elevation: 0,
            flexibleSpace: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.payment,
                        color: Color(0xFFE94560),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Payments',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 3,
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE94560), Color(0xFF0F3460)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('payments').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFE94560),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No payments found',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final payments = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return Card(
                    color: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "User: ${payment['userName']}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Amount: ${payment['amount']}",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Date: ${payment['date'] != null ? (payment['date'] as Timestamp).toDate().toString() : 'Unknown'}",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Status: ${payment['status']}",
                            style: TextStyle(
                              color: payment['status'] == 'Completed' ? Colors.green : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
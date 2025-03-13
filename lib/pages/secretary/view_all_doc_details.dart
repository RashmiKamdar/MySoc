import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class ViewAllDocDetails extends StatefulWidget {
  const ViewAllDocDetails({super.key});

  @override
  State<ViewAllDocDetails> createState() => _ViewAllDocDetailsState();
}

class _ViewAllDocDetailsState extends State<ViewAllDocDetails> {
  late Map args;
  String jobTitle = '';
  late String doc_id;

  void download_pdf(String url, String file_name) async {
    try {
      Dio dio = Dio();

      final dir = Directory('/storage/emulated/0/Download');
      String path = "${dir.path}/$file_name.pdf";

      await dio.download(url, path, onReceiveProgress: (rec, total) {
        print('Rec: $rec, Total: $total');
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: Duration(seconds: 2),
          content: Text("Downloaded the invoice")));
    } catch (e) {
      print("Download Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    jobTitle = args['jobDetails'];
    doc_id = args['buildingDetails'];

    return Scaffold(
      appBar: AppBar(
        title: Text(jobTitle),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('buildings')
              .doc(doc_id)
              .collection('maintainenace')
              .where('job_id', isEqualTo: jobTitle)
              .orderBy('status')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading Maintenance Documents',
                  style: TextStyle(color: Colors.red[700]),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green[300],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Maintenance Documents found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];

                String dueDateString = 'Within Due Date';
                var due = DateTime.parse(doc['dueDate']);

                if (due.isBefore(DateTime.now())) {
                  dueDateString = 'Over Due Date';
                }

                return ListTile(
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        String formatDue = DateFormat('MMMM dd, yyyy')
                            .format(due)
                            .toString();

                        return AlertDialog(
                          backgroundColor: const Color(0xFF1A1A2E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(
                            "${doc['wing']} - ${doc['flatNumber']}",
                            style: const TextStyle(color: Colors.white),
                          ),
                          content: Container(
                            height: 150,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Email: ${doc['residentEmail']}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "Due Date: $formatDue",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "Amount: ${doc['amount']}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "Paid: ${doc['status']}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "Amount Paid + Dues: ${doc['paidAmount']}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "Paid on: ${doc['paid_on']}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                download_pdf(doc['pdfLink'], doc.id);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: Duration(seconds: 2),
                                    content: Text("Downloading the invoice .."),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE94560),
                              ),
                              child: const Text("Download Invoice"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  trailing: doc['status']
                      ? const Icon(Icons.done, color: Colors.green)
                      : const Icon(Icons.pending_actions, color: Colors.orange),
                  title: Text(
                    "${doc['wing']} - ${doc['flatNumber']}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Maintenance due of ${doc['amount']} \$ \n $dueDateString",
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

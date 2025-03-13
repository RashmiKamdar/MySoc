import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class ViewRecordsCourriers extends StatefulWidget {
  const ViewRecordsCourriers({super.key});

  @override
  State<ViewRecordsCourriers> createState() => _ViewRecordsCourriersState();
}

class _ViewRecordsCourriersState extends State<ViewRecordsCourriers> {
  late Map args;
  late DocumentSnapshot build_details;
  late QueryDocumentSnapshot user_details;

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map;
    user_details = args['userDetails'];
    build_details = args['buildingDetails'];

    Stream<QuerySnapshot> getCourriers() {
      return FirebaseFirestore.instance
          .collection('buildings')
          .doc(build_details.id)
          .collection('courriers')
          .where('flat', isEqualTo: user_details['flatNumber'])
          .where('wing', isEqualTo: user_details['wing'])
          .snapshots();
    }

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
                        Icons.local_shipping,
                        color: Color(0xFFE94560),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'Couriers',
                            textStyle: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            speed: const Duration(milliseconds: 100),
                          ),
                        ],
                        isRepeatingAnimation: false,
                        totalRepeatCount: 1,
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
            stream: getCourriers(),
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
                    'No couriers found',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final couriers = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: couriers.length,
                itemBuilder: (context, index) {
                  final courier = couriers[index];
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
                            "From: ${courier['deliveryName']}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Received By: ${courier['recievedName']}",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Description: ${courier['description']}",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Status: ${courier['status'] ? 'Delivered' : 'Pending'}",
                            style: TextStyle(
                              color: courier['status'] ? Colors.green : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          if (!courier['status'])
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  _updateState(id: courier.id);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFE94560),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Icon(Icons.done, color: Colors.white),
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

  void _updateState({required String id}) {
    // Your update state logic here
  }
}

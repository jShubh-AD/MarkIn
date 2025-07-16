import 'dart:async';
import 'dart:math';

import 'package:attendence/core/auth/aurth_service.dart';
import 'package:attendence/user/signin/signin_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final fbStore = FirebaseFirestore.instance.collection('subjects');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Welcome Teacher'),
        actions: [
          GestureDetector(
            onTap: () {
              authService.value.logOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => SignInPage()));
            },
            child: const Icon(Icons.logout),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text('Take Attendance', style: TextStyle(fontSize: 20)),
          Expanded(
            child: ListView.builder(
              itemCount: 1, // Update this with your subject count
              itemBuilder: (context, index) {
                return ExpansionTile(
                  title: const Text('Computer Architecture Sec-D'),
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: fbStore
                          .doc('computer_arc')
                          .collection('computer_arc_sec_d')
                          .doc('attendance_open')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          );
                        }

                        final data = snapshot.data?.data() as Map<String, dynamic>?;
                        final isOpen = data?['isOpen'] ?? false;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isOpen ? 'Attendance is Open ' : 'Attendance is Closed',
                                    style: TextStyle(
                                      color: isOpen ? Colors.green : Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: isOpen,
                                    activeColor: Colors.white,
                                    activeTrackColor: Colors.green,
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: Colors.red,
                                    onChanged: (val) async {
                                      await fbStore
                                          .doc('computer_arc')
                                          .collection('computer_arc_sec_d')
                                          .doc('attendance_open')
                                          .set({'isOpen': val});

                                      if (!val) {
                                        // Optional: reset local UI logic
                                      }
                                    },
                                  ),
                                ],
                              ),
                              // 👇 Countdown button widget (rebuilds only itself)
                              CodeCountdownButton(isOpen: isOpen),
                            ],
                          ),
                        );
                      },
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 👇 Separate widget to handle countdown and code generation
class CodeCountdownButton extends StatefulWidget {
  final bool isOpen;

  const CodeCountdownButton({super.key, required this.isOpen});

  @override
  State<CodeCountdownButton> createState() => _CodeCountdownButtonState();
}

class _CodeCountdownButtonState extends State<CodeCountdownButton> {
  int? _code;
  String _buttonText = "Generate Code";
  bool _isDisabled = false;
  Timer? _timer;

  /// Starts the code generation and countdown logic
  void _startCountdown() async {
    setState(() {
      _isDisabled = true;
      _code = 100000 + Random().nextInt(900000); // generate 6-digit code
      _buttonText = "Wait (30s)";
    });

    final fbStore = FirebaseFirestore.instance.collection('subjects');

    // Upload code and open attendance
    await fbStore
        .doc('computer_arc')
        .collection('computer_arc_sec_d')
        .doc('attendance_open')
        .update({
      'code': _code,
      'isOpen': true,
      'expTime': Timestamp.fromDate(DateTime.now().add(const Duration(seconds: 30)))
    });

    // Local countdown
    int seconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds == 0) {
        setState(() {
          _isDisabled = false;
          _buttonText = 'Generate Code';
          _code = null;
        });
        timer.cancel();
      } else {
        seconds--;
        setState(() {
          _buttonText = "Wait (${seconds}s)";
        });
      }
    });

    // Reset Firestore values after 30 seconds
    Future.delayed(const Duration(seconds: 30), () async {
      await fbStore
          .doc('computer_arc')
          .collection('computer_arc_sec_d')
          .doc('attendance_open')
          .update({
        'isOpen': false,
        'code': FieldValue.delete(),
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_code != null && widget.isOpen)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Generated Code: $_code',
              style: const TextStyle(color: Colors.green),
            ),
          ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: (_isDisabled || !widget.isOpen) ? null : _startCountdown,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isOpen ? Colors.green : Colors.grey,
          ),
          child: Text(
            _buttonText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class VIPUpsellScreen extends StatelessWidget {
  const VIPUpsellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Get VIP"),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Upgrade to VIP",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              "As a VIP, you get access to:\n\n"
              "- Premium Dashboard\n"
              "- Advanced Notes & Attendance Features\n"
              "- Early access to new features\n"
              "- And much more!",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF57C00),
              ),
              onPressed: () {
                // For now, we just pop back. Later admin will toggle premium true.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "VIP upgrade simulated. Admin will activate it.",
                    ),
                  ),
                );
              },
              child: const Text("Get VIP"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../home/home_screen.dart';

class UpgradePremiumScreen extends StatelessWidget {
  const UpgradePremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
    final FirestoreService _firestoreService = FirestoreService();
    final bool isGuest = uid == 'guest_user' || uid.toLowerCase().startsWith('guest');

    if (isGuest) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upgrade to Premium'),
          backgroundColor: const Color(0xFF283593),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Please sign up to upgrade to premium',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        backgroundColor: const Color(0xFF283593),
      ),
      body: StreamBuilder<bool>(
        stream: _firestoreService.getUserPremiumStatus(uid),
        builder: (context, snapshot) {
          final isPremium = snapshot.data ?? false;

          if (isPremium) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 80,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'You are already a Premium member!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF283593),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enjoy all premium features',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Student Sathi Premium',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF283593),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unlock the full potential of your academic journey',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildComparisonTable(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _firestoreService.upgradeToPremium(uid);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Successfully upgraded to Premium! 🎉'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF283593),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Upgrade to Premium',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFeatureRow('Feature', 'Free', 'Premium', isHeader: true),
            const Divider(),
            _buildFeatureRow('Unlimited Subjects', '✓', '✓'),
            _buildFeatureRow('Basic Analytics', '✓', '✓'),
            _buildFeatureRow('Automatic Attendance Popup', '✗', '✓'),
            _buildFeatureRow('Advanced Analytics', '✗', '✓'),
            _buildFeatureRow('GPA Trend Analysis', '✗', '✓'),
            _buildFeatureRow('Subject-wise Marks Analysis', '✗', '✓'),
            _buildFeatureRow('Internal vs External Charts', '✗', '✓'),
            _buildFeatureRow('Attendance Heatmap', '✗', '✓'),
            _buildFeatureRow('Smooth Animations', '✗', '✓'),
            _buildFeatureRow('All UI Themes', '✗', '✓'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature, String free, String premium, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: isHeader ? 16 : 14,
                color: isHeader ? const Color(0xFF283593) : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: isHeader ? 16 : 14,
                color: isHeader ? const Color(0xFF283593) : Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              premium,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: isHeader ? 16 : 14,
                color: isHeader ? const Color(0xFF283593) : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final AuthService _auth = AuthService();

  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.sendPhoneOtp(
        phoneNumber: _phoneCtrl.text.trim(),
        onAutoVerified: (cred) async {
          final user = await _auth.verifyPhoneOtp(
            verificationId: cred.verificationId ?? '',
            smsCode: _otpCtrl.text.trim(),
          );
          if (user != null && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        },
        onFailed: (e) => setState(() => _error = e.message),
        onCodeSent: (verId, _) => setState(() {
          _verificationId = verId;
          _otpSent = true;
        }),
        onCodeTimeout: (verId) => setState(() => _verificationId = verId),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) {
      setState(() => _error = "No verification ID. Resend OTP.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await _auth.verifyPhoneOtp(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF283593);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone OTP Login"),
        backgroundColor: themeColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone (e.g. +919876543210)',
              ),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _otpCtrl,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
            ],
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: themeColor,
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_otpSent ? "Verify OTP" : "Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}

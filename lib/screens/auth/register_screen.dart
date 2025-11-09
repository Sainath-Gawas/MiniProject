import 'package:flutter/material.dart';
import 'package:edutrack/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController(); // NEW
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // NEW
  final _mobileController = TextEditingController(); // NEW (Optional)
  bool _isLoading = false;

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _handleRegistration() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final mobile = _mobileController.text.trim();

    // Basic validation
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnack("Please fill in all required fields.");
      return;
    }

    if (password != confirmPassword) {
      _showSnack("Passwords do not match.");
      return;
    }

    if (password.length < 6) {
      _showSnack("Password must be at least 6 characters.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.registerWithEmail(
        email,
        password,
        name,
        mobile.isNotEmpty ? mobile : null, // Pass null if mobile is empty
      );

      // Registration successful! Pop the screen to navigate to AuthGate.
      Navigator.of(context).pop();
    } catch (e) {
      _showSnack("Registration Failed: ${e.toString().split(':').last.trim()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),
              Text(
                "Join EduTrack",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // --- Name Field (NEW) ---
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: "Full Name (Required)",
                ),
              ),
              const SizedBox(height: 15),
              // --- Email Field ---
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email (Required)",
                ),
              ),
              const SizedBox(height: 15),
              // --- Password Field ---
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password (Min 6 characters)",
                ),
              ),
              const SizedBox(height: 15),
              // --- Confirm Password Field (NEW) ---
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                ),
              ),
              const SizedBox(height: 15),
              // --- Mobile Field (NEW - Optional) ---
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Mobile Number (Optional)",
                ),
              ),
              const SizedBox(height: 30),
              // --- Register Button ---
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Register", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              // --- Login CTA ---
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

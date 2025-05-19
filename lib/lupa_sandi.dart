import 'package:flutter/material.dart';

class LupaSandi extends StatefulWidget {
  const LupaSandi({super.key});

  @override
  State<LupaSandi> createState() => _LupaSandiState();
}

class _LupaSandiState extends State<LupaSandi> {
  final _phoneController = TextEditingController();
  bool _isButtonEnabled = false; // Declare _isButtonEnabled

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_updateButtonState);
  }

  // Function to update button state based on phone input
  void _updateButtonState() {
    setState(() {
      // Enabling button if the phone number input is not empty and has a minimum length of 10 digits
      _isButtonEnabled =
          _phoneController.text.isNotEmpty &&
          _phoneController.text.length >= 10;
    });
  }

  // Build a text field widget for phone input
  Widget _buildTextField(
    String label,
    String hint,
    bool obscureText,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: TextInputType.phone, // Use the phone number keyboard
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            children: [
              ListView(
                children: [
                  const SizedBox(height: 100),
                  const Center(
                    child: Text(
                      "Lupa Kata Sandi",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    "Nomor Telepon",
                    "Masukkan nomor telepon",
                    false,
                    _phoneController,
                  ),
                  const SizedBox(height: 30),
                  // Add your button here
                  ElevatedButton(
                    onPressed: _isButtonEnabled ? () {} : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isButtonEnabled ? Colors.blue : Colors.grey,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Lanjut"),
                  ),
                ],
              ),
              Positioned(
                top: 10,
                left: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

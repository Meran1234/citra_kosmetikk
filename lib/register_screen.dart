import 'dart:convert';
import 'package:citra_kosmetik/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscureText = true;
  bool _obscureTextConfirm = true;

  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final noTelpController = TextEditingController();

  bool isLoading = false;
  String? message;

  Future<void> registerUser() async {
    final nama = namaController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final noTelp = noTelpController.text.trim();

    if (nama.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        noTelp.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        message = 'Semua field harus diisi.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        message = 'Kata sandi dan konfirmasi kata sandi tidak cocok.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = null;
    });

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'nama': nama,
        'email': email,
        'password': password,
        'no_telp': noTelp,
      });

      final response = await dio.post(
        'https://citrakosmetik.my.id/get_regis.php',
        data: formData,
      );

      dynamic data = response.data;

      // Parse string response ke JSON jika perlu
      if (data is String) {
        data = jsonDecode(data);
      }

      if (data is Map<String, dynamic>) {
        setState(() {
          message = data['message'];
        });

        if (data['id_user'] != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Registrasi berhasil!')));
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          });
        }
      } else {
        setState(() {
          message = 'Format data dari server tidak sesuai.';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Terjadi kesalahan koneksi: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
                  const SizedBox(height: 80),
                  Center(child: Image.asset('assets/logo.png', height: 130)),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "Daftar Akun",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "Nama Lengkap",
                    "Masukkan nama lengkap",
                    false,
                    namaController,
                  ),
                  _buildTextField(
                    "Alamat Email",
                    "Masukkan alamat email",
                    false,
                    emailController,
                  ),
                  _buildTextField(
                    "Kata Sandi",
                    "Masukkan kata sandi",
                    true,
                    passwordController,
                  ),
                  _buildTextField(
                    "Konfirmasi Kata Sandi",
                    "Masukkan konfirmasi kata sandi",
                    true,
                    confirmPasswordController,
                  ),
                  _buildTextField(
                    "No Telepon",
                    "Masukkan nomor telepon",
                    false,
                    noTelpController,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isLoading ? null : registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLoading ? Colors.grey : Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child:
                        isLoading
                            ? const CircularProgressIndicator()
                            : const Text("Daftar"),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text("ATAU"),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSocialLoginButton(
                    'assets/icons/google.png',
                    'Daftar dengan Google',
                    () {},
                  ),
                  const SizedBox(height: 12),
                  _buildSocialLoginButton(
                    'assets/icons/facebook.png',
                    'Daftar dengan Facebook',
                    () {},
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Sudah Punya Akun?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
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

  Widget _buildTextField(
    String label,
    String hint,
    bool isPassword,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText:
                isPassword
                    ? (label == 'Konfirmasi Kata Sandi'
                        ? _obscureTextConfirm
                        : _obscureText)
                    : false,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon:
                  isPassword
                      ? IconButton(
                        icon: Icon(
                          (label == 'Konfirmasi Kata Sandi'
                                  ? _obscureTextConfirm
                                  : _obscureText)
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () => setState(() {
                              if (label == 'Konfirmasi Kata Sandi') {
                                _obscureTextConfirm = !_obscureTextConfirm;
                              } else {
                                _obscureText = !_obscureText;
                              }
                            }),
                      )
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginButton(
    String iconPath,
    String text,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 50),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(iconPath, height: 50),
            const SizedBox(width: 20),
            Text(text),
          ],
        ),
      ),
    );
  }
}

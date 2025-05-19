import 'package:citra_kosmetik/lupa_sandi.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:citra_kosmetik/dashboard/dashboard_screen.dart';
import 'package:citra_kosmetik/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled =
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  void _login() async {
    if (!_isButtonEnabled) return;

    try {
      Dio dio = Dio();
      Response response = await dio.post(
        'https://citrakosmetik.my.id/get_login.php', // Ganti dengan URL server PHP Anda
        data: {
          'email': _emailController.text,
          'password': _passwordController.text,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      Map<String, dynamic> responseData = response.data;

      // Cek apakah login berhasil
      if (responseData['message'] == 'Login berhasil!') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Login Berhasil")));

        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Periksa apakah id_user tidak null
        if (responseData['id_user'] != null) {
          int userId = responseData['id_user'];
          await prefs.setInt('id_user', userId);
        } else {
          // Tangani jika id_user null
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID Pengguna tidak ditemukan')),
          );
          return;
        }

        // Simpan nama pengguna
        await prefs.setString('nama', responseData['nama']);

        // Pindah ke halaman Dashboard setelah login sukses
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(responseData['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
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
                      "Log In",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    "Alamat Email",
                    "Masukkan alamat email",
                    false,
                    _emailController,
                  ),
                  _buildTextField(
                    "Kata Sandi",
                    "Masukkan kata sandi",
                    true,
                    _passwordController,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LupaSandi(),
                          ),
                        );
                      },
                      child: const Text(
                        "Lupa Kata Sandi?",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _isButtonEnabled ? _login : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isButtonEnabled ? Colors.blue : Colors.grey,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Sign In"),
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
                    'Log In dengan Google',
                    () {},
                  ),
                  const SizedBox(height: 12),
                  _buildSocialLoginButton(
                    'assets/icons/facebook.png',
                    'Log In dengan Facebook',
                    () {},
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Belum Punya Akun?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Daftar",
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
            obscureText: isPassword ? _obscureText : false,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon:
                  isPassword
                      ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed:
                            () => setState(() => _obscureText = !_obscureText),
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

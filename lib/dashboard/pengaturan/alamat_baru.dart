import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AlamatBaru extends StatefulWidget {
  const AlamatBaru({super.key});

  @override
  State<AlamatBaru> createState() => _AlamatBaruState();
}

class _AlamatBaruState extends State<AlamatBaru> {
  String idUser = '';
  bool isAktif = false;

  final TextEditingController namaController = TextEditingController();
  final TextEditingController telponController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController jalanController = TextEditingController();
  final TextEditingController detailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserId();

    // Tambahkan listener agar setState() dipanggil saat teks berubah
    namaController.addListener(() => setState(() {}));
    telponController.addListener(() => setState(() {}));
    alamatController.addListener(() => setState(() {}));
    jalanController.addListener(() => setState(() {}));
    detailController.addListener(() => setState(() {}));
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getInt('id_user')?.toString() ?? '';
    });
  }

  bool isFilled() {
    return namaController.text.isNotEmpty &&
        telponController.text.isNotEmpty &&
        alamatController.text.isNotEmpty &&
        jalanController.text.isNotEmpty &&
        detailController.text.isNotEmpty;
  }

  Future<void> simpanAlamat() async {
    if (idUser.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ID User tidak ditemukan")));
      return;
    }

    final url = Uri.parse('https://citrakosmetik.my.id/insert_alamat.php');

    try {
      final response = await http.post(
        url,
        body: {
          'id_user': idUser,
          'nama': namaController.text,
          'no_telp': telponController.text,
          'alamat': alamatController.text,
          'jalan': jalanController.text,
          'detail': detailController.text,
          'flag': isAktif ? '1' : '0',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Alamat berhasil disimpan")),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(responseData['message'])));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal menyimpan alamat")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    }
  }

  Widget _buildUnderlineField(
    TextEditingController controller,
    String label, [
    TextInputType type = TextInputType.text,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: label,
          border: const UnderlineInputBorder(),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alamat Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Alamat",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildUnderlineField(namaController, "Nama Lengkap"),
                    _buildUnderlineField(
                      telponController,
                      "No. Telpon",
                      TextInputType.phone,
                    ),
                    _buildUnderlineField(
                      alamatController,
                      "Provinsi, Kota, Kecamatan, Kode Pos",
                    ),
                    _buildUnderlineField(
                      jalanController,
                      "Nama Jalan, Gedung, No. Rumah",
                    ),
                    _buildUnderlineField(
                      detailController,
                      "Detail Lainnya (Cth: Blok / Unit No., Patokan)",
                    ),
                    SwitchListTile(
                      title: const Text(
                        "Atur Sebagai Alamat Utama",
                        style: TextStyle(fontSize: 14),
                      ),
                      value: isAktif,
                      onChanged: (value) {
                        setState(() {
                          isAktif = value;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isFilled() ? simpanAlamat : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFilled() ? Colors.blue : Colors.grey[300],
                    foregroundColor: isFilled() ? Colors.white : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Simpan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

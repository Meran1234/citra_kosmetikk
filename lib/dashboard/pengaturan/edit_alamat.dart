import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart'; // Example for making network requests

class EditAlamat extends StatefulWidget {
  final dynamic alamat;

  const EditAlamat({super.key, required this.alamat});

  @override
  _EditAlamatState createState() => _EditAlamatState();
}

class _EditAlamatState extends State<EditAlamat> {
  String idUser = '';
  String idAlamat = '';
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _noTelpController = TextEditingController();
  final TextEditingController _provinsiController = TextEditingController();
  final TextEditingController _jalanController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  bool isUtama = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    // Set text fields with the data passed from the 'alamat' argument
    _namaController.text = widget.alamat['nama'];
    _noTelpController.text = widget.alamat['no_telp'];
    _provinsiController.text = widget.alamat['alamat'];
    _jalanController.text = widget.alamat['jalan'];
    _detailController.text = widget.alamat['detail'];
    setState(() {
      isUtama = widget.alamat['flag'].toString() == '1';
      idAlamat =
          widget.alamat['id_alamat'].toString(); // Ensure id_alamat is set
    });
  }

  // Memuat id_user dari SharedPreferences
  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getInt('id_user')?.toString() ?? '';
    });
  }

  // Fungsi untuk memeriksa apakah semua form sudah terisi
  bool isFilled() {
    return _namaController.text.isNotEmpty &&
        _noTelpController.text.isNotEmpty &&
        _provinsiController.text.isNotEmpty &&
        _jalanController.text.isNotEmpty &&
        _detailController.text.isNotEmpty;
  }

  // Fungsi untuk menyimpan perubahan alamat
  Future<void> _saveAlamat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Dio dio = Dio();
      Response response = await dio.post(
        'https://citrakosmetik.my.id/update_alamat.php',
        data: {
          'id_user': idUser,
          'id_alamat': idAlamat,
          'nama': _namaController.text,
          'no_telp': _noTelpController.text,
          'alamat': _provinsiController.text,
          'jalan': _jalanController.text,
          'detail': _detailController.text,
          'flag': isUtama ? '1' : '0',
        },
      );

      if (response.statusCode == 200) {
        // Tangani respons sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil diperbarui!')),
        );
      } else {
        // Tangani kesalahan
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui alamat.')),
        );
      }
    } catch (e) {
      // Tangani error jaringan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan, coba lagi!')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Alamat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(_namaController, "Nama Lengkap"),
                    _buildTextField(_noTelpController, "No. Telpon"),
                    _buildTextField(
                      _provinsiController,
                      "Provinsi, Kota, Kecamatan, Kode Pos",
                    ),
                    _buildTextField(
                      _jalanController,
                      "Nama Jalan, Gedung, No. Rumah",
                    ),
                    _buildTextField(
                      _detailController,
                      "Detail Lainnya (Cth: Blok / Unit No., Patokan)",
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Atur Sebagai Alamat Utama"),
                        Switch(
                          value: isUtama,
                          onChanged: (value) {
                            setState(() {
                              isUtama = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    isFilled() && !_isLoading
                        ? () {
                          _saveAlamat();
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFilled() ? Colors.blue : Colors.grey[300],
                  foregroundColor: isFilled() ? Colors.white : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Simpan"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Membuat widget text field yang dapat digunakan ulang
  Widget _buildTextField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: const UnderlineInputBorder(),
        ),
      ),
    );
  }
}

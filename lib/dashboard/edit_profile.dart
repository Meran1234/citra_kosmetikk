import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfile extends StatefulWidget {
  final String nama;

  const EditProfile({super.key, required this.nama});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  List<Map<String, dynamic>> ProfileItems = [];
  String idUser = '';
  String gambar = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String gender = 'Atur Sekarang';
  String birthDate = 'Atur Sekarang';

  final ImagePicker _picker = ImagePicker(); // ImagePicker instance
  File? _imageFile; // Variable to store selected image

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getInt('id_user')?.toString() ?? '';
    });

    if (idUser.isNotEmpty) {
      _fetchProfile();
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://citrakosmetik.my.id/get_pembeli.php',
        data: {'id_user': idUser},
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['pembeli'][0];
        setState(() {
          _nameController.text = data['nama'] ?? '';
          _emailController.text = data['email'] ?? '';
          gender = data['jenis_kelamin'] ?? 'Atur Sekarang';
          birthDate = data['tgl_lahir'] ?? 'Atur Sekarang';
          _phoneController.text = data['no_telp'] ?? '';
          gambar = data['gambar'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  Future<void> _updateProfile() async {
    final dio = Dio();
    try {
      final response = await dio.post(
        'https://citrakosmetik.my.id/update_pembeli.php',
        data: {
          'id_user': idUser,
          'nama': _nameController.text,
          'email': _emailController.text,
          'jenis_kelamin': gender,
          'tgl_lahir': birthDate,
          'no_telp': _phoneController.text,
          // You can add an image upload logic here
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profil berhasil diperbarui')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Gagal update')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> _pickBirthDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthDate =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        gambar = pickedFile.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      _imageFile != null
                          ? FileImage(_imageFile!)
                          : (gambar.isNotEmpty
                              ? NetworkImage(
                                'https://citrakosmetik.my.id/profil/$gambar',
                              )
                              : null),
                  child:
                      _imageFile == null && gambar.isEmpty
                          ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.blue,
                          )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue,
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: gender == 'Atur Sekarang' ? null : gender,
              decoration: const InputDecoration(
                labelText: 'Jenis Kelamin',
                border: OutlineInputBorder(),
              ),
              items:
                  ['Laki-laki', 'Perempuan']
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  gender = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Lahir',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  birthDate,
                  style: TextStyle(
                    color:
                        birthDate == 'Atur Sekarang'
                            ? Colors.red
                            : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'No Telpon',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Alamat Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _updateProfile,
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

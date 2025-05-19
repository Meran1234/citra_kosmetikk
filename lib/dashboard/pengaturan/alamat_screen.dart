import 'dart:convert';
import 'package:citra_kosmetik/dashboard/pengaturan/alamat_baru.dart';
import 'package:citra_kosmetik/dashboard/pengaturan/edit_alamat.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AlamatScreen extends StatefulWidget {
  const AlamatScreen({super.key});

  @override
  State<AlamatScreen> createState() => _AlamatScreenState();
}

class _AlamatScreenState extends State<AlamatScreen> {
  String idUser = '';
  List<dynamic> alamatList = [];

  @override
  void initState() {
    super.initState();
    loadUserId();
  }

  Future<void> loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getInt('id_user')?.toString() ?? '';
    });
    if (idUser.isNotEmpty) {
      fetchAlamat();
    }
  }

  Future<void> fetchAlamat() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://citrakosmetik.my.id/get_alamat_user.php?id_user=$idUser',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          alamatList = jsonDecode(response.body);
        });
      }
    } catch (e) {
      // Optional: tampilkan error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(top: 3.0, left: 20.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: const Text(
          'Alamat Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (alamatList.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: alamatList.length,
                  itemBuilder: (context, index) {
                    final alamat = alamatList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bagian Kiri (Informasi Alamat)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alamat['nama'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(alamat['no_telp']),
                                    Text(
                                      '${alamat['alamat']}, ${alamat['jalan']}',
                                    ),
                                    Text(alamat['detail']),
                                  ],
                                ),
                              ),
                              // Bagian Kanan (Icon Edit & Delete)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      // Navigate to the EditAlamatScreen and pass the selected address
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  EditAlamat(alamat: alamat),
                                        ),
                                      ).then((message) {
                                        // If the address was updated, fetch the new data
                                        if (message != null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text(message)),
                                          );
                                          fetchAlamat();
                                        }
                                      });
                                    },
                                  ),

                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Konfirmasi"),
                                            content: const Text(
                                              "Hapus item dari keranjang?",
                                            ),
                                            actions: [
                                              TextButton(
                                                child: const Text("Batal"),
                                                onPressed:
                                                    () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(),
                                              ),
                                              TextButton(
                                                child: const Text("Hapus"),
                                                onPressed: () async {
                                                  try {
                                                    final dio = Dio();
                                                    final response = await dio.post(
                                                      'https://citrakosmetik.my.id/delete_alamat.php',
                                                      data: {
                                                        'id_user': idUser,
                                                        'detail':
                                                            alamatList[index]['detail'],
                                                      },
                                                      options: Options(
                                                        headers: {
                                                          'Content-Type':
                                                              'application/x-www-form-urlencoded',
                                                        },
                                                      ),
                                                    );

                                                    if (response
                                                            .data['success'] ==
                                                        true) {
                                                      setState(() {
                                                        alamatList.removeAt(
                                                          index,
                                                        );
                                                      });
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            response
                                                                .data['message'],
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            response
                                                                .data['message'],
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    Navigator.of(context).pop();
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Gagal: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AlamatBaru()),
                );
                fetchAlamat();
              },
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.blue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Tambah Alamat Baru',
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

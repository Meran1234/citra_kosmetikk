import 'package:citra_kosmetik/dashboard/dashboard_screen.dart';
import 'package:citra_kosmetik/dashboard/edit_profile.dart';
import 'package:citra_kosmetik/dashboard/favorite_screen.dart';
import 'package:citra_kosmetik/dashboard/keranjang_screen.dart';
import 'package:citra_kosmetik/dashboard/pengaturan_screen.dart';
import 'package:citra_kosmetik/dashboard/terakhir_dilihat.dart';
import 'package:citra_kosmetik/dashboard_awal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String nama = 'Nama';
  String id = 'id_user';
  String gambar = '';

  @override
  void initState() {
    super.initState();
    _loadNama();
    _loadUserId();
  }

  Future<void> _loadNama() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String idUser = prefs.getInt('id_user')?.toString() ?? '';

    if (idUser.isNotEmpty) {
      final dio = Dio();
      final response = await dio.post(
        'https://citrakosmetik.my.id/get_pembeli.php',
        data: {'id_user': idUser},
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          nama = response.data['pembeli'][0]['nama'] ?? 'Tidak diketahui';
          gambar = response.data['pembeli'][0]['gambar'] ?? '';
        });
      }
    }
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      id =
          prefs.getInt('id_user')?.toString() ??
          'id_user'; // Optional: convert to string if needed
    });
  }

  Future<void> launchWhatsApp([String phoneNumber = '6289617833718']) async {
    final Uri url = Uri.parse('https://wa.me/$phoneNumber');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print("Gagal membuka WhatsApp");
      throw 'Tidak bisa membuka WhatsApp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        toolbarHeight: 30,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => KeranjangScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
            onPressed: () {
              launchWhatsApp('6289617833718');
            },
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          gambar.isNotEmpty
                              ? NetworkImage(
                                'https://citrakosmetik.my.id/profil/$gambar',
                              )
                              : null,
                      child:
                          gambar.isEmpty
                              ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.blue,
                              )
                              : null,
                    ),

                    const SizedBox(width: 15),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            nama,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            iconSize: 20.0,
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfile(nama: nama),
                                ),
                              );
                              _loadNama(); // Fungsi untuk ambil ulang data nama terbaru dari server
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    label: const Text(
                      'Log Out',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DashboardAwal(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 5),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Pesanan Saya",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Lihat Riwayat Pesanan >",
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _OrderStatus(
                      icon: Icons.payment_outlined,
                      label: "Belum Bayar",
                    ),
                    _OrderStatus(
                      icon: Icons.inventory_2_outlined,
                      label: "Dikemas",
                    ),
                    _OrderStatus(
                      icon: Icons.local_shipping_outlined,
                      label: "Dikirim",
                    ),
                    _OrderStatus(
                      icon: Icons.star_border_outlined,
                      label: "Beri Penilaian",
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(color: const Color.fromARGB(255, 239, 234, 234), height: 6),
          Expanded(
            child: ListView(
              children: const [
                _ProfileMenuItem(icon: Icons.settings, label: "Pengaturan"),
                _ProfileMenuItem(icon: Icons.favorite, label: "Favorit Saya"),
                _ProfileMenuItem(
                  icon: Icons.history,
                  label: "Terakhir Dilihat",
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 1) {
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoriteScreen()),
            );
          } else if (index == 3) {}
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
        selectedItemColor: Color.fromARGB(255, 54, 171, 244),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}

class _OrderStatus extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OrderStatus({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Icon(icon, size: 30, color: const Color.fromARGB(255, 94, 94, 94)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              icon == Icons.settings
                  ? Colors.grey
                  : (icon == Icons.favorite ? Colors.pink : Colors.blue),
        ),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (label == "Favorit Saya") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoriteScreen()),
            );
          } else if (label == "Pengaturan") {
            // Pindah ke PengaturanScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PengaturanScreen()),
            );
          } else if (label == "Terakhir Dilihat") {
            // Pindah ke PengaturanScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TerakhirDilihat()),
            );
          }
        },
      ),
    );
  }
}

import 'package:citra_kosmetik/dashboard/detail_favorite.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:citra_kosmetik/dashboard/dashboard_screen.dart';
import 'package:citra_kosmetik/dashboard/keranjang_screen.dart';
import 'package:citra_kosmetik/dashboard/profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

String formatRupiah(String nominal) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );
  return formatter.format(int.tryParse(nominal) ?? 0);
}

class Favorite {
  final String id;
  final String merek;
  final String harga;
  final List<String> gambar;
  final String deskripsi;
  final String stok;

  Favorite({
    required this.id,
    required this.merek,
    required this.harga,
    required this.gambar,
    required this.deskripsi,
    required this.stok,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    var gambarList = List<String>.from(json['gambar'] ?? []);
    return Favorite(
      id: json['id_produk'] ?? '',
      merek: json['merek'] ?? '',
      harga: json['harga'] ?? '',
      gambar: gambarList,
      deskripsi: json['deskripsi'],
      stok: json['stok'] ?? '',
    );
  }
}

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  String idUser = '';
  List<Favorite> favoriteProducts = [];
  bool isLoading = true;
  bool isError = false;

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
      _fetchFavorite();
    }
  }

  Future<void> _fetchFavorite() async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://citrakosmetik.my.id/get_favorite.php',
        data: {'id_user': idUser},
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        List data = response.data;
        setState(() {
          favoriteProducts =
              data.map((json) => Favorite.fromJson(json)).toList();
          isLoading = false;
          isError = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      print('Error fetching favorites: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  Future<void> _deleteFavorite(String idProduk) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://citrakosmetik.my.id/delete_favorite.php',
        data: {'id_user': idUser, 'id_produk': idProduk},
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _fetchFavorite();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menghapus produk')));
      }
    } catch (e) {
      print('Error deleting favorite: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan')));
    }
  }

  void _showDeleteDialog(BuildContext context, String idProduk) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Yakin ingin menghapus dari favorit?'),
            actions: [
              TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteFavorite(idProduk);
                },
              ),
            ],
          ),
    );
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.only(top: 7.0),
          child: Text(
            'Favorit Saya',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => KeranjangScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded),
            onPressed: () => launchWhatsApp(),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : isError
                ? const Center(child: Text('Gagal memuat produk favorit.'))
                : favoriteProducts.isEmpty
                ? const Center(child: Text('Favorit Kosong'))
                : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: favoriteProducts.length,
                  itemBuilder: (context, index) {
                    return FavoriteItem(
                      favorite: favoriteProducts[index],
                      onDelete:
                          () => _showDeleteDialog(
                            context,
                            favoriteProducts[index].id,
                          ),
                    );
                  },
                ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
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

class FavoriteItem extends StatelessWidget {
  final Favorite favorite;
  final VoidCallback onDelete;

  const FavoriteItem({
    super.key,
    required this.favorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    DetailFavorite(favorite: favorite), // Produk yang dipilih
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Image.network(
                      favorite.gambar.isNotEmpty
                          ? favorite.gambar[0]
                          : '', // Menampilkan gambar pertama
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 60),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.merek,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formatRupiah(favorite.harga),
                        style: const TextStyle(fontSize: 14, color: Colors.red),
                      ),
                      const SizedBox(height: 5),
                      const Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            '4.8 | 10k terjual',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

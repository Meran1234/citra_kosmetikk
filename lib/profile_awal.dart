import 'package:citra_kosmetik/register_screen.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:citra_kosmetik/dashboard_awal.dart';

class ProfileAwal extends StatelessWidget {
  const ProfileAwal({super.key});

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
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            "Log In",
                            style: TextStyle(
                              color: Colors.blue, // Set the color to blue
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: const Text(
                            "Daftar",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
              MaterialPageRoute(builder: (context) => const DashboardAwal()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
      ),
    );
  }
}

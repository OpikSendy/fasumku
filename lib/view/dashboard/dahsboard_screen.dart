import 'package:fasumku/widgets/buttons/custom_bottom_bar.dart';
import 'package:fasumku/widgets/buttons/report_button.dart';
import 'package:flutter/material.dart';
import 'package:fasumku/widgets/card/report_card_dahsboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      floatingActionButton: ReportButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      backgroundColor: Colors.grey[200],
      bottomNavigationBar: CustomBottomAppBar(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 16), // Atur tinggi AppBar
        child: Container(
          width: double.infinity,
          color: const Color(0xFF4054B2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  // Red block for logo
                  Container(
                    width: 24,
                    height: 24,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 2),
                  // Blue block for logo
                  Container(
                    width: 24,
                    height: 24,
                    color: Colors.lightBlue,
                  ),
                  const SizedBox(width: 8),
                  // Text logo
                  const Text(
                    'FASUMKU',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              // Greeting
              const Text(
                'Hi, Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),

              // Notification icon
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, '/report');
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const ReportCard(
              title: 'Jenis',
              items: [
                ReportItem(name: 'Jalan Rusak', count: 10),
                ReportItem(name: 'Gapura', count: 6),
                ReportItem(name: 'Lampu Jalan', count: 4),
              ],
            ),
            const SizedBox(height: 16),

            // Categories Section
            const ReportCard(
              title: 'Kategori',
              items: [
                ReportItem(name: 'Parah', count: 10),
                ReportItem(name: 'Sedang', count: 6),
                ReportItem(name: 'Kecil', count: 4),
              ],
            ),
            const SizedBox(height: 16),

            // Completed Section
            const ReportCard(
              title: 'Selesai',
              items: [
                ReportItem(name: 'Jalan Rusak', count: 10),
                ReportItem(name: 'Lampu Jalan', count: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


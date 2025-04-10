import 'package:flutter/material.dart';

class ReportButton extends StatelessWidget {
  const ReportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 75,
      height: 75,
      child: FloatingActionButton(
        backgroundColor: const Color(0xFF2196F3),
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/scan');
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(35),
        ),
        elevation: 0,
        child: const Icon(
          Icons.camera_alt,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class PingMetricCard extends StatelessWidget {
  final String title;
  final String value;

  const PingMetricCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

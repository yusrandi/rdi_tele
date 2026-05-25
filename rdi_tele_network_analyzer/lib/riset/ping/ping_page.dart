import 'dart:async';

import 'package:flutter/material.dart';

import 'ping_result.dart';
import 'ping_service.dart';
import 'ping_metric_card.dart';

class PingPage extends StatefulWidget {
  const PingPage({super.key});

  @override
  State<PingPage> createState() => _PingPageState();
}

class _PingPageState extends State<PingPage> {
  final PingService _pingService = PingService();

  StreamSubscription? _pingSubscription;

  double realtimePing = 0;

  double averagePing = 0;
  double jitter = 0;

  List<double> rawPings = [];

  bool testing = false;

  @override
  void initState() {
    super.initState();

    /// realtime listener
    _pingSubscription = _pingService.pingStream.listen((ping) {
      setState(() {
        realtimePing = ping;
      });
    });
  }

  /// =====================================================
  /// START TEST
  /// =====================================================

  Future<void> startTest() async {
    setState(() {
      testing = true;

      realtimePing = 0;
      averagePing = 0;
      jitter = 0;

      rawPings = [];
    });

    final PingResult result = await _pingService.startPingTest();

    setState(() {
      testing = false;

      averagePing = result.averagePing;

      jitter = result.jitter;

      rawPings = result.pings;
    });
  }

  @override
  void dispose() {
    _pingSubscription?.cancel();

    _pingService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ping Analyzer')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PingMetricCard(
              title: 'Realtime Ping',
              value: '${realtimePing.toStringAsFixed(0)} ms',
            ),

            const SizedBox(height: 20),

            PingMetricCard(
              title: 'Average Ping',
              value: '${averagePing.toStringAsFixed(2)} ms',
            ),

            PingMetricCard(
              title: 'Jitter',
              value: '${jitter.toStringAsFixed(2)} ms',
            ),

            const SizedBox(height: 30),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rawPings
                  .map((e) => Chip(label: Text('${e.toStringAsFixed(0)} ms')))
                  .toList(),
            ),

            const SizedBox(height: 40),

            testing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: startTest,
                    child: const Text('START TEST'),
                  ),
          ],
        ),
      ),
    );
  }
}

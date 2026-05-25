import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realspeed_analyzer/utils/network_logger.dart';

class ConsoleLogger extends StatefulWidget {
  const ConsoleLogger({super.key});

  @override
  State<ConsoleLogger> createState() => _ConsoleLoggerState();
}

class _ConsoleLoggerState extends State<ConsoleLogger> {
  final NetworkLogger _logger = NetworkLogger();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header dengan tombol clear
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Console Output',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 16),
                  color: Colors.white70,
                  onPressed: () {
                    setState(() {
                      _logger.clear();
                    });
                  },
                  tooltip: 'Clear logs',
                ),
              ],
            ),
          ),

          // Log list
          Expanded(
            child: StreamBuilder<LogEntry>(
              stream: _logger.logStream,
              builder: (context, snapshot) {
                final logs = _logger.logs;

                if (logs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No logs yet...',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.all(8),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '[${DateFormat('HH:mm:ss').format(log.timestamp)}] ',
                              style: const TextStyle(color: Colors.white38),
                            ),
                            TextSpan(
                              text: '[${log.type}] ',
                              style: TextStyle(
                                color: _getLogColor(log.type),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: log.message,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String type) {
    switch (type) {
      case 'ERROR':
        return Colors.red;
      case 'SPEED':
        return Colors.green;
      case 'TELE':
        return Colors.blue;
      case 'LOC':
        return Colors.orange;
      case 'SESSION':
        return Colors.purple;
      case 'SYSTEM':
        return Colors.cyan;
      default:
        return Colors.white70;
    }
  }
}

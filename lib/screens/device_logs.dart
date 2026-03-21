import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';

class DeviceLogsPage extends StatelessWidget {
  final String deviceId;

  const DeviceLogsPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Device History: $deviceId",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder(
            stream: FirebaseDatabase.instance.ref("logs/$deviceId").onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              }

              final data = snapshot.data?.snapshot.value as Map?;

              if (data == null || data.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.white10),
                      const SizedBox(height: 16),
                      Text('No logs found for this device', style: TextStyle(color: AppColors.textBody)),
                    ],
                  ),
                );
              }

              // Transform and sort logs by timestamp
              final logsList = data.entries.map((e) {
                final val = Map<String, dynamic>.from(e.value as Map);
                return {
                  'status': val['status']?.toString() ?? 'Unknown',
                  'timestamp': val['timestamp'] ?? 0,
                };
              }).toList();

              logsList.sort((a, b) => (b['timestamp'] as num).compareTo(a['timestamp'] as num));

              return ListView.builder(
                itemCount: logsList.length,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemBuilder: (context, index) {
                  final log = logsList[index];
                  final timestamp = log['timestamp'] as num;
                  final dt = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
                  final isTripped = log['status'].toString().toUpperCase() == 'TRIPPED' || 
                                    log['status'].toString().toUpperCase() == 'DANGER';

                  return FadeInUp(
                    delay: Duration(milliseconds: index * 50),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isTripped ? AppColors.statusTripped : AppColors.statusStable).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isTripped ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                              color: isTripped ? AppColors.statusTripped : AppColors.statusStable,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log['status'].toString().toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isTripped ? AppColors.statusTripped : AppColors.statusStable,
                                  ),
                                ),
                                Text(
                                  DateFormat('EEEE, MMM d • hh:mm a').format(dt),
                                  style: const TextStyle(color: AppColors.textBody, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(dt),
                            style: GoogleFonts.outfit(
                              color: AppColors.textBody.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
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
      ),
    );
  }
}

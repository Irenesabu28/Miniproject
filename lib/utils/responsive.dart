import 'package:flutter/material.dart';
import 'theme.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Apply mobile view constraints on large screens (Web/Desktop)
        final bool isLargeScreen = constraints.maxWidth > 500;
        
        Widget mainContent = Stack(
          children: [
            // Main App Content
            Padding(
              padding: EdgeInsets.only(top: isLargeScreen ? 44 : 0),
              child: child,
            ),
            
            if (isLargeScreen) ...[
              // Mock Status Bar / Notch Area
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 44,
                  width: double.infinity,
                  color: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '9:41',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      // Symbolic Notch
                      Container(
                        width: 120,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Icon(Icons.wifi, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Icon(Icons.battery_full_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Home Indicator Mock
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: 140,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        );

        if (!isLargeScreen) return mainContent;

        return Material(
          color: const Color(0xFF020617), // Deep space background
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: mainContent,
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'theme.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop breakpoint
        if (constraints.maxWidth > 500) {
          return Material(
            color: const Color(0xFF020617), 
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 80,
                      spreadRadius: 5,
                      offset: const Offset(0, 40),
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 9 / 19.5, // Modern smartphone aspect ratio
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: const Color(0xFF334155), // Graphite/Dark Slate frame
                        width: 12,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Main App Content
                        Padding(
                          padding: const EdgeInsets.only(top: 40), // Account for Status Bar
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(38),
                            child: child,
                          ),
                        ),
                        
                        // Top Notch / Island
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 120,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E293B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 40),
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Status Bar Mock (Left)
                        const Positioned(
                          top: 15,
                          left: 35,
                          child: Text(
                            '9:41',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // Status Bar Mock (Right)
                        const Positioned(
                          top: 15,
                          right: 35,
                          child: Row(
                            children: [
                              Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Icon(Icons.wifi, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Icon(Icons.battery_full_rounded, color: Colors.white, size: 16),
                            ],
                          ),
                        ),

                        // Bottom Home Indicator
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            width: 120,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        
        // Mobile layout
        return child;
      },
    );
  }
}

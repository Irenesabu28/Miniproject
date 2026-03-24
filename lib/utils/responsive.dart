import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Apply mobile view constraints on large screens (Web/Desktop)
        final bool isLargeScreen = constraints.maxWidth > 500;
        
        Widget mainContent = child;

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

import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileScaffold;
  final Widget tabletScaffold;

  const ResponsiveLayout({
    super.key,
    required this.mobileScaffold,
    required this.tabletScaffold,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Genişlik 600'den küçükse mobil, büyükse tablet/web görünümü
        if (constraints.maxWidth < 600) {
          return mobileScaffold;
        } else {
          return tabletScaffold;
        }
      },
    );
  }
}

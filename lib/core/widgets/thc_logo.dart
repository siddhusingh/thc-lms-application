import 'package:flutter/material.dart';

class ThcLogo extends StatelessWidget {
  const ThcLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/thc-logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

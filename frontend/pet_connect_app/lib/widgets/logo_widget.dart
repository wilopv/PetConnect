import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  const LogoWidget({super.key, this.size = 50.0});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [kPrimaryColor, kAccentColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        'PetConnect',
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
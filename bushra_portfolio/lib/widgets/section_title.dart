import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.only(left: 16),
          height: 1,
          width: 60,
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
          ),
        ),
      ],
    );
  }
}

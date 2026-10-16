import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/portfolio_data.dart';
import '../widgets/section_title.dart';

class EducationSection extends StatelessWidget {
  const EducationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 800;
    final edu = PortfolioData.education;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80,
        vertical: 80,
      ),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Education',
            subtitle: 'Academic background',
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('🎓', style: TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${edu['degree']} – ${edu['branch']}',
                            style: GoogleFonts.inter(
                              fontSize: isNarrow ? 16 : 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            edu['college']!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            edu['graduation']!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(color: AppTheme.border),
                const SizedBox(height: 24),
                Text(
                  'Academic Performance',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),
                if (isNarrow)
                  Column(
                    children: [
                      _CGPABar(
                          label: 'Semester 4',
                          cgpa: edu['sem4']!,
                          maxCgpa: 10,
                          color: AppTheme.accent),
                      const SizedBox(height: 16),
                      _CGPABar(
                          label: 'Semester 3',
                          cgpa: edu['sem3']!,
                          maxCgpa: 10,
                          color: AppTheme.accentSecondary),
                      const SizedBox(height: 16),
                      _CGPABar(
                          label: 'First Year',
                          cgpa: edu['firstYear']!,
                          maxCgpa: 10,
                          color: AppTheme.accentTertiary),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _CGPACard(
                          label: 'Semester 4',
                          cgpa: edu['sem4']!,
                          color: AppTheme.accent,
                          isBest: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _CGPACard(
                          label: 'Semester 3',
                          cgpa: edu['sem3']!,
                          color: AppTheme.accentSecondary,
                          isBest: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _CGPACard(
                          label: 'First Year',
                          cgpa: edu['firstYear']!,
                          color: AppTheme.accentTertiary,
                          isBest: false,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CGPACard extends StatelessWidget {
  final String label;
  final String cgpa;
  final Color color;
  final bool isBest;

  const _CGPACard({
    required this.label,
    required this.cgpa,
    required this.color,
    required this.isBest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          if (isBest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Latest',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [color, color.withOpacity(0.7)],
            ).createShader(bounds),
            child: Text(
              cgpa,
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'out of 10',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _CGPABar extends StatelessWidget {
  final String label;
  final String cgpa;
  final int maxCgpa;
  final Color color;

  const _CGPABar({
    required this.label,
    required this.cgpa,
    required this.maxCgpa,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final value = double.tryParse(cgpa) ?? 0;
    final fraction = value / maxCgpa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.textSecondary)),
            Text(cgpa,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

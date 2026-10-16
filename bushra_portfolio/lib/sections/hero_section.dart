import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../theme/app_theme.dart';
import '../data/portfolio_data.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 800;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80,
        vertical: isNarrow ? 60 : 100,
      ),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: const Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Open to AI/ML Internship Opportunities',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.accentSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Hi, I\'m',
            style: GoogleFonts.inter(
              fontSize: isNarrow ? 18 : 22,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.heroGradient.createShader(bounds),
            child: Text(
              PortfolioData.name,
              style: GoogleFonts.inter(
                fontSize: isNarrow ? 48 : 72,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'I build ',
                style: GoogleFonts.inter(
                  fontSize: isNarrow ? 20 : 26,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              DefaultTextStyle(
                style: GoogleFonts.inter(
                  fontSize: isNarrow ? 20 : 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
                child: AnimatedTextKit(
                  repeatForever: true,
                  animatedTexts: [
                    TypewriterAnimatedText('AI Systems',
                        speed: const Duration(milliseconds: 80)),
                    TypewriterAnimatedText('Multi-Agent Platforms',
                        speed: const Duration(milliseconds: 80)),
                    TypewriterAnimatedText('Computer Vision Apps',
                        speed: const Duration(milliseconds: 80)),
                    TypewriterAnimatedText('Full-Stack Solutions',
                        speed: const Duration(milliseconds: 80)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              PortfolioData.summary,
              style: GoogleFonts.inter(
                fontSize: isNarrow ? 14 : 16,
                color: AppTheme.textSecondary,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              _LocationBadge(
                icon: Icons.location_on_outlined,
                label: PortfolioData.location,
              ),
              const SizedBox(width: 20),
              _LocationBadge(
                icon: Icons.school_outlined,
                label: 'B.E. CSE (AI & ML) · Sem 4: 9.61',
              ),
            ],
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _HeroCTA(
                label: 'View Projects',
                isPrimary: true,
                icon: Icons.rocket_launch_outlined,
                onTap: () {},
              ),
              _HeroCTA(
                label: 'Download Resume',
                isPrimary: false,
                icon: Icons.download_outlined,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LocationBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _HeroCTA extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final IconData icon;
  final VoidCallback onTap;

  const _HeroCTA({
    required this.label,
    required this.isPrimary,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HeroCTA> createState() => _HeroCTAState();
}

class _HeroCTAState extends State<_HeroCTA> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.isPrimary ? AppTheme.heroGradient : null,
            color: widget.isPrimary
                ? null
                : (_hovered ? AppTheme.card : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: widget.isPrimary
                ? null
                : Border.all(color: AppTheme.border),
            boxShadow: widget.isPrimary && _hovered
                ? [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

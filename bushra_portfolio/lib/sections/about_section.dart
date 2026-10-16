import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/portfolio_data.dart';
import '../widgets/section_title.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 800;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 24 : 80,
        vertical: 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'About Me',
            subtitle: 'Who I am & what I do',
          ),
          const SizedBox(height: 48),
          if (isNarrow)
            _buildContent(isNarrow)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildContent(isNarrow)),
                const SizedBox(width: 60),
                Expanded(flex: 2, child: _buildStats()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          PortfolioData.summary,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppTheme.textSecondary,
            height: 1.9,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _InfoBadge(icon: Icons.email_outlined, label: PortfolioData.email),
            _InfoBadge(icon: Icons.phone_outlined, label: PortfolioData.phone),
            _InfoBadge(
                icon: Icons.location_on_outlined,
                label: PortfolioData.location),
          ],
        ),
        if (isNarrow) ...[const SizedBox(height: 40), _buildStats()],
      ],
    );
  }

  Widget _buildStats() {
    final stats = [
      {'value': '9.61', 'label': 'Sem 4 CGPA', 'icon': '📊'},
      {'value': '3', 'label': 'AI Projects Built', 'icon': '🚀'},
      {'value': '1st', 'label': 'AICW 2.0 Rank', 'icon': '🏆'},
      {'value': '1', 'label': 'Paper Published', 'icon': '📄'},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: stats
          .map(
            (s) => _StatCard(
              value: s['value']!,
              label: s['label']!,
              emoji: s['icon']!,
            ),
          )
          .toList(),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;

  const _StatCard({
    required this.value,
    required this.label,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.heroGradient.createShader(bounds),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

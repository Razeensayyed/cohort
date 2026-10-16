import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/portfolio_data.dart';
import '../widgets/section_title.dart';

class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key});

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
            title: 'Achievements',
            subtitle: 'Awards, certifications & recognition',
          ),
          const SizedBox(height: 48),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: PortfolioData.achievements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _AchievementCard(
              achievement: PortfolioData.achievements[index],
              index: index,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatefulWidget {
  final Map<String, String> achievement;
  final int index;

  const _AchievementCard({required this.achievement, required this.index});

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard> {
  bool _hovered = false;

  static const List<Color> _colors = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    AppTheme.accent,
    AppTheme.accentSecondary,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[widget.index % _colors.length];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _hovered ? color.withOpacity(0.06) : AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? color.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  widget.achievement['emoji']!,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.achievement['title']!,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.achievement['description']!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

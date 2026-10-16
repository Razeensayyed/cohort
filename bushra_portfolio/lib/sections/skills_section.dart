import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/portfolio_data.dart';
import '../widgets/section_title.dart';
import '../widgets/skill_chip.dart';

class SkillsSection extends StatelessWidget {
  const SkillsSection({super.key});

  static const List<Color> _categoryColors = [
    AppTheme.accent,
    AppTheme.accentSecondary,
    AppTheme.accentTertiary,
    Color(0xFFFFB347),
  ];

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 800;

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
            title: 'Technical Skills',
            subtitle: 'Technologies & tools I work with',
          ),
          const SizedBox(height: 48),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isNarrow ? 1 : 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: isNarrow ? 1.6 : 1.4,
            ),
            itemCount: PortfolioData.skills.length,
            itemBuilder: (context, index) {
              final skill = PortfolioData.skills[index];
              final color = _categoryColors[index % _categoryColors.length];
              return _SkillCategory(
                skill: skill,
                color: color,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SkillCategory extends StatelessWidget {
  final Map<String, dynamic> skill;
  final Color color;

  const _SkillCategory({required this.skill, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    skill['icon'] as String,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                skill['category'] as String,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (skill['items'] as List<String>)
                .map((item) => SkillChip(label: item, color: color))
                .toList(),
          ),
        ],
      ),
    );
  }
}

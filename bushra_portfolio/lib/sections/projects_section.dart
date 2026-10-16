import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/portfolio_data.dart';
import '../widgets/section_title.dart';
import '../widgets/project_card.dart';

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

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
            title: 'Projects',
            subtitle: 'Things I\'ve built',
          ),
          const SizedBox(height: 48),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: PortfolioData.projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) => ProjectCard(
              project: PortfolioData.projects[index],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../sections/hero_section.dart';
import '../sections/about_section.dart';
import '../sections/skills_section.dart';
import '../sections/projects_section.dart';
import '../sections/education_section.dart';
import '../sections/achievements_section.dart';
import '../sections/contact_section.dart';
import '../widgets/nav_bar.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<GlobalKey> _sectionKeys = List.generate(6, (_) => GlobalKey());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          NavBar(sectionKeys: _sectionKeys),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HeroSection(),
                  KeyedSubtree(
                    key: _sectionKeys[0],
                    child: const AboutSection(),
                  ),
                  KeyedSubtree(
                    key: _sectionKeys[1],
                    child: const SkillsSection(),
                  ),
                  KeyedSubtree(
                    key: _sectionKeys[2],
                    child: const ProjectsSection(),
                  ),
                  KeyedSubtree(
                    key: _sectionKeys[3],
                    child: const EducationSection(),
                  ),
                  KeyedSubtree(
                    key: _sectionKeys[4],
                    child: const AchievementsSection(),
                  ),
                  KeyedSubtree(
                    key: _sectionKeys[5],
                    child: const ContactSection(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

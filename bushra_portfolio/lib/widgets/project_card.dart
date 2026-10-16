import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ProjectCard extends StatefulWidget {
  final Map<String, String> project;

  const ProjectCard({super.key, required this.project});

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(widget.project['color']!));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? color.withOpacity(0.5) : AppTheme.border,
            width: 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 24,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.project['emoji']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.project['title']!,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.project['subtitle']!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                widget.project['description']!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  widget.project['tech']!,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

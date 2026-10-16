import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SkillChip extends StatefulWidget {
  final String label;
  final Color color;

  const SkillChip({super.key, required this.label, required this.color});

  @override
  State<SkillChip> createState() => _SkillChipState();
}

class _SkillChipState extends State<SkillChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered ? widget.color.withOpacity(0.15) : AppTheme.card,
          border: Border.all(
            color: _hovered ? widget.color : AppTheme.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _hovered ? widget.color : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

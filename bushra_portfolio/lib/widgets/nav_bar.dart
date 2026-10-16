import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class NavBar extends StatefulWidget {
  final List<GlobalKey> sectionKeys;

  const NavBar({super.key, required this.sectionKeys});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _activeIndex = 0;

  final List<String> _labels = [
    'About',
    'Skills',
    'Projects',
    'Education',
    'Achievements',
    'Contact',
  ];

  void _scrollTo(int index) {
    setState(() => _activeIndex = index);
    final ctx = widget.sectionKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 700;

    return Container(
      color: AppTheme.background.withOpacity(0.95),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 16 : 40,
              vertical: 16,
            ),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.heroGradient.createShader(bounds),
                  child: Text(
                    'BK.',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                if (!isNarrow)
                  Row(
                    children: List.generate(
                      _labels.length,
                      (i) => _NavItem(
                        label: _labels[i],
                        isActive: _activeIndex == i,
                        onTap: () => _scrollTo(i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: AppTheme.border),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight:
                  widget.isActive ? FontWeight.w600 : FontWeight.w400,
              color: widget.isActive || _hovered
                  ? AppTheme.accent
                  : AppTheme.textSecondary,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

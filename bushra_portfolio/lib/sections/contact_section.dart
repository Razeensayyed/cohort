import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../data/portfolio_data.dart';
import '../widgets/section_title.dart';

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 800;

    final contacts = [
      {
        'icon': Icons.email_outlined,
        'label': 'Email',
        'value': PortfolioData.email,
        'url': 'mailto:${PortfolioData.email}',
        'color': const Color(0xFFFF6B6B),
      },
      {
        'icon': Icons.code,
        'label': 'GitHub',
        'value': 'github.com/bushrakazi68-arch',
        'url': PortfolioData.github,
        'color': AppTheme.accent,
      },
      {
        'icon': Icons.work_outline,
        'label': 'LinkedIn',
        'value': 'Bushra Kazi',
        'url': PortfolioData.linkedin,
        'color': AppTheme.accentSecondary,
      },
    ];

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
            title: 'Contact',
            subtitle: 'Let\'s connect & collaborate',
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.heroGradient.createShader(bounds),
                  child: Text(
                    'Let\'s Build Something Together',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: isNarrow ? 24 : 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'I\'m currently open to AI/ML or software engineering internship opportunities. Feel free to reach out!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: contacts.map((c) {
                    return _ContactButton(
                      icon: c['icon'] as IconData,
                      label: c['label'] as String,
                      value: c['value'] as String,
                      color: c['color'] as Color,
                      onTap: () => _launchUrl(c['url'] as String),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                Container(height: 1, color: AppTheme.border),
                const SizedBox(height: 24),
                Text(
                  '© 2026 Bushra Kazi · Built with Flutter 💙',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ContactButton> createState() => _ContactButtonState();
}

class _ContactButtonState extends State<_ContactButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withOpacity(0.1)
                : AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? widget.color : AppTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: widget.color),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    widget.value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _hovered ? widget.color : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

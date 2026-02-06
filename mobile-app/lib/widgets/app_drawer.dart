import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';

/// App drawer with settings and links
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Theme section
            Row(
              children: [
                Icon(
                  Icons.palette,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Theme',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildThemeSelector(context, settings),
            const Divider(height: 32),

            // Links section
            Row(
              children: [
                Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Links',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSocialLinks(context),
            const SizedBox(height: 16),
            _buildProjectLinks(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsProvider settings) {
    return Row(
      children: [
        _buildThemeOption(
          context,
          icon: Icons.computer,
          label: 'System',
          isSelected: settings.themeMode == ThemeMode.system,
          onTap: () => settings.setThemeMode(ThemeMode.system),
        ),
        const SizedBox(width: 8),
        _buildThemeOption(
          context,
          icon: Icons.light_mode,
          label: 'Light',
          isSelected: settings.themeMode == ThemeMode.light,
          onTap: () => settings.setThemeMode(ThemeMode.light),
        ),
        const SizedBox(width: 8),
        _buildThemeOption(
          context,
          icon: Icons.dark_mode,
          label: 'Dark',
          isSelected: settings.themeMode == ThemeMode.dark,
          onTap: () => settings.setThemeMode(ThemeMode.dark),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLinks(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          context,
          icon: Icons.code,
          color: Colors.grey,
          url: 'https://github.com/shubhattin/svara_darshini',
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          context,
          icon: Icons.play_circle_fill,
          color: Colors.red,
          url: 'https://www.youtube.com/@TheSanskritChannel',
        ),
        const SizedBox(width: 16),
        _buildSocialButton(
          context,
          icon: Icons.camera_alt,
          color: Colors.pink,
          url: 'https://www.instagram.com/thesanskritchannel/',
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildProjectLinks(BuildContext context) {
    return Column(
      children: [
        _buildProjectLinkTile(
          context,
          title: 'Projects',
          subtitle: 'Sanskrit Channel Projects',
          iconColor: Colors.green,
          icon: Icons.menu_book,
          url: 'http://projects.thesanskritchannel.org/',
        ),
        const SizedBox(height: 8),
        _buildProjectLinkTile(
          context,
          title: 'Padavali',
          subtitle: 'A Sanskrit Word Game',
          iconColor: Colors.indigo,
          icon: Icons.extension,
          url: 'https://krida.thesanskritchannel.org/padavali',
        ),
        const SizedBox(height: 8),
        _buildProjectLinkTile(
          context,
          title: 'Akshara Shikshaka',
          subtitle: 'Learn to Write Indian Scripts',
          iconColor: Colors.orange,
          icon: Icons.edit,
          url: 'https://akshara.thesanskritchannel.org/',
        ),
        const SizedBox(height: 8),
        _buildProjectLinkTile(
          context,
          title: 'Lipi Lekhika',
          subtitle: 'Type Indian Languages',
          iconColor: Colors.purple,
          icon: Icons.keyboard,
          url: 'https://lipilekhika.in',
        ),
      ],
    );
  }

  Widget _buildProjectLinkTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color iconColor,
    required IconData icon,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor, iconColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

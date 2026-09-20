import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../core/theme_controller.dart';
import '../data/app_backup_repository.dart';

/// Tela de Configurações: tema claro/escuro, exportar/importar backup
/// das matérias e informações sobre o app.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _sectionTitleStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: kAccentColor,
  );

  Future<void> _exportConfig(BuildContext context) async {
    try {
      final path = await AppBackupRepository().exportToFile();
      if (path != null && context.mounted) {
        _showSnack(context, 'Backup exportado com sucesso!', Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Erro ao exportar: $e', Colors.red);
      }
    }
  }

  Future<void> _importConfig(BuildContext context) async {
    try {
      final imported = await AppBackupRepository().importFromFile();
      if (imported && context.mounted) {
        _showSnack(
          context,
          'Backup restaurado! Reinicie o app para aplicar.',
          Colors.green,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Erro ao importar: $e', Colors.red);
      }
    }
  }

  // Método posicionado corretamente DENTRO da classe SettingsScreen
  Future<void> _launchGitHubUrl(BuildContext context) async {
    final Uri url = Uri.parse('https://github.com/xgustus');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          _showSnack(context, 'Não foi possível abrir o link', Colors.red);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Erro ao abrir o link: $e', Colors.red);
      }
    }
  }

  void _showSnack(
      BuildContext context,
      String message,
      Color color, {
        Duration? duration,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('APARÊNCIA DA AGENDA', style: _sectionTitleStyle),
            ),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeController,
              builder: (context, currentMode, _) {
                final isDark = currentMode == ThemeMode.dark;
                return ListTile(
                  leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('Modo Escuro'),
                  trailing: Switch(
                    value: isDark,
                    activeThumbColor: kAccentColor,
                    onChanged: themeController.setDarkMode,
                  ),
                );
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('BACKUP COMPLETO', style: _sectionTitleStyle),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_rounded),
              title: const Text('Exportar Tudo'),
              subtitle: const Text(
                '(Matérias, tarefas e CubeTimer)',
              ),
              onTap: () => _exportConfig(context),
            ),
            ListTile(
              leading: const Icon(Icons.file_download_rounded),
              title: const Text('Importar Tudo'),
              subtitle: const Text(
                '(sobrescreve os dados atuais)',
              ),
              onTap: () => _importConfig(context),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('SOBRE O APLICATIVO', style: _sectionTitleStyle),
            ),
            const ListTile(
              leading: Icon(Icons.code),
              title: Text('Desenvolvedor'),
              subtitle: Text('XGustus'),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Github'),
              subtitle: const Text(
                'https://github.com/xgustus',
                style: TextStyle(
                  color: kAccentColor,
                ),
              ),
              onTap: () => _launchGitHubUrl(context),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Versão'),
              subtitle: Text('1.0.3'),
            ),
          ],
        ),
      ),
    );
  }
}
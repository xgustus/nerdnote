import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// Controla o tema (claro/escuro) do app e mantém a escolha do usuário
/// salva no dispositivo.
///
/// É um [ValueNotifier], então qualquer widget pode "ouvir" mudanças de
/// tema com um [ValueListenableBuilder] — é assim que [AgendaMedonhaApp]
/// e a tela de Configurações reagem à troca de tema.
///
/// Isso substitui a antiga variável global solta `themeNotifier` do
/// main.dart: agora a lógica de carregar/salvar mora junto com o estado.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.dark);

  /// Lê a preferência salva (padrão: modo escuro) e atualiza [value].
  /// Deve ser chamado uma única vez, antes do `runApp`.
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(PrefsKeys.isDarkMode) ?? true;
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Troca o tema e já persiste a escolha. Usado pelo Switch da tela de
  /// Configurações.
  Future<void> setDarkMode(bool isDark) async {
    value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.isDarkMode, isDark);
  }
}

/// Instância única (singleton simples) compartilhada por todo o app.
final themeController = ThemeController();

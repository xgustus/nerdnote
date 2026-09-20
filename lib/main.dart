import 'package:flutter/material.dart';
import 'app.dart';
import 'core/theme_controller.dart';

/// Ponto de entrada da aplicação.
///
/// Antes essa função também continha a criação do MaterialApp; agora ela
/// só cuida de "ligar" o app (inicializar plugins e carregar o tema) —
/// o widget da aplicação em si mora em `app.dart`.
void main() async {
  // Garante que os plugins nativos (SharedPreferences, etc.) estejam
  // prontos antes de qualquer chamada assíncrona abaixo.
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega o tema salvo (claro/escuro) antes de desenhar a primeira
  // tela, para evitar o "flash" de tema errado ao abrir o app.
  await themeController.loadSavedTheme();

  runApp(const NerdNoteApp());
}
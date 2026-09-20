import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants.dart';
import 'core/theme_controller.dart';
import 'screens/home_screen.dart';

/// Widget raiz do aplicativo: define tema, idioma e a tela inicial.
///
/// Ficava tudo dentro de `MyApp` no antigo main.dart; foi movido para cá
/// para que main.dart fique só com a inicialização (bootstrap) do app.
class NerdNoteApp extends StatelessWidget {
  const NerdNoteApp({super.key});

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kAccentColor,
      brightness: Brightness.light,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: kAccentColor,
      selectionColor: kAccentColor.withValues(alpha: 0.4),
      selectionHandleColor: kAccentColor,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kAccentColor,
      brightness: Brightness.dark,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: kAccentColor,
      selectionColor: kAccentColor.withValues(alpha: 0.4),
      selectionHandleColor: kAccentColor,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Reconstrói o MaterialApp sempre que o tema mudar (claro <-> escuro).
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'NerdNote',
          debugShowCheckedModeBanner: false,

          themeMode: currentMode,
          theme: _lightTheme,
          darkTheme: _darkTheme,

          // Faz os widgets nativos (DatePicker, TimePicker etc.)
          // aparecerem em português do Brasil.
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
          locale: const Locale('pt', 'BR'),

          home: const HomeScreen(),
        );
      },
    );
  }
}
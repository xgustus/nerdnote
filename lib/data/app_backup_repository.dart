import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// Exporta e importa um backup ÚNICO (.json) com TODOS os dados do
/// app: matérias cadastradas, aulas marcadas no horário semanal,
/// tarefas e tempos do CubeTimer — além da preferência de tema.
///
/// Antes existia um backup parcial (só matérias, em
/// `backup_repository.dart`); esta classe substitui aquela e unifica
/// tudo em um arquivo só, o que permite migrar o app inteiro para
/// outro celular de uma vez.
class AppBackupRepository {
  static const int _formatVersion = 3;

  /// Gera o arquivo de backup completo e abre o seletor "Salvar como".
  /// Retorna o caminho escolhido pelo usuário, ou `null` se ele
  /// cancelou.
  Future<String?> exportToFile() async {
    final prefs = await SharedPreferences.getInstance();

    final backup = {
      'format_version': _formatVersion,
      'export_date': DateTime.now().toIso8601String(),
      'subjects': _decodeList(prefs.getString(PrefsKeys.subjects)),
      'registered_subjects':
          _decodeList(prefs.getString(PrefsKeys.registeredSubjects)),
      'tasks': _decodeList(prefs.getString(PrefsKeys.tasks)),
      'cube_solves': _decodeList(prefs.getString(PrefsKeys.cubeSolves)),
      // Desde a v3 do formato, a imagem de fundo do CubeTimer é salva
      // como base64 (não mais como caminho de arquivo), então ela é um
      // dado autocontido e pode entrar no backup sem virar uma
      // referência quebrada em outro aparelho.
      'cube_timer_bg_image': prefs.getString(PrefsKeys.cubeTimerBgImage) ?? '',
      'is_dark_mode': prefs.getBool(PrefsKeys.isDarkMode) ?? true,
    };

    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(backup)),
    );

    final uri = await FilePicker.saveFile(
      dialogTitle: 'Onde deseja salvar o backup?',
      fileName: 'nerdnote_backup.json',
      bytes: bytes,
    );

    return uri?.path;
  }

  /// Abre o seletor de arquivos, lê um backup .json e sobrescreve
  /// TODOS os dados salvos localmente (matérias, tarefas, tempos do
  /// cubo mágico e tema).
  ///
  /// Retorna `false` se o usuário cancelou a seleção do arquivo (não é
  /// um erro). Lança uma [Exception] se o arquivo escolhido não tiver a
  /// estrutura mínima esperada.
  Future<bool> importFromFile() async {
    final pickedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (pickedFile == null) return false;

    // Desde o file_picker 12, `PlatformFile.bytes` não existe mais: os
    // bytes são lidos sob demanda com `readAsBytes()`, que funciona em
    // todas as plataformas (inclusive web, onde não há `path`).
    final contents = utf8.decode(await pickedFile.readAsBytes());

    final data = jsonDecode(contents) as Map<String, dynamic>;

    // Backups antigos (de antes da unificação) só tinham 'subjects' e
    // 'registered_subjects' — continuam sendo aceitos aqui, só que sem
    // tarefas/tempos/tema para restaurar.
    if (!data.containsKey('subjects') ||
        !data.containsKey('registered_subjects')) {
      throw Exception('Arquivo de backup inválido.');
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      PrefsKeys.subjects,
      jsonEncode(data['subjects']),
    );
    await prefs.setString(
      PrefsKeys.registeredSubjects,
      jsonEncode(data['registered_subjects']),
    );

    if (data.containsKey('tasks')) {
      await prefs.setString(PrefsKeys.tasks, jsonEncode(data['tasks']));
    }
    if (data.containsKey('cube_solves')) {
      await prefs.setString(
        PrefsKeys.cubeSolves,
        jsonEncode(data['cube_solves']),
      );
    }
    if (data.containsKey('cube_timer_bg_image')) {
      await prefs.setString(
        PrefsKeys.cubeTimerBgImage,
        data['cube_timer_bg_image'] as String,
      );
    }
    if (data.containsKey('is_dark_mode')) {
      await prefs.setBool(PrefsKeys.isDarkMode, data['is_dark_mode'] as bool);
    }

    return true;
  }

  List<dynamic> _decodeList(String? json) =>
      json == null ? [] : jsonDecode(json) as List<dynamic>;
}

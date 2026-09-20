import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/registered_subject.dart';
import '../models/subject.dart';

/// Responsável por ler e gravar, no SharedPreferences, tudo que envolve
/// matérias: o catálogo ([RegisteredSubject]) e as aulas marcadas no
/// horário semanal ([Subject]).
///
/// Concentrar essas leituras/gravações aqui evita duplicar a lógica de
/// JSON em cada tela — antes `MatterScreen` e `TasksScreen` liam a
/// chave 'subjects' cada uma com seu próprio código.
class SubjectsRepository {
  /// Carrega a lista de aulas marcadas no horário semanal.
  Future<List<Subject>> loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(PrefsKeys.subjects);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((item) => Subject.fromJson(item)).toList();
  }

  /// Carrega o catálogo de matérias cadastradas (nome + professor).
  Future<List<RegisteredSubject>> loadRegisteredSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(PrefsKeys.registeredSubjects);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((item) => RegisteredSubject.fromJson(item)).toList();
  }

  /// Salva as duas listas de uma vez. É assim que a tela de Matérias
  /// sempre usa: qualquer alteração em uma pode afetar a outra (ex:
  /// renomear uma matéria do catálogo atualiza as aulas já marcadas).
  Future<void> save({
    required List<Subject> subjects,
    required List<RegisteredSubject> registeredSubjects,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PrefsKeys.subjects,
      jsonEncode(subjects.map((s) => s.toJson()).toList()),
    );
    await prefs.setString(
      PrefsKeys.registeredSubjects,
      jsonEncode(registeredSubjects.map((r) => r.toJson()).toList()),
    );
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/task.dart';

/// Responsável por ler e gravar as tarefas no SharedPreferences.
class TasksRepository {
  /// Carrega as tarefas salvas, já ordenadas por prazo (mais próximas
  /// primeiro) — a tela de Tarefas espera recebê-las assim.
  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(PrefsKeys.tasks);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    final tasks = list.map((item) => Task.fromJson(item)).toList();
    tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
    return tasks;
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PrefsKeys.tasks,
      jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
  }
}

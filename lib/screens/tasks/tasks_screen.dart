import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/subjects_repository.dart';
import '../../data/tasks_repository.dart';
import '../../models/registered_subject.dart';
import '../../models/subject.dart';
import '../../models/task.dart';
import 'task_form_sheet.dart';
import 'task_tile.dart';

/// Tela de Tarefas: lista as entregas pendentes com contagem regressiva
/// e permite criar, editar e concluir cada uma.
///
/// Esta tela é a "orquestradora": guarda o estado (`_tasks`,
/// `_subjects`) e decide o que fazer quando o usuário interage; o
/// visual de cada item mora em [TaskTile] e o formulário em
/// [showTaskFormSheet].
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _subjectsRepository = SubjectsRepository();
  final _tasksRepository = TasksRepository();

  List<Task> _tasks = [];
  List<Subject> _subjects = [];
  List<RegisteredSubject> _registeredSubjects = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Atualiza a tela a cada segundo para o contador regressivo andar
    // (o próprio `TaskTile` recalcula o tempo restante a cada rebuild).
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Precisa das matérias (`_subjects`) para saber os horários de cada
    // uma e sugerir prazos ao criar uma tarefa nova.
    final subjects = await _subjectsRepository.loadSubjects();
    final registered = await _subjectsRepository.loadRegisteredSubjects();
    final tasks = await _tasksRepository.loadTasks();
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      _registeredSubjects = registered;
      _tasks = tasks;
    });
  }

  /// Relê as matérias salvas. Necessário porque o `IndexedStack` da
  /// tela principal mantém esta tela viva o tempo todo: o `_loadData`
  /// do `initState` roda só uma vez, então matérias cadastradas depois
  /// (na aba Matérias) nunca chegariam aqui. Por isso o formulário de
  /// tarefa chama este método sempre que abre.
  Future<void> _refreshSubjects() async {
    final subjects = await _subjectsRepository.loadSubjects();
    final registered = await _subjectsRepository.loadRegisteredSubjects();
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      _registeredSubjects = registered;
    });
  }

  /// Nomes das matérias disponíveis para uma tarefa, sem repetição:
  /// todas as matérias cadastradas em "Minhas Matérias" (mesmo as que
  /// ainda não têm aula marcada no horário) mais as do horário semanal
  /// (que cobrem dados antigos/backups sem catálogo).
  List<String> get _subjectNames {
    final names = <String>[];
    for (final name in [
      ..._registeredSubjects.map((r) => r.name),
      ..._subjects.map((s) => s.name),
    ]) {
      if (name.isNotEmpty && !names.contains(name)) names.add(name);
    }
    return names;
  }

  /// Calcula a próxima data/horário em que uma matéria terá aula,
  /// olhando todos os horários dela na semana e escolhendo o mais
  /// próximo a partir de agora. Usado para sugerir o prazo de uma
  /// tarefa nova assim que o usuário escolhe a matéria no formulário.
  DateTime _getClosestOccurrence(String subjectName) {
    final occurrences = _subjects.where((s) => s.name == subjectName).toList();
    if (occurrences.isEmpty) {
      return DateTime.now().add(const Duration(days: 1));
    }

    final now = DateTime.now();
    final potentialDates = <DateTime>[];

    for (final occ in occurrences) {
      final targetWeekday = kWeekDayNumbers[occ.dayOfWeek] ?? 1;
      final timeParts = occ.time.split(':');
      final hour = timeParts.length == 2 ? int.parse(timeParts[0]) : 23;
      final minute = timeParts.length == 2 ? int.parse(timeParts[1]) : 59;

      var diffDays = targetWeekday - now.weekday;
      final alreadyPassedToday = diffDays == 0 &&
          (now.hour > hour || (now.hour == hour && now.minute >= minute));
      if (diffDays < 0 || alreadyPassedToday) diffDays += 7;

      potentialDates.add(
        DateTime(now.year, now.month, now.day, hour, minute)
            .add(Duration(days: diffDays)),
      );
    }

    potentialDates.sort();
    return potentialDates.first;
  }

  Future<void> _openTaskForm({Task? taskToEdit}) async {
    // Sempre relê as matérias antes de abrir, para refletir o que foi
    // cadastrado/alterado na aba Matérias desde a última vez.
    await _refreshSubjects();
    if (!mounted) return;
    showTaskFormSheet(
      context: context,
      subjectNames: _subjectNames,
      getClosestOccurrence: _getClosestOccurrence,
      taskToEdit: taskToEdit,
      onSave: (task, {required isNew}) {
        setState(() {
          if (isNew) _tasks.add(task);
          _tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
        });
        _tasksRepository.saveTasks(_tasks);
      },
    );
  }

  // Agora só alterna a marcação de concluída (troca a tarja do
  // TaskTile entre vermelha = pendente e verde = concluída); a tarefa continua na lista até ser apagada de
  // verdade pela lixeira (`_deleteTask`).
  void _toggleTaskCompleted(int index) {
    setState(() {
      final task = _tasks[index];
      task.completed = !task.completed;
    });
    _tasksRepository.saveTasks(_tasks);
  }

  void _deleteTask(int index) {
    setState(() => _tasks.removeAt(index));
    _tasksRepository.saveTasks(_tasks);
  }

  void _confirmDeleteTask(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Apagar tarefa'),
          content: const Text('Tem certeza de que deseja apagar esta tarefa?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteTask(index);
              },
              child: const Text('Apagar', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAccentColor,
        onPressed: () => _openTaskForm(),
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
      body: _tasks.isEmpty
          ? const Center(child: Text('Nenhuma tarefa pendente'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return TaskTile(
                  task: task,
                  onEdit: () => _openTaskForm(taskToEdit: task),
                  onComplete: () => _toggleTaskCompleted(index),
                  onDelete: () => _confirmDeleteTask(index),
                );
              },
            ),
    );
  }
}

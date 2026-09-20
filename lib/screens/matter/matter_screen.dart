import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/subjects_repository.dart';
import '../../models/registered_subject.dart';
import '../../models/subject.dart';
import 'day_column.dart';
import 'manage_subjects_sheet.dart';
import 'subject_time_form_sheet.dart';

/// Tela de Matérias: mostra o horário semanal (um cartão por dia) e dá
/// acesso ao cadastro geral de matérias (catálogo).
///
/// Assim como [TasksScreen], esta tela guarda o estado e delega o
/// visual/formulários para widgets e funções auxiliares em arquivos
/// separados ([DayColumn], [showManageSubjectsSheet],
/// [showSubjectTimeFormSheet]).
class MatterScreen extends StatefulWidget {
  const MatterScreen({super.key});

  @override
  State<MatterScreen> createState() => _MatterScreenState();
}

class _MatterScreenState extends State<MatterScreen> {
  final _repository = SubjectsRepository();

  List<Subject> _subjects = [];
  List<RegisteredSubject> _registeredSubjects = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final subjects = await _repository.loadSubjects();
    final registered = await _repository.loadRegisteredSubjects();
    setState(() {
      _subjects = subjects;
      _registeredSubjects = registered;
    });
  }

  Future<void> _saveData() => _repository.save(
        subjects: _subjects,
        registeredSubjects: _registeredSubjects,
      );

  List<Subject> _subjectsForDay(String day) {
    final list = _subjects.where((s) => s.dayOfWeek == day).toList();
    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  // --- Catálogo de matérias (RegisteredSubject) ---

  void _openManageSubjects() {
    showManageSubjectsSheet(
      context: context,
      registeredSubjects: _registeredSubjects,
      onAdd: (subject) {
        setState(() => _registeredSubjects.add(subject));
        _saveData();
      },
      onEdit: (index, updated, oldName) {
        setState(() {
          _registeredSubjects[index] = updated;
          // Propaga o novo nome/professor para todas as aulas já
          // marcadas dessa matéria no horário semanal.
          for (final subject in _subjects) {
            if (subject.name == oldName) {
              subject.name = updated.name;
              subject.teacher = updated.teacher;
            }
          }
        });
        _saveData();
      },
      onDelete: (index) {
        final nameToRemove = _registeredSubjects[index].name;
        setState(() {
          _registeredSubjects.removeAt(index);
          // Remove também as aulas dessa matéria do horário semanal,
          // já que ela deixou de existir no catálogo.
          _subjects.removeWhere((s) => s.name == nameToRemove);
        });
        _saveData();
      },
    );
  }

  // --- Aulas marcadas no horário (Subject) ---

  void _openSubjectTimeForm({required String day, Subject? subjectToEdit}) {
    showSubjectTimeFormSheet(
      context: context,
      dayContext: day,
      registeredSubjects: _registeredSubjects,
      subjectToEdit: subjectToEdit,
      onAdd: (subject) {
        setState(() => _subjects.add(subject));
        _saveData();
      },
      onEditTime: (subject, newTime) {
        setState(() => subject.time = newTime);
        _saveData();
      },
    );
  }

  void _deleteSubject(Subject subject) {
    setState(() => _subjects.remove(subject));
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScrollConfiguration(
        // Habilita rolar a lista de dias arrastando com o mouse/trackpad
        // (útil em desktop/web), além do toque normal.
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: SafeArea(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            // +1 = o botão "Matérias" que fica fixo ao final da lista.
            itemCount: kWeekDays.length + 1,
            itemBuilder: (context, index) {
              if (index == kWeekDays.length) {
                return _ManageSubjectsButton(onTap: _openManageSubjects);
              }

              final day = kWeekDays[index];
              return DayColumn(
                day: day,
                subjects: _subjectsForDay(day),
                onAddClass: () => _openSubjectTimeForm(day: day),
                onEditClass: (subject) =>
                    _openSubjectTimeForm(day: day, subjectToEdit: subject),
                onDeleteClass: _deleteSubject,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Botão fixo ao final da lista horizontal de dias, que abre o
/// catálogo de matérias.
class _ManageSubjectsButton extends StatelessWidget {
  const _ManageSubjectsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: kAccentColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: -5),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: onTap,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings),
                SizedBox(width: 8),
                Text('Matérias',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, height: 1.1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

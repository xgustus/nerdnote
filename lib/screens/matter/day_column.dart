import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/subject.dart';

/// Um "cartão" de dia da semana, com a lista de aulas marcadas para
/// aquele dia e um botão para adicionar uma nova aula.
class DayColumn extends StatelessWidget {
  const DayColumn({
    super.key,
    required this.day,
    required this.subjects,
    required this.onAddClass,
    required this.onEditClass,
    required this.onDeleteClass,
  });

  final String day;
  final List<Subject> subjects;
  final VoidCallback onAddClass;
  final void Function(Subject subject) onEditClass;
  final void Function(Subject subject) onDeleteClass;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kAccentColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              day.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                color: kAccentColor,
              ),
            ),
          ),
          Expanded(
            child: subjects.isEmpty
                ? Center(
              child: Text(
                'Nenhuma aula',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: subjects.length,
              itemBuilder: (context, i) {
                final item = subjects[i];
                return Card(
                  elevation: 0,
                  color: kAccentColor.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item.time} • ${item.teacher}',
                        style: const TextStyle(fontSize: 12)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEditClass(item);
                        if (value == 'delete') onDeleteClass(item);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Editar')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Remover',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          InkWell(
            onTap: onAddClass,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Icon(Icons.add_circle_outline_rounded,
                  color: kAccentColor, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}
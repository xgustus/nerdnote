import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/task.dart';

/// Um item da lista de tarefas: mostra o contador regressivo, o título
/// e a matéria; ao expandir, mostra a descrição e os botões de
/// editar/concluir.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onComplete,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  /// Formata o tempo restante até o prazo como "HH:MM:SS", ou
  /// "EXPIRADO" se o prazo já passou. A tela pai (`TasksScreen`) chama
  /// `setState` a cada segundo, o que faz este texto se atualizar.
  String _timeRemaining() {
    final diff = task.deadline.difference(DateTime.now());
    if (diff.isNegative) return 'EXPIRADO';
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = task.deadline.isBefore(DateTime.now());
    final statusColor = isExpired ? Colors.redAccent : kAccentColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      // Stack para desenhar a tarja de status (vermelha = pendente,
      // verde = concluída) sobre o card, sem tirar a tarefa da lista.
      child: Stack(
        children: [
          ExpansionTile(
            // Remove as linhas divisórias que o ExpansionTile desenha por
            // padrão ao abrir/fechar.
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration:
                    task.completed ? TextDecoration.lineThrough : null,
                color: task.completed
                    ? Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)
                    : null,
              ),
            ),
            subtitle: Text(task.subjectName),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, color: statusColor, size: 20),
                Text(
                  _timeRemaining(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.content.isEmpty ? 'Sem descrição.' : task.content,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: kAccentColor),
                          tooltip: 'Editar',
                          onPressed: onEdit,
                        ),
                        IconButton(
                          icon: Icon(
                            task.completed
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          tooltip: task.completed
                              ? 'Marcar como não concluída'
                              : 'Marcar como concluída',
                          onPressed: onComplete,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Apagar',
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tarja no canto direito: vermelha enquanto a tarefa está
          // pendente e verde quando foi concluída. Fica sempre visível,
          // então dá pra bater o olho na lista e ver o que falta.
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 8,
                color: task.completed ? Colors.green : Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

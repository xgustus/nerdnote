import 'package:flutter/material.dart';
import '../core/time_format.dart';
import '../models/cube_solve.dart';

/// Critérios de ordenação do histórico de solves.
enum SolveSort {
  /// Menor tempo primeiro (DNF vai para o fim). É o padrão.
  fastest,

  /// Mais recente primeiro.
  lastSession,
}

class SolvesHistoryModal extends StatefulWidget {
  final List<CubeSolve> solves;
  final Function(String id) onDeleteSolve;

  const SolvesHistoryModal({
    super.key,
    required this.solves,
    required this.onDeleteSolve,
  });

  @override
  State<SolvesHistoryModal> createState() => _SolvesHistoryModalState();
}

class _SolvesHistoryModalState extends State<SolvesHistoryModal> {
  SolveSort _sort = SolveSort.fastest;

  String _formatDate(DateTime date) {
    String d = date.day.toString().padLeft(2, '0');
    String m = date.month.toString().padLeft(2, '0');
    String y = date.year.toString();
    String hh = date.hour.toString().padLeft(2, '0');
    String mm = date.minute.toString().padLeft(2, '0');
    String ss = date.second.toString().padLeft(2, '0');

    return '$d/$m/$y - $hh:$mm:$ss';
  }

  /// Ordem crescente de tempo; DNF (-1) sempre por último. Empates são
  /// desempatados pela data (mais recente primeiro), porque o `sort`
  /// do Dart não é estável.
  int _compareByTime(CubeSolve a, CubeSolve b) {
    final timeA = a.effectiveTime;
    final timeB = b.effectiveTime;
    if (timeA == -1 && timeB == -1) return b.date.compareTo(a.date);
    if (timeA == -1) return 1;
    if (timeB == -1) return -1;
    final byTime = timeA.compareTo(timeB);
    return byTime != 0 ? byTime : b.date.compareTo(a.date);
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Apagar tempo'),
          content: const Text('Tem certeza de que deseja apagar esta solução?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                widget.onDeleteSolve(id);
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
    // A lista é ordenada conforme o critério escolhido e o `#` de cada
    // item é a sua posição nessa ordem (#1 = primeiro da lista):
    // - Última sessão: #1 é a solução mais recente.
    // - Tempo crescente: #1 é a solução mais rápida.
    final sortedSolves = List<CubeSolve>.from(widget.solves);
    if (_sort == SolveSort.lastSession) {
      sortedSolves.sort((a, b) => b.date.compareTo(a.date));
    } else {
      sortedSolves.sort(_compareByTime);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Histórico de Solves',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SegmentedButton<SolveSort>(
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: const [
              ButtonSegment(
                value: SolveSort.fastest,
                label: Text('Tempo crescente'),
              ),
              ButtonSegment(
                value: SolveSort.lastSession,
                label: Text('Última sessão'),
              ),
            ],
            selected: {_sort},
            onSelectionChanged: (selection) =>
                setState(() => _sort = selection.first),
          ),
          const Divider(),
          Expanded(
            child: sortedSolves.isEmpty
                ? const Center(child: Text('Nenhum tempo registrado.'))
                : ListView.builder(
              itemCount: sortedSolves.length,
              itemBuilder: (context, index) {
                final solve = sortedSolves[index];
                final effTime = solve.effectiveTime;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#${index + 1}  ${formatSolveTime(effTime)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _confirmDelete(context, solve.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatDate(solve.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

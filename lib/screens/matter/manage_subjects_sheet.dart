import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/registered_subject.dart';
import '../../widgets/app_text_field.dart';

/// Abre a folha (bottom sheet) "Minhas Matérias": lista, edita e remove
/// o catálogo de matérias, e permite cadastrar uma nova.
void showManageSubjectsSheet({
  required BuildContext context,
  required List<RegisteredSubject> registeredSubjects,
  required void Function(RegisteredSubject subject) onAdd,
  required void Function(int index, RegisteredSubject updated, String oldName)
  onEdit,
  required void Function(int index) onDelete,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (context) => StatefulBuilder(
      // `setModalState` só redesenha o conteúdo da folha, sem precisar
      // reabri-la — é assim que a lista atualiza na hora após
      // adicionar/editar/remover uma matéria.
      builder: (context, setModalState) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Container(
              width: 45,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400]?.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Minhas Matérias',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              '${registeredSubjects.length} disciplinas no total',
              style: TextStyle(
                  color: Colors.grey[500], fontSize: 13, letterSpacing: 0.5),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: registeredSubjects.isEmpty
                  ? Center(
                child: Text('Nenhuma matéria cadastrada.',
                    style: TextStyle(color: Colors.grey[400])),
              )
                  : ListView.builder(
                itemCount: registeredSubjects.length,
                padding: const EdgeInsets.only(bottom: 20),
                itemBuilder: (context, i) {
                  final subject = registeredSubjects[i];
                  return _RegisteredSubjectCard(
                    subject: subject,
                    onEdit: () => _showSubjectCatalogDialog(
                      context: context,
                      existing: subject,
                      onSave: (updated) {
                        onEdit(i, updated, subject.name);
                        setModalState(() {});
                      },
                    ),
                    onDelete: () {
                      onDelete(i);
                      setModalState(() {});
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 58),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: () => _showSubjectCatalogDialog(
                context: context,
                onSave: (added) {
                  onAdd(added);
                  setModalState(() {});
                },
              ),
              icon: const Icon(Icons.add_rounded, size: 24),
              label: const Text('CADASTRAR',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Card de uma matéria dentro da lista "Minhas Matérias".
class _RegisteredSubjectCard extends StatelessWidget {
  const _RegisteredSubjectCard({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
  });

  final RegisteredSubject subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  subject.teacher.isEmpty ? 'Sem professor' : subject.teacher,
                  style: TextStyle(
                      color: kAccentColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.edit, color: kAccentColor),
                onPressed: onEdit,
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Diálogo simples para cadastrar ou editar uma matéria do catálogo
/// (nome + professor). É privado a este arquivo porque só faz sentido
/// aberto a partir da folha "Minhas Matérias" acima.
void _showSubjectCatalogDialog({
  required BuildContext context,
  required void Function(RegisteredSubject subject) onSave,
  RegisteredSubject? existing,
}) {
  final nameController = TextEditingController(text: existing?.name);
  final teacherController = TextEditingController(text: existing?.teacher);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(existing == null ? 'Nova Matéria' : 'Editar Matéria'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
              controller: nameController, label: 'Nome', icon: Icons.book_rounded),
          const SizedBox(height: 12),
          AppTextField(
              controller: teacherController,
              label: 'Professor(a)',
              icon: Icons.person_rounded),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kAccentColor),
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isEmpty) return; // evita cadastrar matéria sem nome
            onSave(RegisteredSubject(
              name: name,
              teacher: teacherController.text.trim(),
            ));
            Navigator.pop(context);
          },
          child: const Text('Salvar',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/task.dart';
import '../../widgets/app_text_field.dart';

/// Abre o formulário (bottom sheet) de criação/edição de uma tarefa.
///
/// - [subjectNames] são os nomes das matérias que aparecem na escolha
///   (já sem repetição: vêm do catálogo de matérias cadastradas e das
///   aulas do horário semanal). A data sugerida ao escolher uma
///   matéria vem de [getClosestOccurrence].
/// - [onSave] é chamado com a tarefa pronta quando o usuário confirma;
///   `isNew` diz se é uma tarefa nova (deve ser adicionada à lista) ou
///   uma edição (a própria referência de [taskToEdit] já foi alterada).
void showTaskFormSheet({
  required BuildContext context,
  required List<String> subjectNames,
  required DateTime Function(String subjectName) getClosestOccurrence,
  required void Function(Task task, {required bool isNew}) onSave,
  Task? taskToEdit,
}) {
  final titleController = TextEditingController(text: taskToEdit?.title);
  final contentController = TextEditingController(text: taskToEdit?.content);
  DateTime selectedDateTime = taskToEdit?.deadline ?? DateTime.now();

  String? selectedName = taskToEdit?.subjectName;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                taskToEdit == null ? 'Nova Tarefa' : 'Editar Tarefa',
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Seletor de matéria. Antes usava DropdownButtonFormField,
              // mas no navegador (Flutter Web) o menu desse dropdown,
              // quando aberto dentro de um showModalBottomSheet, pode
              // ficar atrás do próprio modal e não responder ao toque
              // — um problema conhecido do Flutter Web com dropdowns
              // aninhados dentro de outro bottom sheet. Por isso usamos
              // o mesmo padrão já usado no seletor de data/hora logo
              // abaixo: um ListTile que abre a escolha em outro sheet.
              ListTile(
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(Icons.school, color: kAccentColor),
                title: Text(
                  selectedName ?? 'Selecione a matéria',
                  style: TextStyle(
                    color: selectedName == null
                        ? Theme.of(context).hintColor
                        : null,
                  ),
                ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: subjectNames.isEmpty
                    ? null
                    : () async {
                        final picked = await _showSubjectPicker(
                          context,
                          subjectNames,
                          selectedName,
                        );
                        if (picked == null) return;
                        setModalState(() {
                          selectedName = picked;
                          // Sugere automaticamente a próxima aula dessa
                          // matéria como prazo, agilizando o cadastro.
                          selectedDateTime = getClosestOccurrence(picked);
                        });
                      },
              ),
              if (subjectNames.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Nenhuma matéria cadastrada ainda — adicione uma na aba Matérias.',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                  ),
                ),
              const SizedBox(height: 16),

              AppTextField(
                controller: titleController,
                label: 'Título',
                icon: Icons.edit_note,
              ),
              const SizedBox(height: 16),

              // Seletor de data/hora do prazo.
              ListTile(
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(Icons.calendar_today, color: kAccentColor),
                title: Text(
                  DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR')
                      .format(selectedDateTime),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null) return;
                  if (!context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                  );
                  if (time == null) return;
                  setModalState(() {
                    selectedDateTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: contentController,
                label: 'Descrição',
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  if (titleController.text.isEmpty || selectedName == null) {
                    return;
                  }

                  final isNew = taskToEdit == null;
                  final task = isNew
                      ? Task(
                    id: DateTime.now().toString(),
                    subjectName: selectedName!,
                    title: titleController.text,
                    deadline: selectedDateTime,
                    content: contentController.text,
                  )
                  // Edição: atualiza a própria instância recebida em
                  // vez de criar uma nova (mantém o mesmo `id`).
                      : (taskToEdit
                    ..title = titleController.text
                    ..subjectName = selectedName!
                    ..deadline = selectedDateTime
                    ..content = contentController.text);

                  onSave(task, isNew: isNew);
                  Navigator.pop(context);
                },
                child: Text(taskToEdit == null ? 'CRIAR' : 'SALVAR'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Abre a lista de matérias em um bottom sheet e retorna a escolhida
/// (ou `null` se o usuário cancelar/fechar sem escolher). Usado no
/// lugar de um DropdownButtonFormField porque, no navegador, o menu
/// do dropdown pode não responder quando aberto dentro de outro
/// bottom sheet (ver comentário acima, junto ao ListTile que chama
/// esta função).
Future<String?> _showSubjectPicker(
  BuildContext context,
  List<String> subjectNames,
  String? currentlySelected,
) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              'Selecione a matéria',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          for (final name in subjectNames)
            ListTile(
              title: Text(name),
              trailing: name == currentlySelected
                  ? Icon(Icons.check, color: kAccentColor)
                  : null,
              onTap: () => Navigator.pop(sheetContext, name),
            ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../../models/registered_subject.dart';
import '../../models/subject.dart';
import '../../widgets/app_text_field.dart';

/// Abre o formulário para marcar uma nova aula em um dia da semana, ou
/// editar o horário de uma aula já existente.
///
/// Quando [subjectToEdit] é informado, o formulário só permite alterar
/// o horário — a matéria de uma aula já criada não muda por aqui (para
/// trocar a matéria, o usuário remove e cria de novo), mantendo o
/// mesmo comportamento do código original.
void showSubjectTimeFormSheet({
  required BuildContext context,
  required String dayContext,
  required List<RegisteredSubject> registeredSubjects,
  required void Function(Subject subject) onAdd,
  required void Function(Subject subject, String newTime) onEditTime,
  Subject? subjectToEdit,
}) {
  if (registeredSubjects.isEmpty && subjectToEdit == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastre uma matéria no fim da página!')),
    );
    return;
  }

  RegisteredSubject? selectedSubject;
  final timeController = TextEditingController(text: subjectToEdit?.time);

  // Formata automaticamente "1900" -> "19:00" enquanto o usuário digita,
  // só os números (o TextInputFormatter abaixo já bloqueia letras).
  timeController.addListener(() {
    final text = timeController.text;
    final digitsOnly = text.replaceAll(':', '');
    if (digitsOnly.length == 3 && !text.contains(':')) {
      final newText = '${digitsOnly.substring(0, 2)}:${digitsOnly.substring(2)}';
      timeController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.fromPosition(TextPosition(offset: newText.length)),
      );
    }
  });

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subjectToEdit == null ? 'Nova aula: $dayContext' : 'Editar horário',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            if (subjectToEdit == null)
              DropdownButtonFormField<RegisteredSubject>(
                dropdownColor: Theme.of(context).colorScheme.surfaceContainerLow,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                hint: const Text('Selecione a Matéria'),
                items: registeredSubjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (val) => selectedSubject = val,
              )
            else
              Text(
                subjectToEdit.name,
                style: TextStyle(
                    color: kAccentColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),

            const SizedBox(height: 16),
            AppTextField(
              controller: timeController,
              label: 'Horário (ex: 19:00)',
              icon: Icons.access_time_rounded,
              keyboardType: TextInputType.datetime,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: Colors.black,
                    shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final time = timeController.text.trim();
                    if (time.isEmpty) return;
                    if (subjectToEdit == null && selectedSubject == null) return;

                    if (subjectToEdit == null) {
                      onAdd(Subject(
                        id: DateTime.now().toString(),
                        name: selectedSubject!.name,
                        teacher: selectedSubject!.teacher,
                        dayOfWeek: dayContext,
                        time: time,
                      ));
                    } else {
                      onEditTime(subjectToEdit, time);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(subjectToEdit == null ? 'Adicionar' : 'Salvar'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
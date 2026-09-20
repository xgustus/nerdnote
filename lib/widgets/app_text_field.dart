import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';

/// Decoração padrão (bordas arredondadas, fundo levemente acinzentado,
/// ícone à esquerda) usada em todos os formulários do app.
///
/// Antes cada tela tinha sua própria cópia disso (`_inputStyle` na tela
/// de Tarefas, um `InputDecoration` "na unha" na tela de Matérias...).
InputDecoration appInputDecoration(
  BuildContext context,
  String label,
  IconData icon,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: kAccentColor),
    filled: true,
    fillColor:
        isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

/// Um [TextField] já estilizado com [appInputDecoration]. Reduz a
/// repetição que existia em cada tela (`_buildField`,
/// `_buildAdaptiveTextField`...) para o mesmo resultado visual.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: appInputDecoration(context, label, icon),
    );
  }
}

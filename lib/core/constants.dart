import 'package:flutter/material.dart';

/// Cor de destaque usada em toda a aplicação (botões, ícones, bordas...).
/// Centralizada aqui para que, se um dia quisermos trocar a cor do tema,
/// baste alterar em um único lugar em vez de caçar `Color(0xFF64B5F6)`
/// espalhado pelas telas.
const Color kAccentColor = Color(0xFF64B5F6);

/// Dias da semana, na ordem em que aparecem na tela de Matérias.
/// Usados tanto para montar as colunas do horário quanto (indiretamente,
/// via [kWeekDayNumbers]) para calcular a próxima ocorrência de uma aula.
const List<String> kWeekDays = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

/// Mapa auxiliar: nome do dia -> número do dia da semana no padrão do
/// Dart (segunda = 1 ... domingo = 7). Usado em
/// `TasksScreen._getClosestOccurrence` para descobrir a próxima data em
/// que uma matéria terá aula.
const Map<String, int> kWeekDayNumbers = {
  'Segunda-feira': 1,
  'Terça-feira': 2,
  'Quarta-feira': 3,
  'Quinta-feira': 4,
  'Sexta-feira': 5,
  'Sábado': 6,
  'Domingo': 7,
};

/// Chaves usadas para persistir dados no SharedPreferences.
/// Antes cada tela usava a string 'subjects', 'tasks' etc. "na mão";
/// manter tudo aqui evita erro de digitação (ex: 'task' vs 'tasks') que
/// faria uma tela salvar em uma chave e outra ler de outra.
class PrefsKeys {
  PrefsKeys._(); // impede instanciar essa classe; ela só guarda constantes

  static const String isDarkMode = 'isDarkMode';
  static const String subjects = 'subjects';
  static const String registeredSubjects = 'registered_subjects';
  static const String tasks = 'tasks';
  static const String cubeSolves = 'cube_solves';
  static const String cubeTimerBgImage = 'cube_timer_bg_image';
  static const String cubeTimerInspectionEnabled =
      'cube_timer_inspection_enabled';
}

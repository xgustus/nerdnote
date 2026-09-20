/// Formata um tempo de solução (em milissegundos) como "mm:ss.SSS",
/// ou "DNF" (Did Not Finish) quando o valor é -1.
///
/// Antes essa mesma função existia copiada em dois lugares
/// (`cube_timer_screen.dart` e `solves_history_modal.dart`); agora os
/// dois importam daqui, então qualquer ajuste no formato só precisa
/// ser feito uma vez.
String formatSolveTime(int milliseconds) {
  if (milliseconds == -1) return 'DNF';

  final minutes = milliseconds ~/ 60000;
  final seconds = (milliseconds % 60000) ~/ 1000;
  final millis = milliseconds % 1000;

  final mStr = minutes.toString().padLeft(2, '0');
  final sStr = seconds.toString().padLeft(2, '0');
  final msStr = millis.toString().padLeft(3, '0');

  return '$mStr:$sStr.$msStr';
}

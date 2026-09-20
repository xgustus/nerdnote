class CubeSolve {
  final String id;
  final int time;
  final DateTime date;
  final int penalty;

  CubeSolve({
    required this.id,
    required this.time,
    required this.date,
    this.penalty = 0,
  });

  /// Tempo final considerando a penalidade. Penalidade -1 marca a
  /// solução como DNF (Did Not Finish), que sobrepõe o tempo cravado.
  ///
  /// Centralizado aqui porque a tela do timer e o modal de histórico
  /// precisavam exatamente do mesmo cálculo.
  int get effectiveTime => penalty == -1 ? -1 : time + penalty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'date': date.toIso8601String(),
      'penalty': penalty,
    };
  }

  factory CubeSolve.fromJson(Map<String, dynamic> json) {
    return CubeSolve(
      id: json['id'],
      time: json['time'],
      date: DateTime.parse(json['date']),
      penalty: json['penalty'] ?? 0,
    );
  }
}
/// Representa uma aula específica no horário semanal: uma matéria, em
/// um dia da semana, em um horário.
///
/// Não confundir com [RegisteredSubject] (em registered_subject.dart):
/// um [Subject] é UMA aula marcada no calendário (ex: "Cálculo I,
/// Segunda-feira, 19:00"), enquanto o RegisteredSubject é o cadastro
/// geral da matéria (nome + professor), usado como catálogo para criar
/// aulas.
class Subject {
  String id;
  String name;
  String? teacher;
  String dayOfWeek;
  String time; // Formato "HH:mm", ex: "19:00"

  Subject({
    required this.id,
    required this.name,
    this.teacher,
    required this.dayOfWeek,
    required this.time,
  });

  /// Converte para um Map simples, pronto para virar JSON e ser salvo.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'teacher': teacher,
        'dayOfWeek': dayOfWeek,
        'time': time,
      };

  /// Reconstrói um Subject a partir do Map decodificado do JSON salvo.
  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'],
        name: json['name'],
        teacher: json['teacher'],
        dayOfWeek: json['dayOfWeek'],
        time: json['time'],
      );
}

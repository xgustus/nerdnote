/// Cadastro "mestre" de uma matéria: nome e professor(a).
///
/// É o que aparece na lista "Minhas Matérias" (tela de Matérias) e
/// serve de catálogo para criar novas aulas ([Subject]) no horário
/// semanal.
///
/// Antes esses dados eram guardados soltos como `Map<String, String>`
/// pelo código (`_registeredSubjects`); aqui viram uma classe só, o que
/// evita erros de digitação nas chaves do Map (ex: escrever 'teachr')
/// e deixa explícito quais campos existem. O JSON salvo continua com o
/// mesmo formato de antes, então backups antigos continuam funcionando.
class RegisteredSubject {
  String name;
  String teacher;

  RegisteredSubject({required this.name, required this.teacher});

  Map<String, String> toJson() => {'name': name, 'teacher': teacher};

  factory RegisteredSubject.fromJson(Map<String, dynamic> json) =>
      RegisteredSubject(
        name: json['name'] ?? '',
        teacher: json['teacher'] ?? '',
      );
}

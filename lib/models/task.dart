/// Representa uma tarefa/entrega vinculada a uma matéria, com prazo.
///
/// ATENÇÃO (correção): no projeto original essa classe existia em
/// DOIS lugares diferentes ao mesmo tempo — em `models/subject.dart` e,
/// de novo, dentro de `screens/tasks_screen.dart`. Isso é um erro real:
/// como `tasks_screen.dart` importava `models/subject.dart` (que já
/// trazia sua própria `Task`) e também declarava uma `Task` local, as
/// duas ficavam com o mesmo nome visíveis no mesmo arquivo, o que o
/// Dart não permite ("The name 'Task' is defined in..."). Agora existe
/// uma única fonte de verdade: este arquivo.
class Task {
  String id;
  String subjectName;
  String title;
  DateTime deadline;
  String content;
  // Marca se a tarefa já foi concluída. Antes "concluir" removia a
  // tarefa da lista na hora; agora só marca (o TaskTile mostra tarja
  // vermelha se pendente e verde se concluída) e ela some de verdade apenas pela lixeira.
  bool completed;

  Task({
    required this.id,
    required this.subjectName,
    required this.title,
    required this.deadline,
    this.content = '',
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectName': subjectName,
        'title': title,
        'deadline': deadline.toIso8601String(),
        'content': content,
        'completed': completed,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        subjectName: json['subjectName'],
        title: json['title'],
        deadline: DateTime.parse(json['deadline']),
        content: json['content'] ?? '',
        completed: json['completed'] ?? false,
      );
}

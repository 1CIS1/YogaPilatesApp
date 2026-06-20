/// Тип занятия (йога, пилатес, стретчинг…).
class ClassType {
  const ClassType({
    required this.id,
    required this.name,
    this.color,
  });

  final String id;
  final String name;
  final String? color; // HEX-цвет для UI-календаря
}

/// Преподаватель.
class Instructor {
  const Instructor({
    required this.id,
    required this.fullName,
    this.photoUrl,
    this.rating = 0,
  });

  final String id;
  final String fullName;
  final String? photoUrl;
  final double rating;
}

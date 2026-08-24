class Plant {
  final String id;
  String name;
  String species;
  String location;
  DateTime createdAt;

  Plant({
    required this.id,
    required this.name,
    this.species = 'Unknown species',
    this.location = 'Indoor',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'species': species,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Plant.fromJson(Map<String, dynamic> j) => Plant(
        id: '${j['id']}',
        name: '${j['name']}',
        species: '${j['species'] ?? 'Unknown species'}',
        location: '${j['location'] ?? 'Indoor'}',
        createdAt: DateTime.tryParse('${j['createdAt']}'),
      );
}

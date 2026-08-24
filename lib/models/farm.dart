class Farm {
  final String id;
  final String name;
  final String location;
  final List<FarmField> fields;

  const Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.fields,
  });

  Farm copyWith({
    String? name,
    String? location,
    List<FarmField>? fields,
  }) =>
      Farm(
        id: id,
        name: name ?? this.name,
        location: location ?? this.location,
        fields: fields ?? this.fields,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'fields': fields.map((field) => field.toJson()).toList(),
      };

  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
        id: '${json['id']}',
        name: '${json['name']}',
        location: '${json['location'] ?? ''}',
        fields: (json['fields'] as List? ?? const [])
            .map((item) =>
                FarmField.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class FarmField {
  final String id;
  final String name;
  final String crop;
  final double areaAcres;
  final List<FarmZone> zones;

  const FarmField({
    required this.id,
    required this.name,
    required this.crop,
    required this.areaAcres,
    required this.zones,
  });

  FarmField copyWith({
    String? name,
    String? crop,
    double? areaAcres,
    List<FarmZone>? zones,
  }) =>
      FarmField(
        id: id,
        name: name ?? this.name,
        crop: crop ?? this.crop,
        areaAcres: areaAcres ?? this.areaAcres,
        zones: zones ?? this.zones,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'crop': crop,
        'areaAcres': areaAcres,
        'zones': zones.map((zone) => zone.toJson()).toList(),
      };

  factory FarmField.fromJson(Map<String, dynamic> json) => FarmField(
        id: '${json['id']}',
        name: '${json['name']}',
        crop: '${json['crop'] ?? ''}',
        areaAcres: (json['areaAcres'] as num?)?.toDouble() ?? 0,
        zones: (json['zones'] as List? ?? const [])
            .map((item) =>
                FarmZone.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class FarmZone {
  final String id;
  final String name;
  final String cropStage;
  final List<String> nodeIds;

  const FarmZone({
    required this.id,
    required this.name,
    required this.cropStage,
    required this.nodeIds,
  });

  FarmZone copyWith({
    String? name,
    String? cropStage,
    List<String>? nodeIds,
  }) =>
      FarmZone(
        id: id,
        name: name ?? this.name,
        cropStage: cropStage ?? this.cropStage,
        nodeIds: nodeIds ?? this.nodeIds,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cropStage': cropStage,
        'nodeIds': nodeIds,
      };

  factory FarmZone.fromJson(Map<String, dynamic> json) => FarmZone(
        id: '${json['id']}',
        name: '${json['name']}',
        cropStage: '${json['cropStage'] ?? ''}',
        nodeIds: (json['nodeIds'] as List? ?? const [])
            .map((item) => '$item')
            .toList(),
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectType {
  newConstruction('new'),
  renovation('renovation'),
  interior('interior');

  final String value;
  const ProjectType(this.value);

  static ProjectType fromString(String value) {
    return ProjectType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ProjectType.newConstruction,
    );
  }

  String get label {
    switch (this) {
      case ProjectType.newConstruction:
        return 'New Construction';
      case ProjectType.renovation:
        return 'Renovation';
      case ProjectType.interior:
        return 'Interior Design';
    }
  }
}

enum ProjectStatus {
  live('live'),
  hidden('hidden');

  final String value;
  const ProjectStatus(this.value);

  static ProjectStatus fromString(String value) {
    return ProjectStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProjectStatus.hidden,
    );
  }
}

class ProjectImage {
  final String url;
  final String alt;

  ProjectImage({required this.url, required this.alt});

  factory ProjectImage.fromMap(Map<String, dynamic> map) {
    return ProjectImage(url: map['url'] ?? '', alt: map['alt'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'url': url, 'alt': alt};
  }
}

class ProjectMeta {
  final String? area;
  final String? duration;
  final int? year;
  final List<String> services;

  ProjectMeta({this.area, this.duration, this.year, this.services = const []});

  factory ProjectMeta.fromMap(Map<String, dynamic>? map) {
    if (map == null) return ProjectMeta();
    return ProjectMeta(
      area: map['area'],
      duration: map['duration'],
      year: map['year'],
      services: List<String>.from(map['services'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'duration': duration,
      'year': year,
      'services': services,
    };
  }
}

class Project {
  final String id;
  final String slug;
  final String title;
  final String district;
  final ProjectType type;
  final String summary;
  final String description;
  final List<ProjectImage> images;
  final ProjectStatus status;
  final bool isFeatured;
  final List<String> tags;
  final int views;
  final int bookingConversions;
  final ProjectMeta meta;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.slug,
    required this.title,
    required this.district,
    required this.type,
    required this.summary,
    required this.description,
    this.images = const [],
    required this.status,
    this.isFeatured = false,
    this.tags = const [],
    this.views = 0,
    this.bookingConversions = 0,
    required this.meta,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Project(
      id: doc.id,
      slug: data['slug'] ?? '',
      title: data['title'] ?? '',
      district: data['district'] ?? '',
      type: ProjectType.fromString(data['type'] ?? 'new'),
      summary: data['summary'] ?? '',
      description: data['description'] ?? '',
      images:
          (data['images'] as List<dynamic>?)
              ?.map((img) => ProjectImage.fromMap(img as Map<String, dynamic>))
              .toList() ??
          [],
      status: ProjectStatus.fromString(data['status'] ?? 'hidden'),
      isFeatured: data['isFeatured'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      views: data['views'] ?? 0,
      bookingConversions: data['bookingConversions'] ?? 0,
      meta: ProjectMeta.fromMap(data['meta']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slug': slug,
      'title': title,
      'district': district,
      'type': type.value,
      'summary': summary,
      'description': description,
      'images': images.map((img) => img.toMap()).toList(),
      'status': status.value,
      'isFeatured': isFeatured,
      'tags': tags,
      'views': views,
      'bookingConversions': bookingConversions,
      'meta': meta.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static String generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  Project copyWith({
    String? id,
    String? slug,
    String? title,
    String? district,
    ProjectType? type,
    String? summary,
    String? description,
    List<ProjectImage>? images,
    ProjectStatus? status,
    bool? isFeatured,
    List<String>? tags,
    int? views,
    int? bookingConversions,
    ProjectMeta? meta,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      district: district ?? this.district,
      type: type ?? this.type,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      images: images ?? this.images,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
      views: views ?? this.views,
      bookingConversions: bookingConversions ?? this.bookingConversions,
      meta: meta ?? this.meta,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceStatus {
  live('live'),
  disabled('disabled');

  final String value;
  const ServiceStatus(this.value);

  static ServiceStatus fromString(String value) {
    return ServiceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ServiceStatus.disabled,
    );
  }
}

class ServiceImage {
  final String url;
  final String alt;

  ServiceImage({required this.url, required this.alt});

  factory ServiceImage.fromMap(Map<String, dynamic> map) {
    return ServiceImage(url: map['url'] ?? '', alt: map['alt'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'url': url, 'alt': alt};
  }
}

class ProcessStep {
  final int step;
  final String title;
  final String description;

  ProcessStep({
    required this.step,
    required this.title,
    required this.description,
  });

  factory ProcessStep.fromMap(Map<String, dynamic> map) {
    return ProcessStep(
      step: map['step'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'step': step, 'title': title, 'description': description};
  }
}

class FAQ {
  final String question;
  final String answer;

  FAQ({required this.question, required this.answer});

  factory FAQ.fromMap(Map<String, dynamic> map) {
    return FAQ(question: map['question'] ?? '', answer: map['answer'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'question': question, 'answer': answer};
  }
}

class Service {
  final String id;
  final String slug;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final List<ServiceImage> images;
  final List<String> tags;
  final ServiceStatus status;
  final List<String> features;
  final List<ProcessStep> process;
  final List<FAQ> faqs;
  final List<String> areaServed;
  final int views;
  final int bookingConversions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Service({
    required this.id,
    required this.slug,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    this.images = const [],
    this.tags = const [],
    required this.status,
    this.features = const [],
    this.process = const [],
    this.faqs = const [],
    this.areaServed = const [],
    this.views = 0,
    this.bookingConversions = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Service(
      id: doc.id,
      slug: data['slug'] ?? '',
      title: data['title'] ?? '',
      shortDescription: data['shortDescription'] ?? '',
      fullDescription: data['fullDescription'] ?? '',
      images:
          (data['images'] as List<dynamic>?)
              ?.map((img) => ServiceImage.fromMap(img as Map<String, dynamic>))
              .toList() ??
          [],
      tags: List<String>.from(data['tags'] ?? []),
      status: ServiceStatus.fromString(data['status'] ?? 'disabled'),
      features: List<String>.from(data['features'] ?? []),
      process:
          (data['process'] as List<dynamic>?)
              ?.map((p) => ProcessStep.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      faqs:
          (data['faqs'] as List<dynamic>?)
              ?.map((f) => FAQ.fromMap(f as Map<String, dynamic>))
              .toList() ??
          [],
      areaServed: List<String>.from(data['areaServed'] ?? []),
      views: data['views'] ?? 0,
      bookingConversions: data['bookingConversions'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slug': slug,
      'title': title,
      'shortDescription': shortDescription,
      'fullDescription': fullDescription,
      'images': images.map((img) => img.toMap()).toList(),
      'tags': tags,
      'status': status.value,
      'features': features,
      'process': process.map((p) => p.toMap()).toList(),
      'faqs': faqs.map((f) => f.toMap()).toList(),
      'areaServed': areaServed,
      'views': views,
      'bookingConversions': bookingConversions,
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

  Service copyWith({
    String? id,
    String? slug,
    String? title,
    String? shortDescription,
    String? fullDescription,
    List<ServiceImage>? images,
    List<String>? tags,
    ServiceStatus? status,
    List<String>? features,
    List<ProcessStep>? process,
    List<FAQ>? faqs,
    List<String>? areaServed,
    int? views,
    int? bookingConversions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Service(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      features: features ?? this.features,
      process: process ?? this.process,
      faqs: faqs ?? this.faqs,
      areaServed: areaServed ?? this.areaServed,
      views: views ?? this.views,
      bookingConversions: bookingConversions ?? this.bookingConversions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

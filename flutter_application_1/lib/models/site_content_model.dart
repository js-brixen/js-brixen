import 'package:cloud_firestore/cloud_firestore.dart';

class SiteContent {
  final HeroSection hero;
  final AboutSection about;
  final List<HowItWorksStep> howItWorks;
  final CtaSection cta;
  final ContactInfo contact;
  final DateTime? updatedAt;

  SiteContent({
    required this.hero,
    required this.about,
    required this.howItWorks,
    required this.cta,
    required this.contact,
    this.updatedAt,
  });

  factory SiteContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SiteContent(
      hero: HeroSection.fromMap(data['hero'] ?? {}),
      about: AboutSection.fromMap(data['about'] ?? {}),
      howItWorks:
          (data['howItWorks'] as List<dynamic>?)
              ?.map(
                (step) => HowItWorksStep.fromMap(step as Map<String, dynamic>),
              )
              .toList() ??
          [],
      cta: CtaSection.fromMap(data['cta'] ?? {}),
      contact: ContactInfo.fromMap(data['contact'] ?? {}),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hero': hero.toMap(),
      'about': about.toMap(),
      'howItWorks': howItWorks.map((step) => step.toMap()).toList(),
      'cta': cta.toMap(),
      'contact': contact.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class HeroSection {
  final String title;
  final String subtext;
  final String ctaText;

  HeroSection({
    required this.title,
    required this.subtext,
    required this.ctaText,
  });

  factory HeroSection.fromMap(Map<String, dynamic> map) {
    return HeroSection(
      title: map['title'] ?? 'Building Your Vision Into Reality',
      subtext:
          map['subtext'] ??
          'Premium construction services across Kerala & Karnataka. From custom homes to commercial projects, we deliver excellence with every build.',
      ctaText: map['ctaText'] ?? 'Get Free Quote',
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'subtext': subtext, 'ctaText': ctaText};
  }

  HeroSection copyWith({String? title, String? subtext, String? ctaText}) {
    return HeroSection(
      title: title ?? this.title,
      subtext: subtext ?? this.subtext,
      ctaText: ctaText ?? this.ctaText,
    );
  }
}

class AboutSection {
  final String story;
  final String statsYears;
  final String statsProjects;
  final String statsClients;
  final String statsTeam;

  AboutSection({
    required this.story,
    required this.statsYears,
    required this.statsProjects,
    required this.statsClients,
    required this.statsTeam,
  });

  factory AboutSection.fromMap(Map<String, dynamic> map) {
    return AboutSection(
      story:
          map['story'] ??
          'Founded with a vision to transform the construction industry in Kerala and Karnataka, JS Construction has grown from a small team of passionate builders to a trusted name in residential and commercial construction.',
      statsYears: map['statsYears'] ?? '10+',
      statsProjects: map['statsProjects'] ?? '200+',
      statsClients: map['statsClients'] ?? '500+',
      statsTeam: map['statsTeam'] ?? '50+',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'story': story,
      'statsYears': statsYears,
      'statsProjects': statsProjects,
      'statsClients': statsClients,
      'statsTeam': statsTeam,
    };
  }

  AboutSection copyWith({
    String? story,
    String? statsYears,
    String? statsProjects,
    String? statsClients,
    String? statsTeam,
  }) {
    return AboutSection(
      story: story ?? this.story,
      statsYears: statsYears ?? this.statsYears,
      statsProjects: statsProjects ?? this.statsProjects,
      statsClients: statsClients ?? this.statsClients,
      statsTeam: statsTeam ?? this.statsTeam,
    );
  }
}

class HowItWorksStep {
  final String step;
  final String title;
  final String description;

  HowItWorksStep({
    required this.step,
    required this.title,
    required this.description,
  });

  factory HowItWorksStep.fromMap(Map<String, dynamic> map) {
    return HowItWorksStep(
      step: map['step'] ?? '1',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'step': step, 'title': title, 'description': description};
  }

  HowItWorksStep copyWith({String? step, String? title, String? description}) {
    return HowItWorksStep(
      step: step ?? this.step,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }
}

class CtaSection {
  final String title;
  final String text;

  CtaSection({required this.title, required this.text});

  factory CtaSection.fromMap(Map<String, dynamic> map) {
    return CtaSection(
      title: map['title'] ?? 'Ready to Start Your Project?',
      text:
          map['text'] ??
          'Book a free consultation with our construction experts today.',
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'text': text};
  }

  CtaSection copyWith({String? title, String? text}) {
    return CtaSection(title: title ?? this.title, text: text ?? this.text);
  }
}

class ContactInfo {
  final List<String> phoneNumbers;
  final String email;
  final List<String> whatsappNumbers;
  final String address;
  final String contactFormEmail; // New field for form destination

  ContactInfo({
    required this.phoneNumbers,
    required this.email,
    required this.whatsappNumbers,
    required this.address,
    required this.contactFormEmail,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    // Handle 'phone' (legacy string) vs 'phoneNumbers' (new list)
    List<String> phones = [];
    if (map['phoneNumbers'] != null) {
      phones = List<String>.from(map['phoneNumbers']);
    } else if (map['phone'] != null) {
      phones = [map['phone'].toString()];
    } else {
      phones = ['+91XXXXXXXXXX'];
    }

    // Handle 'whatsapp' (legacy string) vs 'whatsappNumbers' (new list)
    List<String> whatsapps = [];
    if (map['whatsappNumbers'] != null) {
      whatsapps = List<String>.from(map['whatsappNumbers']);
    } else if (map['whatsapp'] != null) {
      whatsapps = [map['whatsapp'].toString()];
    } else {
      whatsapps = ['91XXXXXXXXXX'];
    }

    return ContactInfo(
      phoneNumbers: phones,
      email: map['email'] ?? 'info@jsconstruction.com',
      whatsappNumbers: whatsapps,
      address: map['address'] ?? '',
      contactFormEmail: map['contactFormEmail'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumbers': phoneNumbers,
      'email': email,
      'whatsappNumbers': whatsappNumbers,
      'address': address,
      'contactFormEmail': contactFormEmail,
      // Keep legacy fields for a while
      'phone': phoneNumbers.isNotEmpty ? phoneNumbers.first : '',
      'whatsapp': whatsappNumbers.isNotEmpty ? whatsappNumbers.first : '',
    };
  }

  ContactInfo copyWith({
    List<String>? phoneNumbers,
    String? email,
    List<String>? whatsappNumbers,
    String? address,
    String? contactFormEmail,
  }) {
    return ContactInfo(
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      email: email ?? this.email,
      whatsappNumbers: whatsappNumbers ?? this.whatsappNumbers,
      address: address ?? this.address,
      contactFormEmail: contactFormEmail ?? this.contactFormEmail,
    );
  }
}

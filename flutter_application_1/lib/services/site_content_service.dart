import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/site_content_model.dart';

class SiteContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'siteContent';
  static const String _docId = 'main';

  Future<SiteContent> getSiteContent() async {
    try {
      final doc = await _firestore.collection(_collection).doc(_docId).get();

      if (!doc.exists) {
        return _getDefaultContent();
      }

      return SiteContent.fromFirestore(doc);
    } catch (e) {
      print('[SiteContentService] Error fetching content: $e');
      return _getDefaultContent();
    }
  }

  Stream<SiteContent> watchSiteContent() {
    return _firestore.collection(_collection).doc(_docId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) {
        return _getDefaultContent();
      }
      return SiteContent.fromFirestore(doc);
    });
  }

  Future<void> updateSiteContent(SiteContent content) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(_docId)
          .set(content.toFirestore(), SetOptions(merge: true));

      print('[SiteContentService] Content updated successfully');
    } catch (e) {
      print('[SiteContentService] Error updating content: $e');
      rethrow;
    }
  }

  SiteContent _getDefaultContent() {
    return SiteContent(
      hero: HeroSection(
        title: 'Building Your Vision Into Reality',
        subtext:
            'Premium construction services across Kerala & Karnataka. From custom homes to commercial projects, we deliver excellence with every build.',
        ctaText: 'Get Free Quote',
      ),
      about: AboutSection(
        story:
            'Founded with a vision to transform the construction industry in Kerala and Karnataka, JS Construction has grown from a small team of passionate builders to a trusted name in residential and commercial construction.',
        statsYears: '10+',
        statsProjects: '200+',
        statsClients: '500+',
        statsTeam: '50+',
      ),
      howItWorks: [
        HowItWorksStep(
          step: '1',
          title: 'Book Consultation',
          description:
              'Schedule a free consultation with our experts to discuss your project requirements and vision.',
        ),
        HowItWorksStep(
          step: '2',
          title: 'Contact us',
          description:
              'Receive a detailed, transparent quote with no hidden costs.',
        ),
        HowItWorksStep(
          step: '3',
          title: 'Get Building',
          description:
              'Our experienced team begins construction with regular updates and quality checks.',
        ),
      ],
      cta: CtaSection(
        title: 'Ready to Start Your Project?',
        text:
            "Let's discuss your vision and bring it to life with expert construction services",
      ),
      contact: ContactInfo(
        phoneNumbers: ['+91XXXXXXXXXX'],
        email: 'info@jsconstruction.com',
        whatsappNumbers: ['91XXXXXXXXXX'],
        address: '',
        contactFormEmail: '',
      ),
    );
  }
}

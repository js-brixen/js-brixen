import 'package:flutter/material.dart';
import '../models/site_content_model.dart';
import '../services/site_content_service.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final SiteContentService _contentService = SiteContentService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  // Hero section controllers
  late TextEditingController _heroTitleController;
  late TextEditingController _heroSubtextController;
  late TextEditingController _heroCtaController;

  // About section controllers
  late TextEditingController _aboutStoryController;
  late TextEditingController _statsYearsController;
  late TextEditingController _statsProjectsController;
  late TextEditingController _statsClientsController;
  late TextEditingController _statsTeamController;

  // CTA section controllers
  late TextEditingController _ctaTitleController;
  late TextEditingController _ctaTextController;

  // Contact controllers
  List<TextEditingController> _phoneControllers = [];
  List<TextEditingController> _whatsappControllers = [];
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _contactFormEmailController; // New controller

  // How It Works steps
  List<HowItWorksStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadContent();
  }

  void _initControllers() {
    _heroTitleController = TextEditingController();
    _heroSubtextController = TextEditingController();
    _heroCtaController = TextEditingController();
    _aboutStoryController = TextEditingController();
    _statsYearsController = TextEditingController();
    _statsProjectsController = TextEditingController();
    _statsClientsController = TextEditingController();
    _statsTeamController = TextEditingController();
    _ctaTitleController = TextEditingController();
    _ctaTextController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _contactFormEmailController = TextEditingController(); // Init
    // Initialize with one empty controller for new entries
    _phoneControllers = [TextEditingController()];
    _whatsappControllers = [TextEditingController()];
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      final content = await _contentService.getSiteContent();
      setState(() {
        _populateControllers(content);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading content: $e')));
      }
    }
  }

  void _populateControllers(SiteContent content) {
    _heroTitleController.text = content.hero.title;
    _heroSubtextController.text = content.hero.subtext;
    _heroCtaController.text = content.hero.ctaText;
    _aboutStoryController.text = content.about.story;
    _statsYearsController.text = content.about.statsYears;
    _statsProjectsController.text = content.about.statsProjects;
    _statsClientsController.text = content.about.statsClients;
    _statsTeamController.text = content.about.statsTeam;
    _ctaTitleController.text = content.cta.title;
    _ctaTextController.text = content.cta.text;

    _emailController.text = content.contact.email;
    _addressController.text = content.contact.address;
    _contactFormEmailController.text =
        content.contact.contactFormEmail; // Populate

    // Populate Phone Controllers
    for (var controller in _phoneControllers) controller.dispose();
    _phoneControllers = content.contact.phoneNumbers
        .map((p) => TextEditingController(text: p))
        .toList();
    if (_phoneControllers.isEmpty)
      _phoneControllers = [TextEditingController()];

    // Populate WhatsApp Controllers
    for (var controller in _whatsappControllers) controller.dispose();
    _whatsappControllers = content.contact.whatsappNumbers
        .map((w) => TextEditingController(text: w))
        .toList();
    if (_whatsappControllers.isEmpty)
      _whatsappControllers = [TextEditingController()];

    _steps = List.from(content.howItWorks);
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      // Filter out empty numbers
      final phones = _phoneControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final whatsapps = _whatsappControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final updatedContent = SiteContent(
        hero: HeroSection(
          title: _heroTitleController.text.trim(),
          subtext: _heroSubtextController.text.trim(),
          ctaText: _heroCtaController.text.trim(),
        ),
        about: AboutSection(
          story: _aboutStoryController.text.trim(),
          statsYears: _statsYearsController.text.trim(),
          statsProjects: _statsProjectsController.text.trim(),
          statsClients: _statsClientsController.text.trim(),
          statsTeam: _statsTeamController.text.trim(),
        ),
        howItWorks: _steps,
        cta: CtaSection(
          title: _ctaTitleController.text.trim(),
          text: _ctaTextController.text.trim(),
        ),
        contact: ContactInfo(
          phoneNumbers: phones,
          email: _emailController.text.trim(),
          whatsappNumbers: whatsapps,
          address: _addressController.text.trim(),
          contactFormEmail: _contactFormEmailController.text.trim(),
        ),
      );

      await _contentService.updateSiteContent(updatedContent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Content updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _heroTitleController.dispose();
    _heroSubtextController.dispose();
    _heroCtaController.dispose();
    _aboutStoryController.dispose();
    _statsYearsController.dispose();
    _statsProjectsController.dispose();
    _statsClientsController.dispose();
    _statsTeamController.dispose();
    _ctaTitleController.dispose();
    _ctaTextController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _contactFormEmailController.dispose(); // Dispose
    for (var c in _phoneControllers) c.dispose();
    for (var c in _whatsappControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Content'),
        elevation: 0,
        backgroundColor: const Color(0xFF1a1a2e),
      ),
      backgroundColor: const Color(0xFF1a1a2e),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                title: '🏠 Hero Section',
                children: [
                  _buildTextField(
                    controller: _heroTitleController,
                    label: 'Title',
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _heroSubtextController,
                    label: 'Subtext',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _heroCtaController,
                    label: 'Call to Action Text',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildCard(
                title: 'ℹ️ About Section',
                children: [
                  _buildTextField(
                    controller: _aboutStoryController,
                    label: 'Our Story',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _statsYearsController,
                          label: 'Years Exp.',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          controller: _statsProjectsController,
                          label: 'Projects',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _statsClientsController,
                          label: 'Client Satisfaction',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          controller: _statsTeamController,
                          label: 'Team Size',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildCard(
                title: '📢 CTA Section (Bottom)',
                children: [
                  _buildTextField(
                    controller: _ctaTitleController,
                    label: 'Title',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ctaTextController,
                    label: 'Description',
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildContactSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildCard(
      title: '📞 Contact Information',
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'info@jsconstruction.com',
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (!v!.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _contactFormEmailController,
          label: 'Form Submission Email (Internal)',
          hint: 'Where do you want to receive messages?',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Office Address',
          hint: 'Full address (multi-line supported)',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        const Text('Phone Numbers', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        ..._buildDynamicList(_phoneControllers, '+91XXXXXXXXXX'),
        const SizedBox(height: 16),
        const Text('WhatsApp Numbers', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        ..._buildDynamicList(_whatsappControllers, '91XXXXXXXXXX'),
      ],
    );
  }

  List<Widget> _buildDynamicList(
    List<TextEditingController> controllers,
    String hint,
  ) {
    return [
      ...controllers.asMap().entries.map((entry) {
        final index = entry.key;
        final controller = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: controller,
                  label: 'Number ${index + 1}',
                  hint: hint,
                ),
              ),
              const SizedBox(width: 8),
              if (controllers.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      controller.dispose();
                      controllers.removeAt(index);
                    });
                  },
                ),
            ],
          ),
        );
      }),
      TextButton.icon(
        onPressed: () {
          setState(() {
            controllers.add(TextEditingController());
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Another Number'),
      ),
    ];
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveContent,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save All Changes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

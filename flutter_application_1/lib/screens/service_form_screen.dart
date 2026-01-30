import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/service.dart';
import '../models/project.dart';
import '../providers/services_provider.dart';
import '../widgets/image_gallery_picker.dart';

class ServiceFormScreen extends StatefulWidget {
  final Service? service;

  const ServiceFormScreen({super.key, this.service});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _fullDescController = TextEditingController();
  final _tagsController = TextEditingController();
  final _featuresController = TextEditingController();
  final _areaServedController = TextEditingController();

  ServiceStatus _selectedStatus = ServiceStatus.live;
  List<ServiceImage> _images = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _loadServiceData();
    }
  }

  void _loadServiceData() {
    final service = widget.service!;
    _titleController.text = service.title;
    _shortDescController.text = service.shortDescription;
    _fullDescController.text = service.fullDescription;
    _selectedStatus = service.status;
    _images = List.from(service.images);
    _tagsController.text = service.tags.join(', ');
    _featuresController.text = service.features.join('\n');
    _areaServedController.text = service.areaServed.join(', ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _fullDescController.dispose();
    _tagsController.dispose();
    _featuresController.dispose();
    _areaServedController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final slug = Service.generateSlug(_titleController.text);
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final features = _featuresController.text
          .split('\n')
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList();

      final areaServed = _areaServedController.text
          .split(',')
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();

      final serviceData = {
        'slug': slug,
        'title': _titleController.text.trim(),
        'shortDescription': _shortDescController.text.trim(),
        'fullDescription': _fullDescController.text.trim(),
        'images': _images.map((img) => img.toMap()).toList(),
        'status': _selectedStatus.value,
        'tags': tags,
        'features': features,
        'process': [], // Can be extended later
        'faqs': [], // Can be extended later
        'areaServed': areaServed,
      };

      if (widget.service == null) {
        await context.read<ServicesProvider>().createService(serviceData);
      } else {
        await context.read<ServicesProvider>().updateService(
          widget.service!.id,
          serviceData,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service == null ? 'Add Service' : 'Edit Service'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f3460),
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Service Title *',
                  hintText: 'e.g., New House Construction',
                  filled: true,
                  fillColor: Colors.white10,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shortDescController,
                decoration: const InputDecoration(
                  labelText: 'Short Description *',
                  hintText: 'Brief description (1-2 lines)',
                  filled: true,
                  fillColor: Colors.white10,
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a short description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullDescController,
                decoration: const InputDecoration(
                  labelText: 'Full Description *',
                  hintText: 'Detailed service description',
                  filled: true,
                  fillColor: Colors.white10,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a full description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ImageGalleryPicker(
                initialImages: _images
                    .map((img) => ProjectImage(url: img.url, alt: img.alt))
                    .toList(),
                onImagesChanged: (images) {
                  setState(() {
                    _images = images
                        .map((img) => ServiceImage(url: img.url, alt: img.alt))
                        .toList();
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Service Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'e.g., Turnkey, Residential (comma-separated)',
                  filled: true,
                  fillColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _featuresController,
                decoration: const InputDecoration(
                  labelText: 'Features',
                  hintText: 'One feature per line',
                  filled: true,
                  fillColor: Colors.white10,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaServedController,
                decoration: const InputDecoration(
                  labelText: 'Area Served',
                  hintText: 'e.g., Kerala, Karnataka (comma-separated)',
                  filled: true,
                  fillColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Publishing Options',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ServiceStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  filled: true,
                  fillColor: Colors.white10,
                ),
                items: const [
                  DropdownMenuItem(
                    value: ServiceStatus.live,
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Live (Visible on website)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ServiceStatus.disabled,
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_off,
                          size: 18,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text('Disabled (Hidden)'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveService,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.cyan,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.service == null
                            ? 'Create Service'
                            : 'Update Service',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

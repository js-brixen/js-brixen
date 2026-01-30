import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../providers/projects_provider.dart';
import '../widgets/image_gallery_picker.dart';

class ProjectFormScreen extends StatefulWidget {
  final Project? project;

  const ProjectFormScreen({super.key, this.project});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _districtController = TextEditingController();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _areaController = TextEditingController();
  final _durationController = TextEditingController();
  final _yearController = TextEditingController();
  final _tagsController = TextEditingController();

  ProjectType _selectedType = ProjectType.newConstruction;
  ProjectStatus _selectedStatus = ProjectStatus.hidden;
  bool _isFeatured = false;
  List<ProjectImage> _images = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _loadProjectData();
    }
  }

  void _loadProjectData() {
    final project = widget.project!;
    _titleController.text = project.title;
    _districtController.text = project.district;
    _summaryController.text = project.summary;
    _descriptionController.text = project.description;
    _selectedType = project.type;
    _selectedStatus = project.status;
    _isFeatured = project.isFeatured;
    _images = List.from(project.images);
    _areaController.text = project.meta.area ?? '';
    _durationController.text = project.meta.duration ?? '';
    _yearController.text = project.meta.year?.toString() ?? '';
    _tagsController.text = project.tags.join(', ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _districtController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _durationController.dispose();
    _yearController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
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
      final slug = Project.generateSlug(_titleController.text);
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final projectData = {
        'slug': slug,
        'title': _titleController.text.trim(),
        'district': _districtController.text.trim(),
        'type': _selectedType.value,
        'summary': _summaryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'images': _images.map((img) => img.toMap()).toList(),
        'status': _selectedStatus.value,
        'isFeatured': _isFeatured,
        'tags': tags,
        'meta': {
          'area': _areaController.text.trim().isEmpty
              ? null
              : _areaController.text.trim(),
          'duration': _durationController.text.trim().isEmpty
              ? null
              : _durationController.text.trim(),
          'year': _yearController.text.trim().isEmpty
              ? null
              : int.tryParse(_yearController.text.trim()),
          'services': [],
        },
      };

      if (widget.project == null) {
        await context.read<ProjectsProvider>().createProject(projectData);
      } else {
        await context.read<ProjectsProvider>().updateProject(
          widget.project!.id,
          projectData,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save project: $e'),
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
        title: Text(widget.project == null ? 'Add Project' : 'Edit Project'),
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
                  labelText: 'Project Title *',
                  hintText: 'e.g., Lakeside Modern Villa',
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
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'District/Location *',
                  hintText: 'e.g., Kochi, Kerala',
                  filled: true,
                  fillColor: Colors.white10,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProjectType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Project Type *',
                  filled: true,
                  fillColor: Colors.white10,
                ),
                items: ProjectType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Summary *',
                  hintText: 'Short description (1-2 lines)',
                  filled: true,
                  fillColor: Colors.white10,
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a summary';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Full Description *',
                  hintText: 'Detailed project description',
                  filled: true,
                  fillColor: Colors.white10,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ImageGalleryPicker(
                initialImages: _images,
                onImagesChanged: (images) {
                  setState(() {
                    _images = images;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Additional Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _areaController,
                      decoration: const InputDecoration(
                        labelText: 'Area',
                        hintText: 'e.g., 3200 sq ft',
                        filled: true,
                        fillColor: Colors.white10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        hintText: 'e.g., 14 months',
                        filled: true,
                        fillColor: Colors.white10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  hintText: 'e.g., 2025',
                  filled: true,
                  fillColor: Colors.white10,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'e.g., modern, lakefront, luxury (comma-separated)',
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
              DropdownButtonFormField<ProjectStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  filled: true,
                  fillColor: Colors.white10,
                ),
                items: const [
                  DropdownMenuItem(
                    value: ProjectStatus.live,
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Live (Visible on website)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: ProjectStatus.hidden,
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_off,
                          size: 18,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text('Hidden (Draft)'),
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
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Featured Project'),
                subtitle: const Text('Show in featured section'),
                value: _isFeatured,
                onChanged: (value) {
                  setState(() {
                    _isFeatured = value;
                  });
                },
                secondary: Icon(
                  _isFeatured ? Icons.star : Icons.star_border,
                  color: _isFeatured ? Colors.amber : Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProject,
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
                        widget.project == null
                            ? 'Create Project'
                            : 'Update Project',
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

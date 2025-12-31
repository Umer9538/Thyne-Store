import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/banner.dart' as BannerModel;
import '../../../../data/services/api_service.dart';
import '../../../../utils/theme.dart';

class BannerFormScreen extends StatefulWidget {
  final BannerModel.Banner? banner;

  const BannerFormScreen({super.key, this.banner});

  @override
  State<BannerFormScreen> createState() => _BannerFormScreenState();
}

class _BannerFormScreenState extends State<BannerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _ctaTextController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _targetUrlController = TextEditingController();

  String _selectedType = 'main';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int _priority = 0;
  bool _isActive = true;
  String? _selectedFestival;
  File? _selectedImage;
  bool _isLoading = false;
  bool _showPreview = false;

  final List<String> _bannerTypes = [
    'main',
    'promotional',
    'festival',
    'flash_sale',
  ];

  final List<String> _festivals = [
    'diwali',
    'christmas',
    'valentine',
    'newyear',
    'holi',
    'eid',
    'rakhi',
    'navratri',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.banner != null) {
      _loadBannerData();
    }
  }

  void _loadBannerData() {
    final banner = widget.banner!;
    _titleController.text = banner.title;
    _subtitleController.text = banner.subtitle ?? banner.description ?? '';
    _ctaTextController.text = banner.ctaText ?? 'SHOP NOW';
    _descriptionController.text = banner.description ?? '';
    _imageUrlController.text = banner.imageUrl;
    _targetUrlController.text = banner.targetUrl ?? '';
    _selectedType = banner.type;
    _startDate = banner.startDate;
    _endDate = banner.endDate;
    _priority = banner.priority;
    _isActive = banner.isActive;
    _selectedFestival = banner.festivalTag;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _ctaTextController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _targetUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageUrlController.text = pickedFile.path;
      });
    }
  }

  Future<void> _selectDateTime(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartDate) {
            _startDate = dateTime;
          } else {
            _endDate = dateTime;
          }
        });
      }
    }
  }

  Future<void> _saveBanner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Convert to UTC and format with Z suffix for Go backend
      final startDateUtc = _startDate.toUtc();
      final endDateUtc = _endDate?.toUtc();

      final bannerData = {
        'title': _titleController.text,
        'subtitle': _subtitleController.text.isEmpty
            ? null
            : _subtitleController.text,
        'ctaText': _ctaTextController.text.isEmpty
            ? 'SHOP NOW'
            : _ctaTextController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'imageUrl': _imageUrlController.text,
        'type': _selectedType,
        'targetUrl': _targetUrlController.text.isEmpty
            ? null
            : _targetUrlController.text,
        'startDate': '${startDateUtc.toIso8601String().split('.')[0]}Z',
        'endDate': endDateUtc != null ? '${endDateUtc.toIso8601String().split('.')[0]}Z' : null,
        'isActive': _isActive,
        'priority': _priority,
        'festivalTag': _selectedFestival,
      };

      if (widget.banner == null) {
        await ApiService.createBanner(bannerData: bannerData);
      } else {
        await ApiService.updateBanner(
          bannerId: widget.banner!.id,
          bannerData: bannerData,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.banner == null
                  ? 'Banner created successfully'
                  : 'Banner updated successfully',
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.banner == null ? 'New Banner' : 'Edit Banner'),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
        ],
      ),
      body: _showPreview ? _buildPreview() : _buildForm(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveBanner,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.banner == null ? 'Create Banner' : 'Update Banner'),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Selection
            const Text(
              'Banner Image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : _imageUrlController.text.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _imageUrlController.text,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.add_photo_alternate, size: 48),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48),
                                SizedBox(height: 8),
                                Text('Tap to select image'),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Or enter image URL',
                prefixIcon: Icon(Icons.link),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please provide an image';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Banner Title',
                prefixIcon: Icon(Icons.title),
                hintText: 'e.g., Begin Your Bridal Journey',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Subtitle (shown on banner)
            TextFormField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: 'Subtitle',
                prefixIcon: Icon(Icons.subtitles),
                hintText: 'Short description shown on the banner',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // CTA Button Text
            TextFormField(
              controller: _ctaTextController,
              decoration: const InputDecoration(
                labelText: 'Button Text',
                prefixIcon: Icon(Icons.smart_button),
                hintText: 'e.g., SHOP NOW, EXPLORE',
              ),
            ),
            const SizedBox(height: 16),

            // Description (internal)
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Internal Description (Optional)',
                prefixIcon: Icon(Icons.description),
                hintText: 'For admin reference only',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Banner Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Banner Type',
                prefixIcon: Icon(Icons.category),
              ),
              items: _bannerTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value!);
              },
            ),
            const SizedBox(height: 16),

            // Festival Tag
            DropdownButtonFormField<String>(
              value: _selectedFestival,
              decoration: const InputDecoration(
                labelText: 'Festival Tag (Optional)',
                prefixIcon: Icon(Icons.celebration),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ..._festivals.map((festival) {
                  return DropdownMenuItem(
                    value: festival,
                    child: Text(festival.toUpperCase()),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedFestival = value);
              },
            ),
            const SizedBox(height: 16),

            // Target URL
            TextFormField(
              controller: _targetUrlController,
              decoration: const InputDecoration(
                labelText: 'Target URL (Optional)',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),

            // Priority
            Row(
              children: [
                const Icon(Icons.priority_high, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority: $_priority',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Slider(
                        value: _priority.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: _priority.toString(),
                        activeColor: AppTheme.primaryGold,
                        onChanged: (value) {
                          setState(() => _priority = value.toInt());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Start Date
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date & Time'),
              subtitle: Text(_formatDateTime(_startDate)),
              trailing: const Icon(Icons.edit),
              onTap: () => _selectDateTime(true),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 16),

            // End Date
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('End Date & Time (Optional)'),
              subtitle: Text(_endDate != null
                  ? _formatDateTime(_endDate!)
                  : 'No end date'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _endDate = null),
                    ),
                  const Icon(Icons.edit),
                ],
              ),
              onTap: () => _selectDateTime(false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 16),

            // Active Status
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Banner will be visible when scheduled'),
              value: _isActive,
              activeColor: AppTheme.primaryGold,
              onChanged: (value) => setState(() => _isActive = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Preview Banner
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : _imageUrlController.text.isNotEmpty
                    ? Image.network(
                        _imageUrlController.text,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 48),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.image, size: 48),
                        ),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleController.text.isEmpty
                      ? 'Banner Title'
                      : _titleController.text,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_descriptionController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _descriptionController.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildPreviewInfo('Type', _selectedType.toUpperCase()),
                if (_selectedFestival != null)
                  _buildPreviewInfo('Festival', _selectedFestival!.toUpperCase()),
                _buildPreviewInfo('Priority', _priority.toString()),
                _buildPreviewInfo('Start', _formatDateTime(_startDate)),
                if (_endDate != null)
                  _buildPreviewInfo('End', _formatDateTime(_endDate!)),
                _buildPreviewInfo('Status', _isActive ? 'ACTIVE' : 'INACTIVE'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

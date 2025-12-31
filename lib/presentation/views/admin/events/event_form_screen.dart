import 'package:flutter/material.dart';
import '../../../../data/models/event.dart';
import '../../../../data/services/api_service.dart';
import '../../../../utils/theme.dart';

class EventFormScreen extends StatefulWidget {
  final Event? event;
  final DateTime selectedDate;

  const EventFormScreen({
    super.key,
    this.event,
    required this.selectedDate,
  });

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _themeColorController = TextEditingController();

  String _selectedType = 'festival';
  DateTime _eventDate = DateTime.now();
  bool _isRecurring = false;
  bool _isActive = true;
  final List<String> _suggestedCategories = [];
  bool _isLoading = false;

  final List<String> _eventTypes = ['festival', 'sale', 'promotion', 'holiday'];
  final List<String> _availableCategories = [
    'Rings',
    'Necklaces',
    'Earrings',
    'Bracelets',
    'Pendants',
    'Bangles',
  ];

  @override
  void initState() {
    super.initState();
    _eventDate = widget.selectedDate;
    if (widget.event != null) {
      _loadEventData();
    }
  }

  void _loadEventData() {
    final event = widget.event!;
    _nameController.text = event.name;
    _descriptionController.text = event.description ?? '';
    _themeColorController.text = event.themeColor ?? '';
    _selectedType = event.type;
    _eventDate = event.date;
    _isRecurring = event.isRecurring;
    _isActive = event.isActive;
    _suggestedCategories.addAll(event.suggestedCategories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _themeColorController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_eventDate),
      );

      if (time != null) {
        setState(() {
          _eventDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Convert to UTC and format with Z suffix for Go backend
      final eventDateUtc = _eventDate.toUtc();
      final eventData = {
        'name': _nameController.text,
        'type': _selectedType,
        'date': '${eventDateUtc.toIso8601String().split('.')[0]}Z',
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'themeColor': _themeColorController.text.isEmpty
            ? null
            : _themeColorController.text,
        'isRecurring': _isRecurring,
        'suggestedCategories': _suggestedCategories,
        'isActive': _isActive,
      };

      if (widget.event == null) {
        await ApiService.createEvent(eventData: eventData);
      } else {
        await ApiService.updateEvent(
          eventId: widget.event!.id,
          eventData: eventData,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event == null
                  ? 'Event created successfully'
                  : 'Event updated successfully',
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
        title: Text(widget.event == null ? 'New Event' : 'Edit Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  prefixIcon: Icon(Icons.event),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _eventTypes.map((type) {
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

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Date & Time
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Event Date & Time'),
                subtitle: Text(_formatDateTime(_eventDate)),
                trailing: const Icon(Icons.edit),
                onTap: _selectDateTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),

              // Theme Color
              TextFormField(
                controller: _themeColorController,
                decoration: const InputDecoration(
                  labelText: 'Theme Color (Optional, e.g., #FF6F00)',
                  prefixIcon: Icon(Icons.color_lens),
                ),
              ),
              const SizedBox(height: 16),

              // Suggested Categories
              const Text(
                'Suggested Product Categories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCategories.map((category) {
                  final isSelected = _suggestedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _suggestedCategories.add(category);
                        } else {
                          _suggestedCategories.remove(category);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryGold.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryGold,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Recurring Event
              SwitchListTile(
                title: const Text('Recurring Event'),
                subtitle: const Text('Repeats annually'),
                value: _isRecurring,
                activeColor: AppTheme.primaryGold,
                onChanged: (value) => setState(() => _isRecurring = value),
              ),

              // Active Status
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Event will be visible'),
                value: _isActive,
                activeColor: AppTheme.primaryGold,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveEvent,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.event == null ? 'Create Event' : 'Update Event'),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:performance_analzer2/screens/activity_uploader.dart';
import 'package:performance_analzer2/service/api_service.dart';

class ResearchTab extends ActivityTab {
  const ResearchTab({super.key});
  
  @override
  State<ResearchTab> createState() => _ResearchTabState();
}

class _ResearchTabState extends ActivityTabState<ResearchTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    super.dispose();
  }
  
  @override
  String get activityTypeName => 'Research Project';
    final ApiService _apiService = ApiService();
  
  @override
  List<Widget> buildActivitySpecificFields() {
    return [
      TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Research Title',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a research title';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'Research Description',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        maxLines: 3,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a research description';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _yearController,
        decoration: const InputDecoration(
          labelText: 'Year',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a year';
          }
          if (int.tryParse(value) == null) {
            return 'Please enter a valid year';
          }
          return null;
        },
      ),
    ];
  }
  
  @override
  Future<bool> saveActivity(String email) async {
    try {
      final research = {
        'Title': _titleController.text.trim(),
        'Description': _descriptionController.text.trim(),
        'Year': int.parse(_yearController.text.trim()),
        'Score': 85, // Default score for valid research
      };
      
      // Save the research to the server
      return await _apiService.saveResearch(email, research);
    } catch (e) {
      print('Error saving research: $e');
      return false;
    }
  }
}

// Publications Tab Implementation
class PublicationsTab extends ActivityTab {
  const PublicationsTab({super.key});
  
  @override
  State<PublicationsTab> createState() => _PublicationsTabState();
}

class _PublicationsTabState extends ActivityTabState<PublicationsTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _journalController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _citationController = TextEditingController();
    final ApiService _apiService = ApiService();
  
  @override
  void dispose() {
    _titleController.dispose();
    _journalController.dispose();
    _yearController.dispose();
    _citationController.dispose();
    super.dispose();
  }
  
  @override
  String get activityTypeName => 'Publication';
  
  @override
  List<Widget> buildActivitySpecificFields() {
    return [
      TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Publication Title',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a publication title';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _journalController,
        decoration: const InputDecoration(
          labelText: 'Journal/Conference',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter journal or conference name';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a year';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid year';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _citationController,
              decoration: const InputDecoration(
                labelText: 'Citation Count',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter citation count';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    ];
  }
  
  @override
  Future<bool> saveActivity(String email) async {
    try {
      final publication = {
        'Title': _titleController.text.trim(),
        'Journal': _journalController.text.trim(),
        'Year': int.parse(_yearController.text.trim()),
        'Citation': int.parse(_citationController.text.trim()),
        'Score': 45, // Default score for valid publication
      };
      
      // Save the publication to the server
      return await _apiService.savePublication(email, publication);
    } catch (e) {
      print('Error saving publication: $e');
      return false;
    }
  }
}

// Guest Lectures Tab Implementation
class GuestLecturesTab extends ActivityTab {
  const GuestLecturesTab({super.key});
  
  @override
  State<GuestLecturesTab> createState() => _GuestLecturesTabState();
}

class _GuestLecturesTabState extends ActivityTabState<GuestLecturesTab> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  DateTime _lectureDate = DateTime.now();
  
  @override
  void dispose() {
    _topicController.dispose();
    _institutionController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lectureDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _lectureDate) {
      setState(() {
        _lectureDate = picked;
      });
    }
  }
  
  @override
  String get activityTypeName => 'Guest Lecture';
  
  @override
  List<Widget> buildActivitySpecificFields() {
    return [
      TextFormField(
        controller: _topicController,
        decoration: const InputDecoration(
          labelText: 'Lecture Topic',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter the lecture topic';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _institutionController,
        decoration: const InputDecoration(
          labelText: 'Institution/Organization',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter the institution name';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      InkWell(
        onTap: () => _selectDate(context),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Date of Lecture',
            border: OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_lectureDate.day}/${_lectureDate.month}/${_lectureDate.year}',
              ),
              const Icon(Icons.calendar_today, size: 20),
            ],
          ),
        ),
      ),
    ];
  }
  
  @override
  Future<bool> saveActivity(String email) async {
      final ApiService _apiService = ApiService();
    try {
      final guestLecture = {
        'Topic': _topicController.text.trim(),
        'Institution': _institutionController.text.trim(),
        'Date': _lectureDate.toIso8601String(),
        'Score': 85, // Default score for valid guest lecture
      };
      
      // Save the guest lecture to the server
      return await _apiService.saveGuestLecture(email, guestLecture);
    } catch (e) {
      print('Error saving guest lecture: $e');
      return false;
    }
  }
}

// Self Development Tab Implementation
class SelfDevelopmentTab extends ActivityTab {
  const SelfDevelopmentTab({super.key});
  
  @override
  State<SelfDevelopmentTab> createState() => _SelfDevelopmentTabState();
}

class _SelfDevelopmentTabState extends ActivityTabState<SelfDevelopmentTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  DateTime _completionDate = DateTime.now();
  String _activityType = 'Course';
  
  final List<String> _activityTypes = [
    'Course',
    'Workshop',
    'Certification',
    'Training',
    'Conference',
    'Seminar',
  ];
  
  @override
  void dispose() {
    _titleController.dispose();
    _organizationController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _completionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _completionDate) {
      setState(() {
        _completionDate = picked;
      });
    }
  }
  
  @override
  String get activityTypeName => 'Self Development Activity';
  
  @override
  List<Widget> buildActivitySpecificFields() {
    return [
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Activity Type',
          border: OutlineInputBorder(),
        ),
        value: _activityType,
        items: _activityTypes.map((String type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _activityType = newValue;
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select an activity type';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Activity Title',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter the activity title';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _organizationController,
        decoration: const InputDecoration(
          labelText: 'Organization/Provider',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter the organization or provider';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      InkWell(
        onTap: () => _selectDate(context),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Completion Date',
            border: OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_completionDate.day}/${_completionDate.month}/${_completionDate.year}',
              ),
              const Icon(Icons.calendar_today, size: 20),
            ],
          ),
        ),
      ),
    ];
  }
  
  @override
  Future<bool> saveActivity(String email) async {
    try {
      final selfDevelopment = {
        'ActivityType': _activityType,
        'Title': _titleController.text.trim(),
        'Organization': _organizationController.text.trim(),
        'Date': _completionDate.toIso8601String(),
        'Score': 85, // Default score for valid self development activity
      };
        final ApiService _apiService = ApiService();
      // Save the self development activity to the server
      return await _apiService.saveSelfDevelopment(email, selfDevelopment);
    } catch (e) {
      print('Error saving self development activity: $e');
      return false;
    }
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:performance_analzer2/screens/activity_sub.dart';
import 'package:performance_analzer2/service/api_service.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/certificate_provider.dart';
import '../providers/user_provider.dart';

class AcademicActivitiesScreen extends StatefulWidget {
  const AcademicActivitiesScreen({super.key});

  @override
  State<AcademicActivitiesScreen> createState() => _AcademicActivitiesScreenState();
}

class _AcademicActivitiesScreenState extends State<AcademicActivitiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Activities'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Research'),
            Tab(text: 'Publications'),
            Tab(text: 'Guest Lectures'),
            Tab(text: 'Self Development'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              ResearchTab(),
              PublicationsTab(),
              GuestLecturesTab(),
              SelfDevelopmentTab(),
            ],
          ),
    );
  }
}

// Base class for activity tabs with common functionality
abstract class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});
}

abstract class ActivityTabState<T extends ActivityTab> extends State<T> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<File> _selectedImages = []; // Changed to list of files
  Map<File, bool> _imageValidationStatus = {}; // Track validation status for each image
  Map<File, String> _imageValidationMessages = {}; // Track validation messages for each image
  Map<File, String> _imageDocumentTypes = {}; // Track document types for each image
  
  // Abstract method to get fields specific to this activity type
  List<Widget> buildActivitySpecificFields();
  
  // Abstract method to get the activity type name
  String get activityTypeName;
  
  // Abstract method to save the activity
  Future<bool> saveActivity(String email);
  
  Future<void> _pickImage() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final ImagePicker picker = ImagePicker();
      final List<XFile>? pickedFiles = await picker.pickMultiImage();
      
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        // Convert XFiles to Files and add to our list
        List<File> newFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();
        
        setState(() {
          _selectedImages.addAll(newFiles);
          
          // Initialize validation status for new files
          for (var file in newFiles) {
            _imageValidationStatus[file] = false;
            _imageValidationMessages[file] = '';
            _imageDocumentTypes[file] = 'Unknown';
          }
        });
        
        // Validate all new images
        for (var file in newFiles) {
          await _validateSingleImage(file);
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _validateSingleImage(File file) async {
  setState(() {
    _imageValidationMessages[file] = 'Validating document...';
  });
  
  try {
    // Use the certificate authentication service to validate the document
    final CertificateProvider certificateProvider = Provider.of<CertificateProvider>(context, listen: false);
    final authResult = await certificateProvider.authService.authenticateCertificate(file);
    
    final String fileName = file.path.split('/').last;
    print('Document validation result for $fileName: $authResult');
    
    // Get values from auth result
    bool isOriginal = authResult['isOriginal'] == true;
    final String certificateType = authResult['certificateType'] ?? 'Unknown';
    final String reason = authResult['reason'] ?? 'No validation reason provided';
    
    // Improved validation logic:
    // Consider document valid if:
    // 1. It's marked as original by the service OR
    // 2. It has a recognized certificate type (not Unknown/Unidentified) OR
    // 3. The reason contains "certificate text" and "document layout"
    if (!isOriginal) {
      if (certificateType != 'Unknown' && certificateType != 'Unidentified') {
        // Override since we have a valid certificate type
        isOriginal = true;
      } else if (reason.contains("certificate text") && reason.contains("document layout")) {
        // Override since the reason suggests it's valid
        isOriginal = true;
      }
    }
    
    setState(() {
      _imageValidationStatus[file] = isOriginal;
      _imageDocumentTypes[file] = certificateType;
      
      // Create appropriate validation message
      if (isOriginal) {
        if (certificateType != 'Unknown' && certificateType != 'Unidentified') {
          _imageValidationMessages[file] = 'Valid $certificateType document detected. $reason';
        } else {
          _imageValidationMessages[file] = 'Valid document detected. $reason';
        }
      } else {
        _imageValidationMessages[file] = 'Invalid document. $reason';
      }
    });
    
    // Show validation result if this is the only document
    if (_selectedImages.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_imageValidationStatus[file] == true
            ? 'Document validated successfully!' 
            : 'Document validation failed'),
          backgroundColor: _imageValidationStatus[file] == true ? Colors.green : Colors.red,
        ),
      );
    }
    
  } catch (e) {
    print('Error validating image: $e');
    setState(() {
      _imageValidationStatus[file] = false;
      _imageValidationMessages[file] = 'Error validating document: ${e.toString()}';
      _imageDocumentTypes[file] = 'Unknown';
    });
  }
}
  
  void _removeImage(File file) {
    setState(() {
      _selectedImages.remove(file);
      _imageValidationStatus.remove(file);
      _imageValidationMessages.remove(file);
      _imageDocumentTypes.remove(file);
    });
  }
  
  Future<void> _validateAllImages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      for (var file in _selectedImages) {
        await _validateSingleImage(file);
      }
      
      // Show overall validation result
      final allValid = _selectedImages.every((file) => _imageValidationStatus[file] == true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allValid 
            ? 'All documents validated successfully!' 
            : 'Some documents failed validation.'),
          backgroundColor: allValid ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error validating documents: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _submitActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one supporting document'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Check if any documents are invalid
    final hasInvalidDocuments = _selectedImages.any((file) => _imageValidationStatus[file] != true);
    
    if (hasInvalidDocuments) {
      // Show confirmation dialog for invalid documents
      bool proceed = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invalid Documents'),
          content: const Text('Some of the uploaded documents did not pass validation. Do you still want to proceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Proceed Anyway'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ) ?? false;
      
      if (!proceed) return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (!userProvider.isLoggedIn) {
        throw Exception('User not logged in');
      }
      
      final email = userProvider.currentUser!.email;
      final success = await saveActivity(email);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$activityTypeName saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        _formKey.currentState!.reset();
        setState(() {
          _selectedImages.clear();
          _imageValidationStatus.clear();
          _imageValidationMessages.clear();
          _imageDocumentTypes.clear();
        });
      } else {
        throw Exception('Failed to save $activityTypeName');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Build document preview for each uploaded image
  Widget _buildDocumentPreviewItem(File file) {
    final isValid = _imageValidationStatus[file] ?? false;
    final validationMessage = _imageValidationMessages[file] ?? '';
    final documentType = _imageDocumentTypes[file] ?? 'Unknown';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? Colors.green : Colors.red,
          width: 1,
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: Image.file(
                  file,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Validate button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.7),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        onPressed: () => _validateSingleImage(file),
                        tooltip: 'Validate Again',
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Remove button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.7),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => _removeImage(file),
                        tooltip: 'Remove Document',
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isValid ? Icons.check_circle : Icons.error,
                      color: isValid ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isValid ? 'Document Valid' : 'Document Invalid',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isValid ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                if (documentType != 'Unknown' && documentType != 'Unidentified')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description,
                          color: Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          documentType,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (validationMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      validationMessage,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Processing documents...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        )
      : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Add New $activityTypeName',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                
                // Activity-specific fields
                ...buildActivitySpecificFields(),
                
                const SizedBox(height: 24),
                
                // Document upload section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Supporting Documents',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_selectedImages.isNotEmpty)
                      TextButton.icon(
                        onPressed: _validateAllImages,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Validate All'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload images of supporting documents for verification',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                // Document preview list
                if (_selectedImages.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return _buildDocumentPreviewItem(_selectedImages[index]);
                    },
                  ),
                
                // Add document button
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedImages.isEmpty 
                              ? Icons.cloud_upload_outlined 
                              : Icons.add_photo_alternate_outlined,
                          size: _selectedImages.isEmpty ? 40 : 32,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedImages.isEmpty
                              ? 'Tap to upload documents'
                              : 'Add more documents',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Supported formats: JPG, JPEG, PNG',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedImages.isNotEmpty
                          ? (_selectedImages.every((file) => _imageValidationStatus[file] == true)
                              ? Theme.of(context).primaryColor
                              : Colors.orange)
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _selectedImages.isEmpty
                          ? 'Submit $activityTypeName (No Documents)'
                          : (_selectedImages.every((file) => _imageValidationStatus[file] == true)
                              ? 'Submit $activityTypeName'
                              : 'Submit $activityTypeName (Some Invalid)'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
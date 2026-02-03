import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/lost_found_item.dart';

class CreateItemScreen extends StatefulWidget {
  const CreateItemScreen({super.key});

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _collectionLocationController = TextEditingController();
  final _reporterNameController = TextEditingController();
  final _reporterEmailController = TextEditingController();
  final _reporterPhoneController = TextEditingController();

  String _type = 'LOST';
  String _category = 'OTHERS'; // Changed default to match backend
  DateTime _selectedDate = DateTime.now();
  File? _imageFile;
  XFile? _pickedFile; // Store XFile for web compatibility
  String? _uploadedImageUrl;
  bool _isUploading = false;
  bool _isClassifying = false;
  String? _predictedClass;
  double? _confidence;

  // Categories must match backend enum exactly
  final List<String> _categories = [
    'ELECTRONIC',
    'DOCUMENT',
    'ACCESSORIES',
    'CLOTHING',
    'JEWELLERY',
    'FOOTWEAR',
    'OTHERS',
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    final user = provider.currentUser;
    if (user != null) {
      _reporterNameController.text = user.fullName;
      _reporterEmailController.text = user.email;
      _reporterPhoneController.text = user.phoneNumber;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _collectionLocationController.dispose();
    _reporterNameController.dispose();
    _reporterEmailController.dispose();
    _reporterPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
        if (!kIsWeb) {
          _imageFile = File(pickedFile.path);
        }
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_pickedFile == null) return;

    setState(() {
      _isUploading = true;
      _isClassifying = true;
    });

    final provider = Provider.of<AppProvider>(context, listen: false);

    // For web, pass XFile directly, for mobile use File
    final fileToUpload = kIsWeb ? _pickedFile! : _imageFile!;

    // Upload image and classify in parallel
    final results = await Future.wait([
      provider.uploadImage(fileToUpload),
      provider.classifyImage(fileToUpload),
    ]);

    final imageUrl = results[0] as String?;
    final classification = results[1] as Map<String, dynamic>?;

    setState(() {
      _uploadedImageUrl = imageUrl;
      _isUploading = false;
      _isClassifying = false;

      // Apply ML classification result
      if (classification != null) {
        _predictedClass = classification['predictedClass'];
        _confidence = classification['confidence'];
        final suggestedCategory = classification['backendCategory'] as String?;
        if (suggestedCategory != null &&
            _categories.contains(suggestedCategory)) {
          _category = suggestedCategory;
        }
      }
    });

    if (mounted) {
      if (imageUrl != null) {
        String message = 'Image uploaded successfully';
        if (_predictedClass != null && _confidence != null) {
          message +=
              '\nDetected: $_predictedClass (${(_confidence! * 100).toStringAsFixed(0)}%)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AppProvider>(context, listen: false);

      final item = LostFoundItem(
        type: _type,
        title: _titleController.text,
        lostFoundDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        lostFoundLocation: _locationController.text,
        description: _descriptionController.text,
        reporterName: _reporterNameController.text,
        reporterEmail: _reporterEmailController.text,
        reporterPhoneNo: _reporterPhoneController.text,
        category: _category,
        imageUrl: _uploadedImageUrl,
        collectionLocation: _collectionLocationController.text.isEmpty
            ? null
            : _collectionLocationController.text,
      );

      final success = await provider.createItem(item);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to create item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selection
              const Text(
                'Item Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'LOST',
                    label: Text('Lost'),
                    icon: Icon(Icons.search_off),
                  ),
                  ButtonSegment(
                    value: 'FOUND',
                    label: Text('Found'),
                    icon: Icon(Icons.check_circle),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Image Upload
              const Text(
                'Item Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isUploading || _isClassifying ? null : _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _isUploading || _isClassifying
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 8),
                              Text(
                                _isClassifying
                                    ? 'Analyzing image...'
                                    : 'Uploading...',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : _pickedFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(
                                      _pickedFile!.path,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(Icons.error, size: 50),
                                        );
                                      },
                                    )
                                  : Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 50, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add photo',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                ),
              ),

              // ML Classification Result
              if (_predictedClass != null && _confidence != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Detection: $_predictedClass',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            Text(
                              'Confidence: ${(_confidence! * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g., Black iPhone 13',
                ),
                validator: (value) {
                  if (value == null || value.length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide more details...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  hintText: 'Where was it lost/found?',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.length < 5) {
                    return 'Location must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Collection Location (for FOUND items)
              if (_type == 'FOUND')
                TextFormField(
                  controller: _collectionLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Collection Location',
                    hintText: 'Where can it be collected?',
                    prefixIcon: Icon(Icons.place),
                  ),
                ),
              if (_type == 'FOUND') const SizedBox(height: 24),

              // Reporter Info Section
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Reporter Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reporterNameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.length < 5) {
                    return 'Name must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reporterEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _reporterPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              Consumer<AppProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit Report'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pagamipana/services/receipt_processor.dart';
import 'package:pagamipana/pages/people_page.dart'; // Import PeoplePage
import 'package:pagamipana/pages/items_page.dart'; // Import ItemsPage

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paga mi pana',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 144, 231, 147)),
      ),
      home: const UploadBillPage(),
    );
  }
}

class UploadBillPage extends StatefulWidget {
  const UploadBillPage({super.key});

  @override
  State<UploadBillPage> createState() => _UploadBillPageState();
}

class _UploadBillPageState extends State<UploadBillPage> {
  bool isPanelCollapsed = true;
  String? uploadedImagePath;
  int currentStep = 1;
  final ReceiptProcessor receiptProcessor = ReceiptProcessor(); // Ensure proper initialization
  List<Map<String, dynamic>> ocrItems = []; // OCR JSON items
  List<String> people = []; // List of people added in step 2

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        uploadedImagePath = image.path;
      });
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        uploadedImagePath = photo.path;
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Upload from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImageAndNavigate() async {
    if (uploadedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload or take a photo first.')),
      );
      return;
    }

    try {
      final imageBytes = await File(uploadedImagePath!).readAsBytes();
      final items = await receiptProcessor.processReceipt(imageBytes);

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items detected in the receipt.')),
        );
        return;
      }

      setState(() {
        ocrItems = items.map((item) {
          return {
            'name': item.name,
            'quantity': item.quantity, // Removed `?? 1` since `quantity` is non-nullable
            'unitPrice': item.unitPrice, // Removed `??` logic since `unitPrice` is non-nullable
            'isShareable': false, // Default to non-shareable
          };
        }).toList();
        currentStep = 2; // Navigate to the People page
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing receipt: $e')),
      );
    }
  }

  Widget _getCurrentPage() {
    switch (currentStep) {
      case 1:
        return _buildUploadContent();
      case 2:
        return PeoplePage(
          onBack: () => setState(() => currentStep = 1),
          onNext: () {
            setState(() {
              currentStep = 3;
            });
          },
          onPeopleUpdated: (updatedPeople) {
            setState(() {
              people = updatedPeople; // Update the people list
            });
          },
        );
      case 3:
        return ItemsPage(
          items: ocrItems,
          people: people,
          onBack: () => setState(() => currentStep = 2),
          onNext: () => setState(() => currentStep = 4),
        );
      case 4:
        return const Placeholder();
      default:
        return _buildUploadContent();
    }
  }

  Widget _buildUploadContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 240, 255, 240),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Step 1: Upload Your Bill',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose an option to upload your bill',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showImageSourceActionSheet(context),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Upload or Take Photo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          width: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Center(
            child: uploadedImagePath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.image, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Preview will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : Image.file(
                    File(uploadedImagePath!),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _processImageAndNavigate,
          child: const Text('Next'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paga mi pana'),
        backgroundColor: const Color.fromARGB(255, 143, 217, 145),
      ),
      body: Row(
        children: [
          // Collapsible left-side panel
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isPanelCollapsed ? 50 : 150,
            color: const Color.fromARGB(255, 224, 242, 219),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(isPanelCollapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      isPanelCollapsed = !isPanelCollapsed;
                    });
                  },
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => currentStep = 1),
                        child: _buildStepIndicator('1', 'Upload', currentStep == 1),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => setState(() => currentStep = 2),
                        child: _buildStepIndicator('2', 'People', currentStep == 2),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => setState(() => currentStep = 3),
                        child: _buildStepIndicator('3', 'Items', currentStep == 3),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => setState(() => currentStep = 4),
                        child: _buildStepIndicator('4', 'Summary', currentStep == 4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _getCurrentPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(String step, String label, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isActive ? Colors.green : Colors.grey[300],
          child: Text(
            step,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (!isPanelCollapsed) ...[
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
}

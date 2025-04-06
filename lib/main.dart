import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paga mi pana',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paga mi pana'),
        backgroundColor: Colors.green,
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
                      _buildStepIndicator('1', 'Upload', true),
                      const SizedBox(height: 16),
                      _buildStepIndicator('2', 'People', false),
                      const SizedBox(height: 16),
                      _buildStepIndicator('3', 'Items', false),
                      const SizedBox(height: 16),
                      _buildStepIndicator('4', 'Summary', false),
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
              child: Column(
                children: [
                  // Upload content
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
                          'Upload an image of your restaurant bill',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.cloud_upload, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Take a photo or upload an image of your bill',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _pickImage,
                              child: const Text('Upload Image'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _takePhoto,
                              child: const Text('Take Photo'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Rectangular preview box with improved text styling
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
                ],
              ),
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

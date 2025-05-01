import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDetailsPage extends StatefulWidget {
  final String imagePath;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const ReportDetailsPage({
    super.key,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  final TextEditingController _descController = TextEditingController();
  String _severity = 'Medium';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Report a Pothole'),
        backgroundColor: Colors.black,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Image Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(widget.imagePath),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ).animate().fadeIn(duration: 600.ms).slide(begin: const Offset(0, -0.2)),

            const SizedBox(height: 20),

            // Description TextField
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the pothole...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.3),

            const SizedBox(height: 20),

            // Severity Dropdown
            Row(
              children: [
                const Text('Severity:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _severity,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Low', 'Medium', 'High'].map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _severity = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.3),

            const SizedBox(height: 20),

            // Location Card
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Location Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Latitude: ${widget.latitude.toStringAsFixed(6)}'),
                    Text('Longitude: ${widget.longitude.toStringAsFixed(6)}'),
                    Text('Time: ${widget.timestamp.toLocal().toString().substring(0, 19)}'),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),

            const SizedBox(height: 30),

            // Submit Button
            AnimatedSwitcher(
              duration: 400.ms,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.black)
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Report'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _submitReport,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Submits the report to Firebase Storage & Firestore
  void _submitReport() async {
    setState(() => _isSubmitting = true); // Show loading

    try {
      final file = File(widget.imagePath);
      final fileName = 'reports/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload image to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      // Create report data
      final reportData = {
        'imageUrl': imageUrl,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'timestamp': widget.timestamp.toIso8601String(),
        'description': _descController.text,
        'severity': _severity,
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('reports').add(reportData);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully!')),
      );

      Navigator.pop(context); // Go back after successful submission
    } catch (e) {
      print('Submission failed: $e');

      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false); // Hide loading spinner
      }
    }
  }
}

import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class SubmitPaperScreen extends StatefulWidget {
  final String submissionType; // 'abstract' | 'fullpaper'

  const SubmitPaperScreen({
    super.key,
    required this.submissionType,
  });

  @override
  State<SubmitPaperScreen> createState() => _SubmitPaperScreenState();
}

class _SubmitPaperScreenState extends State<SubmitPaperScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();

  PlatformFile? _pickedFile;
  bool _uploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  String get _typeLabel =>
      widget.submissionType == 'abstract' ? 'Abstract' : 'Full Paper';

  // ---------------- FILE PICKER ----------------

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    if (file.extension?.toLowerCase() != 'docx') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a .docx Word document only.'),
        ),
      );
      return;
    }

    setState(() => _pickedFile = file);
  }

  // ---------------- SUBMIT ----------------

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();

    if (title.isEmpty) {
      _showError('Enter a title for your submission.');
      return;
    }

    if (author.isEmpty) {
      _showError('Enter the author name.');
      return;
    }

    if (_pickedFile == null) {
      _showError('Please select a Word document (.docx).');
      return;
    }

    final Uint8List? bytes = _pickedFile!.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showError('Unable to read file. Please try again.');
      return;
    }

    setState(() => _uploading = true);

    try {
      final referenceNumber = await FirestoreService.getNextReferenceNumber();

      final extractedText = _extractTextFromDocx(bytes);

      // Convert bytes to base64 and store inside Firestore document
      final docBase64 = base64Encode(bytes);

      await FirestoreService.addSubmission(
        uid: AuthService.currentUser!.uid,
        title: title,
        author: author,
        submissionType: widget.submissionType,
        referenceNumber: referenceNumber,
        extractedText: extractedText.isEmpty ? null : extractedText,
        docBase64: docBase64,
        docName: _pickedFile?.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submitted successfully. Reference: $referenceNumber'),
          backgroundColor: Colors.green,
        ),
      );

      if (AuthService.isAnonymous) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Submission failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ---------------- DOCX TEXT EXTRACTION ----------------

  String _extractTextFromDocx(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docXml = archive.firstWhere(
        (file) => file.name == 'word/document.xml',
      );

      final xmlContent = String.fromCharCodes(docXml.content as List<int>);
      final document = xml.XmlDocument.parse(xmlContent);

      return document.findAllElements('w:t').map((e) => e.text).join(' ');
    } catch (_) {
      return '';
    }
  }

  // ---------------- UI HELPERS ----------------

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit $_typeLabel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickDocument,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _pickedFile == null
                    ? 'Select Word document (.docx)'
                    : 'Selected: ${_pickedFile!.name}',
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _uploading ? null : _submit,
              child: _uploading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

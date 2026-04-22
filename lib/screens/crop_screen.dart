import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import 'processing_screen.dart';

class CropScreen extends StatefulWidget {
  final String imagePath;

  const CropScreen({super.key, required this.imagePath});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final _cropController = CropController();
  Uint8List? _imageBytes;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    if (mounted) setState(() => _imageBytes = bytes);
  }

  Future<void> _handleCropped(Uint8List croppedBytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(croppedBytes);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(imagePath: file.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Crop to Ingredients',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isCropping)
            TextButton(
              onPressed: () {
                setState(() => _isCropping = true);
                _cropController.crop();
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _imageBytes == null || _isCropping
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : Crop(
              image: _imageBytes!,
              controller: _cropController,
              onCropped: _handleCropped,
              baseColor: AppColors.darkBg,
              maskColor: Colors.black.withValues(alpha: 0.5),
              cornerDotBuilder: (size, edgeAlignment) =>
                  const DotControl(color: AppColors.primaryOrange),
            ),
    );
  }
}

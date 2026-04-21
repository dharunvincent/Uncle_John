import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../theme/app_theme.dart';
import 'processing_screen.dart';

class CropScreen extends StatefulWidget {
  final String imagePath;

  const CropScreen({super.key, required this.imagePath});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cropImage();
    });
  }

  Future<void> _cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: widget.imagePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop to Ingredients',
          toolbarColor: AppColors.darkBg,
          toolbarWidgetColor: AppColors.white,
          backgroundColor: AppColors.darkBg,
          activeControlsWidgetColor: AppColors.primaryOrange,
          cropFrameColor: AppColors.primaryOrange,
          cropGridColor: AppColors.primaryOrange.withValues(alpha: 0.3),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop to Ingredients',
          doneButtonTitle: 'Confirm',
          cancelButtonTitle: 'Retake',
          aspectRatioLockEnabled: false,
          rotateButtonsHidden: true,
          resetButtonHidden: false,
        ),
      ],
    );

    if (!mounted) return;

    if (croppedFile != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              ProcessingScreen(imagePath: croppedFile.path),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primaryOrange,
            ),
            const SizedBox(height: 20),
            Text(
              'Opening cropper...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
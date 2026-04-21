import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../theme/app_theme.dart';
import '../services/ingredient_analyzer.dart';
import 'report_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String imagePath;

  const ProcessingScreen({super.key, required this.imagePath});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  int _messageIndex = 0;
  final List<String> _messages = [
    'Uncle John is reading the label...',
    'Checking each ingredient for you...',
    'Patience is the finest spice in any kitchen...',
    'Almost done, just a moment...',
  ];

  @override
  void initState() {
    super.initState();
    _startMessageRotation();
    _processImage();
  }

  void _startMessageRotation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
      return mounted;
    });
  }

  Future<void> _processImage() async {
    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final rawText = recognizedText.text;

      if (!mounted) return;

      if (rawText.trim().isEmpty) {
        _showError('no_text');
        return;
      }

      final analyzer = IngredientAnalyzer();
      await analyzer.loadDatabase();
      final result = analyzer.analyze(rawText);

      if (!mounted) return;

      if (result.ingredients.isEmpty) {
        _showError('no_ingredients');
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ReportScreen(result: result),
        ),
      );
    } catch (e) {
      debugPrint('Processing error: $e');
      if (mounted) _showError('general');
    }
  }

  void _showError(String type) {
    String title;
    String message;

    switch (type) {
      case 'no_text':
        title = 'Uncle John couldn\'t read that';
        message =
            'The image might be blurry or the text too small. Try again with a clearer photo.';
        break;
      case 'no_ingredients':
        title = 'No ingredients found';
        message =
            'Uncle John couldn\'t find any ingredients in this image. Make sure you\'re pointing at the ingredients list on the package.';
        break;
      default:
        title = 'Something went wrong';
        message =
            'Uncle John had trouble reading that. Let\'s try again with another photo.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkBg, AppColors.darkSurface],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              Text(
                '🔍',
                style: const TextStyle(fontSize: 64),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                    duration: 800.ms,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.15, 1.15),
                    end: const Offset(1, 1),
                    duration: 800.ms,
                  ),

              const SizedBox(height: 16),

              Text(
                'Just a moment...',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),

              const SizedBox(height: 24),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _messages[_messageIndex],
                  key: ValueKey(_messageIndex),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor:
                      AppColors.primaryOrange.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryOrange,
                  ),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const Spacer(flex: 1),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '💬',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"I\'m checking for any hidden nasties so your meal stays as pure as my grandmother\'s Sunday stew."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppColors.white.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
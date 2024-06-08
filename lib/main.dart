import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(VoiceAssistantApp());
}

class VoiceAssistantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Amigo'),
        ),
        body: VoiceAssistantUI(),
      ),
    );
  }
}

class VoiceAssistantUI extends StatefulWidget {
  @override
  _VoiceAssistantUIState createState() => _VoiceAssistantUIState();
}

class _VoiceAssistantUIState extends State<VoiceAssistantUI> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _emoExpression = 'neutral';

  final List<String> _randomDialogues = [
    "I am feeling boring.",
    "Let me answer something.",
    "Please ask me something.",
    "I am enjoying our conversation",
    "you can ask me anything",
    "sitting idle is not very enjoyable",
    "Don't shy please ask me something",
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeSpeechToText();
  }

  void _initializeSpeechToText() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('onStatus: $status'),
      onError: (error) => _handleSpeechError(error),
    );
    if (available) {
      _startListening();
    } else {
      setState(() => _isListening = false);
    }
  }

  void _handleSpeechError(dynamic error) {
    print('onError: ${error.errorMsg}, permanent: ${error.permanent}');
    setState(() {
      _emoExpression = 'sad';
    });
    _sayRandomDialogue();
  }

  void _startListening() async {
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          if (result.recognizedWords.isEmpty) {
            _sayRandomDialogue();
          } else {
            _sendQuestion(result.recognizedWords);
          }
          setState(() => _isListening = false);
        }
      },
      listenFor: Duration(seconds: 10),
      pauseFor: Duration(seconds: 5),
      onSoundLevelChange: (level) => print('Sound level: $level'),
      cancelOnError: true,
      partialResults: false,
    );
  }

  void _sendQuestion(String question) async {
    setState(() {
      _emoExpression = 'thinking';
    });

    try {
      final response = await http.post(
        Uri.parse('https://hakirmubarmaj.pythonanywhere.com/ask_question'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'question': question}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String answer = data['answer'];
        setState(() {
          _emoExpression = 'speaking';
        });
        await _speak(answer);
      } else {
        setState(() {
          _emoExpression = 'sad';
        });
        _startListening();
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _emoExpression = 'sad';
      });
      _startListening();
    }
  }

  void _sayRandomDialogue() async {
    Random random = Random();
    String dialogue = _randomDialogues[random.nextInt(_randomDialogues.length)];
    await _speak(dialogue);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(0.5);  // Lower pitch for a more robotic sound
    await _flutterTts.setSpeechRate(0.6);  // Higher speech rate for a robotic sound
    await _flutterTts.setVolume(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
    _flutterTts.setStartHandler(() {
      setState(() {
        _emoExpression = 'speaking';
      });
    });
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _emoExpression = 'neutral';
      });
      _startListening();
    });
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EMOFace(expression: _emoExpression),
    );
  }
}

class EMOFace extends StatelessWidget {
  final String expression;

  EMOFace({required this.expression});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(200, 200),
      painter: EMOFacePainter(expression: expression),
    );
  }
}

class EMOFacePainter extends CustomPainter {
  final String expression;

  EMOFacePainter({required this.expression});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final eyePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final mouthPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Draw the face background
    final faceRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(faceRect, Radius.circular(20)),
      paint,
    );

    // Draw the eyes
    final eyeRadius = 10.0;
    final eyeOffsetY = size.height / 3;

    switch (expression) {
      case 'happy':
        _drawHappyEyes(canvas, size, eyePaint, eyeRadius, eyeOffsetY);
        _drawHappyMouth(canvas, size, mouthPaint);
        break;
      case 'sad':
        _drawSadEyes(canvas, size, eyePaint, eyeRadius, eyeOffsetY);
        _drawSadMouth(canvas, size, mouthPaint);
        break;
      case 'thinking':
        _drawThinkingEyes(canvas, size, eyePaint, eyeRadius, eyeOffsetY);
        _drawThinkingMouth(canvas, size, mouthPaint);
        break;
      case 'speaking':
        _drawNeutralEyes(canvas, size, eyePaint, eyeRadius, eyeOffsetY);
        _drawSpeakingMouth(canvas, size, mouthPaint);
        break;
      default:
        _drawNeutralEyes(canvas, size, eyePaint, eyeRadius, eyeOffsetY);
        _drawNeutralMouth(canvas, size, mouthPaint);
    }
  }

  void _drawNeutralEyes(Canvas canvas, Size size, Paint paint, double radius, double offsetY) {
    final leftEyeCenter = Offset(size.width / 4, offsetY);
    final rightEyeCenter = Offset(3 * size.width / 4, offsetY);
    canvas.drawCircle(leftEyeCenter, radius, paint);
    canvas.drawCircle(rightEyeCenter, radius, paint);
  }

  void _drawHappyEyes(Canvas canvas, Size size, Paint paint, double radius, double offsetY) {
    final leftEyeCenter = Offset(size.width / 4, offsetY);
    final rightEyeCenter = Offset(3 * size.width / 4, offsetY);
    canvas.drawArc(Rect.fromCircle(center: leftEyeCenter, radius: radius), 0, 3.14, false, paint);
    canvas.drawArc(Rect.fromCircle(center: rightEyeCenter, radius: radius), 0, 3.14, false, paint);
  }

  void _drawSadEyes(Canvas canvas, Size size, Paint paint, double radius, double offsetY) {
    final leftEyeCenter = Offset(size.width / 4, offsetY);
    final rightEyeCenter = Offset(3 * size.width / 4, offsetY);
    canvas.drawArc(Rect.fromCircle(center: leftEyeCenter, radius: radius), 3.14, 3.14, false, paint);
    canvas.drawArc(Rect.fromCircle(center: rightEyeCenter, radius: radius), 3.14, 3.14, false, paint);
  }

  void _drawThinkingEyes(Canvas canvas, Size size, Paint paint, double radius, double offsetY) {
    final leftEyeCenter = Offset(size.width / 4, offsetY);
    final rightEyeCenter = Offset(3 * size.width / 4, offsetY);
    canvas.drawCircle(leftEyeCenter, radius, paint);
    canvas.drawCircle(rightEyeCenter, radius, paint);
    canvas.drawLine(
      Offset(leftEyeCenter.dx - radius, leftEyeCenter.dy + radius),
      Offset(leftEyeCenter.dx + radius, leftEyeCenter.dy + radius),
      paint,
    );
    canvas.drawLine(
      Offset(rightEyeCenter.dx - radius, rightEyeCenter.dy + radius),
      Offset(rightEyeCenter.dx + radius, rightEyeCenter.dy + radius),
      paint,
    );
  }

  void _drawNeutralMouth(Canvas canvas, Size size, Paint paint) {
    final mouthRect = Rect.fromLTWH(size.width / 4, 2 * size.height / 3, size.width / 2, size.height / 6);
    canvas.drawArc(mouthRect, 0, 3.14, false, paint);
  }

  void _drawHappyMouth(Canvas canvas, Size size, Paint paint) {
    final mouthRect = Rect.fromLTWH(size.width / 4, 2 * size.height / 3, size.width / 2, size.height / 6);
    canvas.drawArc(mouthRect, 0, -3.14, false, paint);
  }

  void _drawSadMouth(Canvas canvas, Size size, Paint paint) {
    final mouthRect = Rect.fromLTWH(size.width / 4, 2 * size.height / 3, size.width / 2, size.height / 6);
    canvas.drawArc(mouthRect, 0, 3.14, false, paint);
  }

  void _drawThinkingMouth(Canvas canvas, Size size, Paint paint) {
    final mouthCenter = Offset(size.width / 2, 2 * size.height / 3 + size.height / 12);
    canvas.drawLine(
      Offset(mouthCenter.dx - size.width / 8, mouthCenter.dy),
      Offset(mouthCenter.dx + size.width / 8, mouthCenter.dy),
      paint,
    );
  }

  void _drawSpeakingMouth(Canvas canvas, Size size, Paint paint) {
    final mouthCenter = Offset(size.width / 2, 2 * size.height / 3 + size.height / 12);
    final mouthHeight = size.height / 12;
    final mouthWidth = size.width / 4;
    canvas.drawLine(
      Offset(mouthCenter.dx - mouthWidth / 2, mouthCenter.dy - mouthHeight / 2),
      Offset(mouthCenter.dx + mouthWidth / 2, mouthCenter.dy + mouthHeight / 2),
      paint,
    );
    canvas.drawLine(
      Offset(mouthCenter.dx - mouthWidth / 2, mouthCenter.dy + mouthHeight / 2),
      Offset(mouthCenter.dx + mouthWidth / 2, mouthCenter.dy - mouthHeight / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';


class VoiceAssistantUI extends StatefulWidget {
  final String data;

  VoiceAssistantUI({required Key key, required this.data}) : super(key: key);

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
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _hi();
    _startListening();
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  void _hi() async {
    setState(() {
      _emoExpression = 'hi';
    });
    _speakHi("hi there, this is amigo");
    await Future.delayed(const Duration(seconds: 3));
  }

  void _startListening() async {
    setState(() {
      _emoExpression = 'neutral';
    });
    bool available = await _speech.initialize(
      onStatus: (status) => print('onStatus: $status'),
      onError: (error) => _handleSpeechError(error),
    );
    if (available) {
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
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 5),
        onSoundLevelChange: (level) => print('Sound level: $level'),
        cancelOnError: true,
        partialResults: false,
      );
    } else {
      setState(() => _isListening = false);
    }
  }

  void _handleSpeechError(dynamic error) {
    print('onError: ${error.errorMsg}, permanent: ${error.permanent}');
    setState(() {
      _emoExpression = 'neutral';
    });
    _startListening();
  }

  void _sayRandomDialogue() async {
    Random random = Random();
    String dialogue = _randomDialogues[random.nextInt(_randomDialogues.length)];
    await _speak(dialogue);
  }

  void _sendQuestion(String question) async {
    setState(() {
      _emoExpression = 'listening';
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

  Future<void> _speakHi(String text) async {
    await _flutterTts.setLanguage('en-US');
    if(widget.data == 'women') {
      await _flutterTts.setPitch(0.3);
    }
    if(widget.data == 'men') {
      await _flutterTts.setPitch(0.65);
    }
    if(widget.data == 'robot') {
      await _flutterTts.setPitch(0.5);
    }
    await _flutterTts.setSpeechRate(0.4); 
    await _flutterTts.setVolume(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
    _flutterTts.setStartHandler(() {
      setState(() {
        _emoExpression = 'hi';
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

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage('en-US');
    if(widget.data == 'women') {
      await _flutterTts.setPitch(0.3);
    }
    if(widget.data == 'men') {
      await _flutterTts.setPitch(0.65);
    }
    if(widget.data == 'robot') {
      await _flutterTts.setPitch(0.5);
    }
    await _flutterTts.setSpeechRate(0.4); 
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
    return ExpressionAnimation(expression: expression);
  }
}

class ExpressionAnimation extends StatefulWidget {
  final String expression;

  ExpressionAnimation({required this.expression});

  @override
  _ExpressionAnimationState createState() => _ExpressionAnimationState();
}

class _ExpressionAnimationState extends State<ExpressionAnimation>
    with SingleTickerProviderStateMixin {
  List<String> _frames = [];
  int _currentFrame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateFrames(widget.expression);
    _startAnimation();
  }

  @override
  void didUpdateWidget(ExpressionAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression != widget.expression) {
      _updateFrames(widget.expression);
      _startAnimation();
    }
  }

  void _updateFrames(String expression) {
    switch (expression) {
      case 'speaking':
        _frames = [
          'assets/speak1.jpg',
          'assets/speak2.jpg',
          'assets/speak3.jpg',
          'assets/speak4.jpg',
          'assets/speak5.jpg',
          'assets/speak4.jpg',
          'assets/speak3.jpg',
          'assets/speak2.jpg',
          'assets/speak1.jpg',
          'assets/speak6.jpg',
          'assets/speak7.jpg',
          'assets/speak8.jpg',
          'assets/speak6.jpg',
          'assets/speak7.jpg',
          'assets/speak8.jpg',
          'assets/speak9.jpg',
          'assets/speak10.jpg',
          'assets/speak11.jpg',
          'assets/speak12.jpg',
          'assets/speak11.jpg',
          'assets/speak10.jpg',
          'assets/speak9.jpg',
          'assets/speak10.jpg',
          'assets/speak11.jpg',
        ];
        break;
      case 'neutral':
        _frames = [
          'assets/hold1.jpg',
          'assets/hold2.jpg',
          'assets/hold3.jpg',
          'assets/hold4.jpg',
          'assets/hold5.jpg',
          'assets/hold4.jpg',
          'assets/hold3.jpg',
          'assets/hold2.jpg',
        ];
        break;
      case 'listening':
        _frames = [
          'assets/hearing.jpg',
          'assets/hearing.jpg',
          'assets/hearing.jpg',
          'assets/hearing.jpg',
          'assets/hearing.jpg',
          'assets/hearing.jpg',
        ];
        break;
      case 'hi':
        _frames = [
          'assets/hi1.jpg',
          'assets/hi2.jpg',
          'assets/hi3.jpg',
        ];
        break;
      default:
        _frames = ['assets/hold1.jpg'];
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    _currentFrame = 0;
    if (_frames.isNotEmpty) {
      _timer = Timer.periodic(Duration(milliseconds: 200), (timer) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _frames.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frames.isEmpty) return Container();
    return Image.asset(_frames[_currentFrame], fit: BoxFit.cover, width: double.infinity, height: double.infinity);
  }
}
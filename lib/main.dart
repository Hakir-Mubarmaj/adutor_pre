import 'dart:convert';
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
          title: Text('Voice Assistant'),
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
  final TextEditingController _controller = TextEditingController();
  final List<String> _responses = [];
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  void _triggerVoiceAssistant() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('onStatus: $status'),
        onError: (error) => print('onError: $error'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              _sendQuestion(result.recognizedWords);
              setState(() => _isListening = false);
            }
          },
        );
      } else {
        setState(() => _isListening = false);
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _sendQuestion(String question) async {
    setState(() {
      _responses.add('Question: $question');
      _controller.clear();
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
          _responses.add('Response: $answer');
        });
        await _speak(answer);
      } else {
        setState(() {
          _responses.add('Response: Failed to get answer');
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _responses.add('Response: Failed to send question');
      });
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _triggerVoiceAssistant,
          child: Text(_isListening ? 'Listening...' : 'Press to Activate Voice Assistant'),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Type your question here',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => _sendQuestion(_controller.text),
          child: Text('Send'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _responses.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_responses[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

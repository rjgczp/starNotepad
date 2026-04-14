import 'package:flutter/material.dart';

class AiAssistantPage extends StatelessWidget {
  const AiAssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI助手')),
      body: const SafeArea(
        child: Center(
          child: Text(
            'AI助手',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

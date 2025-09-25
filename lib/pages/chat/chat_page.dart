import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        title: const Text('Tanya AI', style: TextStyle(color: Colors.black),),
        centerTitle: true,
        backgroundColor: const Color(0xFFEEEEEE),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri("https://agritrack-ai.vercel.app"),
        ),
      ),
    );
  }
}

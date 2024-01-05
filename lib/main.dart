import 'package:flutter/material.dart';
import 'package:new_binance_bot/theme/dark_theme.dart';
import 'package:new_binance_bot/ui/create_trade_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: DarkTheme.getTheme(),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final TextEditingController apiKeyController = TextEditingController();
  final TextEditingController secreteKeyController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Přihlášení')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(labelText: 'API key'),
              ),
              TextField(
                controller: secreteKeyController,
                decoration: const InputDecoration(labelText: 'API secret'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateTradeWidget()),
                  );
                },
                child: const Text('Přihlásit se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
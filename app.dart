import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Smart Alert App'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Status: Normal',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Enable Notifications'),
                value: true,
                onChanged: (_) {},
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Check Status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

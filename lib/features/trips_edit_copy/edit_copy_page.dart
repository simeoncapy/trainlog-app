import 'package:flutter/material.dart';

class EditCopyPage extends StatefulWidget {
  const EditCopyPage({super.key});

  @override
  State<EditCopyPage> createState() => _EditCopyPageState();
}

class _EditCopyPageState extends State<EditCopyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Copy'),
      ),
      body: const Center(
        child: Text('This is a basic stateful widget page.'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SmartGroceryScreen extends ConsumerWidget {
  const SmartGroceryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('Smart Grocery Screen')),
    );
  }
}
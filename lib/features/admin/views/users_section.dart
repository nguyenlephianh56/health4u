// lib/features/admin/views/users_section.dart
//
// Tab Users — placeholder, sẽ bổ sung sau

import 'package:flutter/material.dart';

class UsersSection extends StatelessWidget {
  const UsersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Text('👥', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Quản lý Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0284C7),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Sẽ được bổ sung sau.',
              style: TextStyle(color: Colors.black45, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
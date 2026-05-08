// lib/features/admin/views/content_section.dart
//
// Tab Content: sub-tab Recipes | Workouts
// Chỉ lo điều phối giữa RecipeTabView và WorkoutTabView

import 'package:flutter/material.dart';
import '../viewmodels/admin_state.dart';
import '../viewmodels/admin_viewmodel.dart';
import 'admin_tab_bar.dart';
import 'recipe_tab_view.dart';
import 'workout_tab_view.dart';

class ContentSection extends StatelessWidget {
  final AdminState state;
  final AdminViewModel vm;

  const ContentSection({
    super.key,
    required this.state,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-tab Recipes | Workouts
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              AdminSubTabBtn(
                label: '🍽️  Recipes',
                isActive: state.activeContentTab == ContentTab.recipes,
                onTap: () => vm.setContentTab(ContentTab.recipes),
              ),
              AdminSubTabBtn(
                label: '💪  Workouts',
                isActive: state.activeContentTab == ContentTab.workouts,
                onTap: () => vm.setContentTab(ContentTab.workouts),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Nội dung theo sub-tab
        if (state.activeContentTab == ContentTab.recipes)
          RecipeTabView(state: state, vm: vm)
        else
          WorkoutTabView(state: state, vm: vm),
      ],
    );
  }
}
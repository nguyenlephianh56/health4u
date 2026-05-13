// lib/features/admin/views/users_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../viewmodels/admin_state.dart';
import '../widgets/user_card_widget.dart';

class UsersSection extends ConsumerWidget {
  const UsersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminViewModelProvider);
    final vm    = ref.read(adminViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search bar ────────────────────────────────────────────────
        _SearchBar(
          query:     state.searchQuery,
          onChanged: vm.searchUsers,
        ),
        const SizedBox(height: 14),

        // ── Loading ───────────────────────────────────────────────────
        if (state.status == AdminStatus.loading && state.allUsers.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )

        // ── Empty (chưa có user nào) ──────────────────────────────────
        else if (state.filteredUsers.isEmpty && state.searchQuery.isEmpty)
          const _EmptyUsers()

        // ── Không tìm thấy ────────────────────────────────────────────
        else if (state.filteredUsers.isEmpty)
            _NoResult(query: state.searchQuery)

          // ── Danh sách ─────────────────────────────────────────────────
          else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  state.searchQuery.isEmpty
                      ? 'Tổng ${state.filteredUsers.length} người dùng'
                      : 'Tìm thấy ${state.filteredUsers.length} kết quả',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ...state.filteredUsers.map(
                    (user) => UserCardWidget(
                  user:     user,
                  onDelete: () =>
                      _confirmDelete(context, vm, user.id, user.name),
                ),
              ),
            ],
      ],
    );
  }

  void _confirmDelete(
      BuildContext context,
      AdminViewModel vm,
      String uid,
      String name,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa người dùng?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Bạn có chắc muốn xóa "$name" không?\n'
              'Hành động này không thể hoàn tác.',
          style: TextStyle(color: Colors.black.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await vm.deleteUser(uid);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  final String                 query;
  final void Function(String)  onChanged;
  const _SearchBar({required this.query, required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _ctrl,
        enableIMEPersonalizedLearning: true,
        onChanged: (v) {
          setState(() {}); // rebuild để show/hide clear button
          widget.onChanged(v);
        },
        style: const TextStyle(fontSize: 14, color: AppColors.text),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên người dùng...',
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.3),
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.primary, size: 20),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.close_rounded,
                color: Colors.black.withOpacity(0.3), size: 18),
            onPressed: () {
              _ctrl.clear();
              setState(() {});
              widget.onChanged('');
            },
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────
class _EmptyUsers extends StatelessWidget {
  const _EmptyUsers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Text('👥', style: TextStyle(fontSize: 40)),
            SizedBox(height: 10),
            Text(
              'Chưa có người dùng nào.',
              style: TextStyle(color: Colors.black45, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResult extends StatelessWidget {
  final String query;
  const _NoResult({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Text('🔍', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(
              'Không tìm thấy "$query"',
              style: const TextStyle(color: Colors.black45, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
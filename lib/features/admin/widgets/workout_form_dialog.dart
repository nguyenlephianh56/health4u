// lib/features/admin/widgets/workout_form_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/workout_model.dart';
import '../../../data/services/cloudinary_service.dart';
import '../../../core/constants/app_colors.dart';

class WorkoutFormDialog extends StatefulWidget {
  final WorkoutModel? workout; // null = thêm mới, có giá trị = sửa
  final void Function(WorkoutModel) onSave;

  const WorkoutFormDialog({
    super.key,
    this.workout,
    required this.onSave,
  });

  @override
  State<WorkoutFormDialog> createState() => _WorkoutFormDialogState();
}

class _WorkoutFormDialogState extends State<WorkoutFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _uuid    = const Uuid();
  final _picker  = ImagePicker();

  // ── Controllers ──────────────────────────────────────────────────────────
  late final TextEditingController _titleCtrl;
  late final TextEditingController _durationCtrl;

  // ── State ────────────────────────────────────────────────────────────────
  String _category      = 'Cardio';
  String _difficulty    = 'Beginner';
  String _muscleGroup   = 'Toàn thân';
  late final TextEditingController _caloriesCtrl;

  // Image state
  File?  _pickedImageFile;
  String _imageUrl    = '';
  bool   _isUploading = false;

  // Exercises list
  late List<_ExerciseControllers> _exerciseCtrls;

  static const _categories  = ['Cardio', 'Strength', 'Yoga'];
  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    final w = widget.workout;

    _titleCtrl    = TextEditingController(text: w?.title ?? '');
    _durationCtrl = TextEditingController(
        text: w != null ? w.durationMin.toString() : '');

    _category      = w?.category      ?? 'Cardio';
    _difficulty    = w?.difficulty    ?? 'Beginner';
    _muscleGroup   = w?.muscleGroup   ?? 'Toàn thân';
    _caloriesCtrl  = TextEditingController(
        text: w != null ? w.caloriesBurned.toString() : '');
    _imageUrl   = w?.imageUrl   ?? '';

    final existingExercises = w?.exercises ?? [];
    _exerciseCtrls = existingExercises.isNotEmpty
        ? existingExercises
        .map((e) => _ExerciseControllers.fromExercise(e))
        .toList()
        : [_ExerciseControllers.empty()]; // 1 exercise rỗng mặc định
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
    for (final c in _exerciseCtrls) c.dispose();
    super.dispose();
  }

  // ── Image ─────────────────────────────────────────────────────────────────
  Future<void> _pickAndUploadImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _pickedImageFile = file;
      _isUploading     = true;
    });

    try {
      final url = await CloudinaryService.uploadImage(file);
      setState(() {
        _imageUrl    = url;
        _isUploading = false;
      });
      _showSuccess('Tải ảnh lên thành công!');
    } catch (e) {
      setState(() {
        _isUploading     = false;
        _pickedImageFile = null;
      });
      _showError('Tải ảnh thất bại: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImageFile = null;
      _imageUrl        = '';
    });
  }

  // ── Exercise image per item ───────────────────────────────────────────────
  Future<void> _pickAndUploadExerciseImage(int index) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _exerciseCtrls[index].pickedImageFile = file;
      _exerciseCtrls[index].isUploading     = true;
    });

    try {
      final url = await CloudinaryService.uploadImage(file);
      setState(() {
        _exerciseCtrls[index].imageUrl    = url;
        _exerciseCtrls[index].isUploading = false;
      });
      _showSuccess('Tải ảnh bài tập lên thành công!');
    } catch (e) {
      setState(() {
        _exerciseCtrls[index].isUploading     = false;
        _exerciseCtrls[index].pickedImageFile = null;
      });
      _showError('Tải ảnh thất bại: $e');
    }
  }

  void _removeExerciseImage(int index) {
    setState(() {
      _exerciseCtrls[index].pickedImageFile = null;
      _exerciseCtrls[index].imageUrl        = '';
    });
  }

  // ── Exercises ─────────────────────────────────────────────────────────────
  void _addExercise() =>
      setState(() => _exerciseCtrls.add(_ExerciseControllers.empty()));

  void _removeExercise(int index) {
    if (_exerciseCtrls.length <= 1) return;
    setState(() {
      _exerciseCtrls[index].dispose();
      _exerciseCtrls.removeAt(index);
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    if (_isUploading) {
      _showError('Vui lòng chờ ảnh tải xong');
      return;
    }

    // Lọc exercise rỗng
    final exercises = _exerciseCtrls
        .where((c) => c.nameCtrl.text.trim().isNotEmpty)
        .map((c) => ExerciseItem(
      id:          _uuid.v4(),
      name:        c.nameCtrl.text.trim(),
      sets:        int.tryParse(c.setsCtrl.text) ?? 0,
      reps:        int.tryParse(c.repsCtrl.text) ?? 0,
      restSec:     int.tryParse(c.restCtrl.text) ?? 0,
      instruction: c.instructionCtrl.text.trim(),
      imageUrl:    c.imageUrl,
    ))
        .toList();

    if (exercises.isEmpty) {
      _showError('Vui lòng nhập ít nhất 1 bài tập');
      return;
    }

    final workout = WorkoutModel(
      id:             widget.workout?.id ?? '',
      title:          _titleCtrl.text.trim(),
      category:       _category,
      difficulty:     _difficulty,
      durationMin:    int.tryParse(_durationCtrl.text) ?? 0,
      muscleGroup:    _muscleGroup,
      caloriesBurned: int.tryParse(_caloriesCtrl.text) ?? 0,
      exercises:   exercises,
      imageUrl:    _imageUrl,
    );

    widget.onSave(workout);
    Navigator.of(context).pop();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.workout != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(isEdit),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Tên bài tập ───────────────────────────────────
                      _sectionLabel('Tên bài tập'),
                      _SimpleTextField(
                        controller: _titleCtrl,
                        hint: 'VD: HIIT Cardio Blast',
                        validator: (v) =>
                        v!.isEmpty ? 'Vui lòng nhập tên' : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Category ─────────────────────────────────────
                      _sectionLabel('Danh mục (Category)'),
                      _buildCategoryPicker(),
                      const SizedBox(height: 16),

                      // ── Difficulty ───────────────────────────────────
                      _sectionLabel('Độ khó (Difficulty)'),
                      _buildDifficultyPicker(),
                      const SizedBox(height: 16),

                      // ── Duration ─────────────────────────────────────
                      _sectionLabel('Nhóm cơ (Muscle Group)'),
                      _buildMuscleGroupPicker(),
                      const SizedBox(height: 16),

                      _sectionLabel('Calo đốt được (kcal)'),
                      _SimpleTextField(
                        controller: _caloriesCtrl,
                        hint: '300',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 16),

                      _sectionLabel('Tổng thời gian (phút)'),
                      _SimpleTextField(
                        controller: _durationCtrl,
                        hint: '30',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) =>
                        v!.isEmpty ? 'Nhập thời gian' : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Exercises ────────────────────────────────────
                      _sectionLabel('Danh sách bài tập'),
                      _buildExercisesSection(),
                      const SizedBox(height: 16),

                      // ── Ảnh / GIF ────────────────────────────────────
                      _sectionLabel('Ảnh / GIF minh họa'),
                      _buildImagePicker(),
                      const SizedBox(height: 24),

                      // ── Nút lưu ──────────────────────────────────────
                      _buildSaveButton(isEdit),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI builders ──────────────────────────────────────────────────────────

  Widget _buildHeader(bool isEdit) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Text(
            isEdit ? '✏️  Sửa bài tập' : '➕  Thêm bài tập mới',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Wrap(
      spacing: 8,
      children: _categories.map((cat) {
        final isSelected = _category == cat;
        final label = {
          'Cardio':   '🏃 Cardio',
          'Strength': '🏋️ Strength',
          'Yoga':     '🧘 Yoga',
        }[cat] ?? cat;

        return GestureDetector(
          onTap: () => setState(() => _category = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDifficultyPicker() {
    final labels = {
      'Beginner':     '🟢 Dễ',
      'Intermediate': '🟡 Trung bình',
      'Advanced':     '🔴 Khó',
    };
    final colors = {
      'Beginner':     const Color(0xFF16A34A),
      'Intermediate': const Color(0xFFB45309),
      'Advanced':     const Color(0xFFDC2626),
    };

    return Row(
      children: _difficulties.map((diff) {
        final isSelected = _difficulty == diff;
        final isLast = diff == _difficulties.last;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _difficulty = diff),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: isLast ? 0 : 8),
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors[diff]!.withOpacity(0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? colors[diff]!
                      : Colors.black.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  labels[diff] ?? diff,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? colors[diff]!
                        : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExercisesSection() {
    return Column(
      children: [
        // Header
        const Row(
          children: [
            Expanded(flex: 3, child: _ColHeader(label: 'Tên bài tập')),
            SizedBox(width: 6),
            Expanded(flex: 1, child: _ColHeader(label: 'Sets')),
            SizedBox(width: 6),
            Expanded(flex: 1, child: _ColHeader(label: 'Reps')),
            SizedBox(width: 6),
            Expanded(flex: 2, child: _ColHeader(label: 'Nghỉ (giây)')),
            SizedBox(width: 36),
          ],
        ),
        const SizedBox(height: 6),

        // Danh sách exercise
        ...List.generate(_exerciseCtrls.length, (i) {
          final ex = _exerciseCtrls[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row: Tên | Sets | Reps | Rest | Xóa ─────────────
                Row(
                  children: [
                    // Tên bài tập
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        key: ValueKey('ex_name_$i'),
                        controller: ex.nameCtrl,
                        enableIMEPersonalizedLearning: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: _inputDecoration(hint: 'VD: Squat'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Sets
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        key: ValueKey('ex_sets_$i'),
                        controller: ex.setsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(fontSize: 13),
                        decoration: _inputDecoration(hint: '3'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Reps
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        key: ValueKey('ex_reps_$i'),
                        controller: ex.repsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(fontSize: 13),
                        decoration: _inputDecoration(hint: '12'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Rest seconds
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: ValueKey('ex_rest_$i'),
                        controller: ex.restCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(fontSize: 13),
                        decoration: _inputDecoration(hint: '60'),
                      ),
                    ),
                    // Nút xóa
                    if (_exerciseCtrls.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.redAccent, size: 20),
                        onPressed: () => _removeExercise(i),
                      )
                    else
                      const SizedBox(width: 36),
                  ],
                ),
                // ── Hướng dẫn chi tiết ───────────────────────────────
                const SizedBox(height: 6),
                TextFormField(
                  key: ValueKey('ex_instruction_$i'),
                  controller: ex.instructionCtrl,
                  enableIMEPersonalizedLearning: true,
                  maxLines: 3,
                  minLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDecoration(
                    hint: 'Hướng dẫn thực hiện... VD: Đứng thẳng, hạ người xuống từ từ, giữ lưng thẳng...',
                  ).copyWith(
                    hintMaxLines: 2,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 10, right: 6, top: 12),
                      child: Icon(Icons.menu_book_rounded,
                          color: AppColors.primary, size: 16),
                    ),
                    prefixIconConstraints: const BoxConstraints(),
                  ),
                ),
                // ── Ảnh minh họa cho exercise này ───────────────────
                const SizedBox(height: 8),
                _buildExerciseImagePicker(i),
              ],
            ),
          );
        }),

        // Nút thêm exercise
        GestureDetector(
          onTap: _addExercise,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 6),
                Text(
                  'Thêm bài tập',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Ảnh riêng cho từng exercise ──────────────────────────────────────────
  Widget _buildExerciseImagePicker(int index) {
    final ex = _exerciseCtrls[index];

    // Đang upload
    if (ex.isUploading) {
      return Container(
        width: double.infinity,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 10),
            Text(
              'Đang tải ảnh lên...',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // Đã có ảnh
    if (ex.pickedImageFile != null || ex.imageUrl.isNotEmpty) {
      return Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ex.pickedImageFile != null
                ? Image.file(
              ex.pickedImageFile!,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            )
                : Image.network(
              ex.imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 72,
                  height: 72,
                  color: Colors.white,
                  child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: Colors.white,
                child: const Icon(Icons.broken_image_outlined,
                    color: Colors.black26, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Badge + actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 12, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text(
                        'Đã có ảnh',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _pickAndUploadExerciseImage(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Đổi ảnh',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeExerciseImage(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Xoá',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE53935)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Chưa có ảnh
    return GestureDetector(
      onTap: () => _pickAndUploadExerciseImage(index),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.primary.withOpacity(0.7), size: 18),
            const SizedBox(width: 6),
            Text(
              'Thêm ảnh minh họa cho bài tập này',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    // Đang upload
    if (_isUploading) {
      return Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary),
            ),
            SizedBox(height: 10),
            Text(
              'Đang tải lên Cloudinary...',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // Đã có ảnh
    if (_pickedImageFile != null || _imageUrl.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _pickedImageFile != null
                ? Image.file(
              _pickedImageFile!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            )
                : Image.network(
              _imageUrl,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 160,
                  color: Colors.white,
                  child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: Colors.white,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.black26, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 6),
                      Text(
                        'Đã upload thành công',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _pickAndUploadImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Đổi ảnh',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Xoá',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE53935)),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Chưa có ảnh
    return GestureDetector(
      onTap: _pickAndUploadImage,
      child: Container(
        width: double.infinity,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_photo_alternate_outlined,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn ảnh / GIF từ thư viện',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 2),
            Text(
              'Upload lên Cloudinary, lưu URL vào Firebase',
              style: TextStyle(
                  fontSize: 11, color: Colors.black.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }

  static const _muscleGroups = [
    'Ngực', 'Lưng', 'Chân', 'Vai', 'Tay', 'Cơ bụng', 'Toàn thân', 'Tim mạch',
  ];

  Widget _buildMuscleGroupPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _muscleGroups.map((group) {
        final isSelected = _muscleGroup == group;
        return GestureDetector(
          onTap: () => setState(() => _muscleGroup = group),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Text(
              group,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton(bool isEdit) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: _isUploading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white),
        )
            : Text(
          isEdit ? 'Cập nhật bài tập' : 'Thêm bài tập',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
      TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2)),
    );
  }
}

// ── _SimpleTextField — StatelessWidget, không FocusNode ──────────────────────
class _SimpleTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _SimpleTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      enableIMEPersonalizedLearning: true,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Colors.red, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
      ),
    );
  }
}

// ── _ColHeader ────────────────────────────────────────────────────────────────
class _ColHeader extends StatelessWidget {
  final String label;
  const _ColHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black.withOpacity(0.45)),
    );
  }
}

// ── _ExerciseControllers ──────────────────────────────────────────────────────
class _ExerciseControllers {
  final TextEditingController nameCtrl;
  final TextEditingController setsCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController restCtrl;
  final TextEditingController instructionCtrl;

  // ── Ảnh riêng cho từng exercise ──
  File?  pickedImageFile;
  String imageUrl;
  bool   isUploading;

  _ExerciseControllers({
    required this.nameCtrl,
    required this.setsCtrl,
    required this.repsCtrl,
    required this.restCtrl,
    required this.instructionCtrl,
    this.pickedImageFile,
    this.imageUrl    = '',
    this.isUploading = false,
  });

  factory _ExerciseControllers.empty() => _ExerciseControllers(
    nameCtrl:        TextEditingController(),
    setsCtrl:        TextEditingController(),
    repsCtrl:        TextEditingController(),
    restCtrl:        TextEditingController(),
    instructionCtrl: TextEditingController(),
  );

  factory _ExerciseControllers.fromExercise(ExerciseItem e) =>
      _ExerciseControllers(
        nameCtrl:        TextEditingController(text: e.name),
        setsCtrl:        TextEditingController(text: e.sets.toString()),
        repsCtrl:        TextEditingController(text: e.reps.toString()),
        restCtrl:        TextEditingController(text: e.restSec.toString()),
        instructionCtrl: TextEditingController(text: e.instruction),
        imageUrl:        e.imageUrl,
      );

  void dispose() {
    nameCtrl.dispose();
    setsCtrl.dispose();
    repsCtrl.dispose();
    restCtrl.dispose();
    instructionCtrl.dispose();
  }
}
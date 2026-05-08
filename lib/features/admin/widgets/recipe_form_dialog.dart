// lib/features/admin/widgets/recipe_form_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/recipe_model.dart';
import '../../../data/services/cloudinary_service.dart';
import '../../../core/constants/app_colors.dart';

class RecipeFormDialog extends StatefulWidget {
  final RecipeModel? recipe;
  final void Function(RecipeModel) onSave;

  const RecipeFormDialog({
    super.key,
    this.recipe,
    required this.onSave,
  });

  @override
  State<RecipeFormDialog> createState() => _RecipeFormDialogState();
}

class _RecipeFormDialogState extends State<RecipeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _uuid    = const Uuid();
  final _picker  = ImagePicker();

  // ── Controllers ──────────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _prepTimeCtrl;
  late final TextEditingController _caloriesCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;

  // ── State ────────────────────────────────────────────────────────────────
  String  _mealType     = 'Breakfast';
  bool    _isVegan      = false;
  bool    _isVegetarian = false;

  // Image state
  File?   _pickedImageFile;   // File ảnh đã chọn từ máy (chưa upload)
  String  _imageUrl     = ''; // URL cuối cùng (sau khi upload Cloudinary)
  bool    _isUploading  = false; // Đang upload lên Cloudinary

  late List<TextEditingController> _instructionCtrls;
  late List<_IngredientControllers> _ingredientCtrls;

  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;

    _nameCtrl     = TextEditingController(text: r?.name ?? '');
    _prepTimeCtrl = TextEditingController(
        text: r != null ? r.prepTimeMin.toString() : '');
    _caloriesCtrl = TextEditingController(
        text: r != null ? r.nutrition.calories.toStringAsFixed(0) : '');
    _proteinCtrl  = TextEditingController(
        text: r != null ? r.nutrition.protein.toStringAsFixed(0) : '');
    _carbsCtrl    = TextEditingController(
        text: r != null ? r.nutrition.carbs.toStringAsFixed(0) : '');
    _fatCtrl      = TextEditingController(
        text: r != null ? r.nutrition.fat.toStringAsFixed(0) : '');

    _mealType     = r?.mealType ?? 'Breakfast';
    _isVegan      = r?.flags.isVegan ?? false;
    _isVegetarian = r?.flags.isVegetarian ?? false;

    // Nếu đang sửa recipe đã có ảnh → giữ URL cũ
    _imageUrl = r?.imageUrl ?? '';

    final existingSteps = r?.instructions ?? [];
    final steps = existingSteps.isNotEmpty ? existingSteps : ['', '', '', ''];
    _instructionCtrls =
        steps.map((s) => TextEditingController(text: s)).toList();

    final existingIngredients = r?.ingredients ?? [];
    _ingredientCtrls = existingIngredients.isNotEmpty
        ? existingIngredients
        .map((ing) => _IngredientControllers.fromIngredient(ing))
        .toList()
        : [_IngredientControllers.empty()];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _prepTimeCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    for (final c in _instructionCtrls) c.dispose();
    for (final c in _ingredientCtrls) c.dispose();
    super.dispose();
  }

  // ── Image picker ─────────────────────────────────────────────────────────

  /// Mở thư viện ảnh → chọn ảnh → upload Cloudinary → lưu URL
  Future<void> _pickAndUploadImage() async {
    // 1. Mở thư viện ảnh
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // Nén ảnh còn 85% để giảm dung lượng upload
      maxWidth: 1200,   // Giới hạn chiều rộng tối đa
    );

    if (picked == null) return; // User bấm huỷ

    final file = File(picked.path);

    setState(() {
      _pickedImageFile = file; // Hiện preview ngay lập tức
      _isUploading     = true; // Hiện loading indicator
    });

    try {
      // 2. Upload lên Cloudinary
      final url = await CloudinaryService.uploadImage(file);

      // 3. Lưu URL trả về
      setState(() {
        _imageUrl    = url;
        _isUploading = false;
      });

      _showSuccess('Tải ảnh lên thành công!');
    } catch (e) {
      setState(() {
        _isUploading     = false;
        _pickedImageFile = null; // Reset preview nếu upload thất bại
      });
      _showError('Tải ảnh thất bại: ${e.toString()}');
    }
  }

  /// Xoá ảnh đã chọn
  void _removeImage() {
    setState(() {
      _pickedImageFile = null;
      _imageUrl        = '';
    });
  }

  // ── Instructions ─────────────────────────────────────────────────────────

  void _addStep() =>
      setState(() => _instructionCtrls.add(TextEditingController()));

  void _removeStep(int index) {
    if (_instructionCtrls.length <= 1) return;
    setState(() {
      _instructionCtrls[index].dispose();
      _instructionCtrls.removeAt(index);
    });
  }

  // ── Ingredients ──────────────────────────────────────────────────────────

  void _addIngredient() =>
      setState(() => _ingredientCtrls.add(_IngredientControllers.empty()));

  void _removeIngredient(int index) {
    if (_ingredientCtrls.length <= 1) return;
    setState(() {
      _ingredientCtrls[index].dispose();
      _ingredientCtrls.removeAt(index);
    });
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  void _handleSave() {
    // Validate form (tên, dinh dưỡng, thời gian...)
    if (!_formKey.currentState!.validate()) return;

    // Kiểm tra đang upload thì chưa cho lưu
    if (_isUploading) {
      _showError('Vui lòng chờ ảnh tải xong');
      return;
    }

    // Lọc bỏ bước hướng dẫn rỗng
    final instructions = _instructionCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (instructions.isEmpty) {
      _showError('Vui lòng nhập ít nhất 1 bước hướng dẫn');
      return;
    }

    // Lọc bỏ ingredient rỗng
    final ingredients = _ingredientCtrls
        .where((c) => c.nameCtrl.text.trim().isNotEmpty)
        .map((c) => IngredientItem(
      id:       _uuid.v4(),
      name:     c.nameCtrl.text.trim(),
      amount:   double.tryParse(c.amountCtrl.text) ?? 0,
      unit:     c.unitCtrl.text.trim(),
      category: IngredientCategoryX.fromValue(c.categoryValue),
    ))
        .toList();

    final recipe = RecipeModel(
      id:           widget.recipe?.id ?? '',
      name:         _nameCtrl.text.trim(),
      mealType:     _mealType,
      nutrition:    RecipeNutrition(
        calories: double.tryParse(_caloriesCtrl.text) ?? 0,
        protein:  double.tryParse(_proteinCtrl.text)  ?? 0,
        carbs:    double.tryParse(_carbsCtrl.text)    ?? 0,
        fat:      double.tryParse(_fatCtrl.text)      ?? 0,
      ),
      prepTimeMin:  int.tryParse(_prepTimeCtrl.text) ?? 0,
      instructions: instructions,
      flags:        RecipeFlags(
        isVegan:      _isVegan,
        isVegetarian: _isVegetarian,
      ),
      ingredients:  ingredients,
      imageUrl:     _imageUrl, // URL từ Cloudinary (hoặc rỗng nếu không có ảnh)
    );

    widget.onSave(recipe);
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
    final isEdit = widget.recipe != null;

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
                      // ── Tên món ──────────────────────────────────────────
                      _sectionLabel('Tên món ăn'),
                      _StableTextField(
                        controller: _nameCtrl,
                        hint: 'VD: Cơm gà xối mỡ',
                        validator: (v) =>
                        v!.isEmpty ? 'Vui lòng nhập tên' : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Bữa ăn ───────────────────────────────────────────
                      _sectionLabel('Bữa ăn (Meal Type)'),
                      _buildMealTypePicker(),
                      const SizedBox(height: 16),

                      // ── Dinh dưỡng ───────────────────────────────────────
                      _sectionLabel('Dinh dưỡng'),
                      Row(
                        children: [
                          Expanded(child: _StableMiniNumberField(
                              controller: _caloriesCtrl, label: 'Calo (kcal)')),
                          const SizedBox(width: 8),
                          Expanded(child: _StableMiniNumberField(
                              controller: _proteinCtrl, label: 'Protein (g)')),
                          const SizedBox(width: 8),
                          Expanded(child: _StableMiniNumberField(
                              controller: _carbsCtrl, label: 'Carbs (g)')),
                          const SizedBox(width: 8),
                          Expanded(child: _StableMiniNumberField(
                              controller: _fatCtrl, label: 'Fat (g)')),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Thời gian ────────────────────────────────────────
                      _sectionLabel('Thời gian chuẩn bị (phút)'),
                      _StableTextField(
                        controller: _prepTimeCtrl,
                        hint: '30',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) =>
                        v!.isEmpty ? 'Nhập thời gian' : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Hướng dẫn ────────────────────────────────────────
                      _sectionLabel('Hướng dẫn nấu'),
                      _buildInstructionsSection(),
                      const SizedBox(height: 16),

                      // ── Nguyên liệu ──────────────────────────────────────
                      _sectionLabel('Nguyên liệu'),
                      _buildIngredientsSection(),
                      const SizedBox(height: 16),

                      // ── Flags ────────────────────────────────────────────
                      _sectionLabel('Phân loại'),
                      _buildFlags(),
                      const SizedBox(height: 16),

                      // ── Ảnh món ăn (IMAGE PICKER + CLOUDINARY) ───────────
                      _sectionLabel('Ảnh món ăn'),
                      _buildImagePicker(),
                      const SizedBox(height: 24),

                      // ── Nút lưu ──────────────────────────────────────────
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

  // ── Widget: Image Picker ─────────────────────────────────────────────────
  Widget _buildImagePicker() {
    // Trạng thái 1: Đang upload → hiện loading
    if (_isUploading) {
      return Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Đang tải ảnh lên Cloudinary...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Trạng thái 2: Đã có ảnh (preview + nút xoá)
    if (_pickedImageFile != null || _imageUrl.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview ảnh
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _pickedImageFile != null
            // Ảnh vừa chọn từ máy (chưa upload xong - không nên xảy ra vì
            // chúng ta set _pickedImageFile trước khi upload)
                ? Image.file(
              _pickedImageFile!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            )
            // Ảnh đã upload (load từ Cloudinary URL)
                : Image.network(
              _imageUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 180,
                  color: Colors.white,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Colors.white,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.black26, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Badge URL + 2 nút hành động
          Row(
            children: [
              // Badge trạng thái
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Đã upload thành công',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Nút đổi ảnh
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
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Nút xoá ảnh
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
                      color: Color(0xFFE53935),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Trạng thái 3: Chưa có ảnh → nút chọn ảnh
    return GestureDetector(
      onTap: _pickAndUploadImage,
      child: Container(
        width: double.infinity,
        height: 120,
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
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn ảnh từ thư viện',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Ảnh sẽ được upload lên Cloudinary',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black.withOpacity(0.4),
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
            isEdit ? '✏️  Sửa món ăn' : '➕  Thêm món ăn mới',
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

  Widget _buildMealTypePicker() {
    return Wrap(
      spacing: 8,
      children: _mealTypes.map((type) {
        final isSelected = _mealType == type;
        final label = {
          'Breakfast': '🌅 Sáng',
          'Lunch':     '☀️ Trưa',
          'Dinner':    '🌙 Tối',
          'Snack':     '🍎 Xế',
        }[type] ?? type;

        return GestureDetector(
          onTap: () => setState(() => _mealType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _buildInstructionsSection() {
    return Column(
      children: [
        ...List.generate(_instructionCtrls.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 10, right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('step_$i'),
                    controller: _instructionCtrls[i],
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                    enableIMEPersonalizedLearning: true,
                    decoration:
                    _inputDecoration(hint: 'Nhập bước \${i + 1}...'),
                  ),
                ),
                if (_instructionCtrls.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent, size: 20),
                    onPressed: () => _removeStep(i),
                  ),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: _addStep,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  style: BorderStyle.solid),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 6),
                Text(
                  'Thêm bước',
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

  Widget _buildIngredientsSection() {
    // Danh sách tất cả category để hiện trong dropdown
    const categories = IngredientCategory.values;

    return Column(
      children: [
        // Header — thêm cột Loại
        const Row(
          children: [
            Expanded(flex: 3, child: _ColHeader(label: 'Tên nguyên liệu')),
            SizedBox(width: 6),
            Expanded(flex: 2, child: _ColHeader(label: 'Số lượng')),
            SizedBox(width: 6),
            Expanded(flex: 2, child: _ColHeader(label: 'Đơn vị')),
            SizedBox(width: 6),
            Expanded(flex: 3, child: _ColHeader(label: 'Loại')),
            SizedBox(width: 36),
          ],
        ),
        const SizedBox(height: 6),
        ...List.generate(_ingredientCtrls.length, (i) {
          final ing = _ingredientCtrls[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Tên nguyên liệu
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    key: ValueKey('ing_name_\$i'),
                    controller: ing.nameCtrl,
                    style: const TextStyle(fontSize: 13),
                    enableIMEPersonalizedLearning: true,
                    decoration: _inputDecoration(hint: 'VD: Gạo'),
                  ),
                ),
                const SizedBox(width: 6),
                // Số lượng
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: ValueKey('ing_amount_\$i'),
                    controller: ing.amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                    ],
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDecoration(hint: '100'),
                  ),
                ),
                const SizedBox(width: 6),
                // Đơn vị
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: ValueKey('ing_unit_\$i'),
                    controller: ing.unitCtrl,
                    style: const TextStyle(fontSize: 13),
                    enableIMEPersonalizedLearning: true,
                    decoration: _inputDecoration(hint: 'g / ml'),
                  ),
                ),
                const SizedBox(width: 6),
                // ✅ Dropdown chọn loại nguyên liệu
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: ing.categoryValue,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 16),
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500),
                        items: categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat.value,
                            child: Text(
                              cat.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => ing.categoryValue = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                // Nút xóa
                if (_ingredientCtrls.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent, size: 20),
                    onPressed: () => _removeIngredient(i),
                  )
                else
                  const SizedBox(width: 36),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: _addIngredient,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline,
                    color: Color(0xFFF59E0B), size: 18),
                SizedBox(width: 6),
                Text(
                  'Thêm nguyên liệu',
                  style: TextStyle(
                    color: Color(0xFFB45309),
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

  Widget _buildFlags() {
    return Row(
      children: [
        _FlagChip(
          label: '🌿 Vegan',
          value: _isVegan,
          onChanged: (v) => setState(() => _isVegan = v),
        ),
        const SizedBox(width: 12),
        _FlagChip(
          label: '🥗 Chay',
          value: _isVegetarian,
          onChanged: (v) => setState(() => _isVegetarian = v),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isEdit) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        // Disable nút khi đang upload
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
          isEdit ? 'Cập nhật món ăn' : 'Thêm món ăn',
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
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2)),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _StableTextField — ĐỔI thành StatelessWidget, BỎ FocusNode
// FocusNode + addListener → rebuild loop → IME tiếng Việt bị reset
// ════════════════════════════════════════════════════════════════════════════
class _StableTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const _StableTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      enableIMEPersonalizedLearning: true,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _StableMiniNumberField — ĐỔI thành StatelessWidget, BỎ FocusNode
// ════════════════════════════════════════════════════════════════════════════
class _StableMiniNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _StableMiniNumberField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.black.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          enableIMEPersonalizedLearning: true,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
          ],
          validator: (v) => v!.isEmpty ? '?' : null,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2)),
          ),
        ),
      ],
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

// ── _FlagChip ─────────────────────────────────────────────────────────────────
class _FlagChip extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  const _FlagChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF16A34A).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value
                ? const Color(0xFF16A34A)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: value ? const Color(0xFF16A34A) : Colors.black54,
          ),
        ),
      ),
    );
  }
}

// ── _IngredientControllers ────────────────────────────────────────────────────
class _IngredientControllers {
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final TextEditingController unitCtrl;
  // category không dùng TextEditingController mà dùng String value
  String categoryValue;

  _IngredientControllers({
    required this.nameCtrl,
    required this.amountCtrl,
    required this.unitCtrl,
    this.categoryValue = 'other',
  });

  factory _IngredientControllers.empty() => _IngredientControllers(
    nameCtrl:      TextEditingController(),
    amountCtrl:    TextEditingController(),
    unitCtrl:      TextEditingController(),
    categoryValue: 'other',
  );

  factory _IngredientControllers.fromIngredient(IngredientItem ing) =>
      _IngredientControllers(
        nameCtrl:      TextEditingController(text: ing.name),
        amountCtrl:    TextEditingController(text: ing.amount.toString()),
        unitCtrl:      TextEditingController(text: ing.unit),
        categoryValue: ing.category.value,
      );

  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
    unitCtrl.dispose();
  }
}
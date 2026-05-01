// lib/features/admin/widgets/recipe_form_dialog.dart
//
// Mô tả: Popup Dialog để Thêm hoặc Sửa recipe.
// Khi recipe == null → chế độ Thêm mới.
// Khi recipe != null → chế độ Sửa (điền sẵn dữ liệu).
//
// Gọi từ: AdminDashboardScreen khi bấm "Add New Recipe" hoặc nút sửa.
//
// Cách dùng:
//   showDialog(
//     context: context,
//     builder: (_) => RecipeFormDialog(
//       recipe: null,            // null = thêm mới
//       onSave: (recipe) { ... },
//     ),
//   );

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/recipe_model.dart';
import '../../../core/constants/app_colors.dart';

class RecipeFormDialog extends StatefulWidget {
  final RecipeModel? recipe;  // null = thêm mới, có giá trị = sửa
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
  final _uuid = const Uuid();

  // ── Controllers ──────────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _prepTimeCtrl;
  late final TextEditingController _caloriesCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  late final TextEditingController _imageUrlCtrl;

  // ── State ────────────────────────────────────────────────────────────────
  String _mealType = 'Breakfast';
  bool _isVegan = false;
  bool _isVegetarian = false;

  // Instructions: mỗi phần tử là 1 bước, mặc định 4 bước rỗng
  late List<TextEditingController> _instructionCtrls;

  // Ingredients: list các map controller
  late List<_IngredientControllers> _ingredientCtrls;

  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;

    // Điền sẵn dữ liệu nếu đang sửa
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
    _imageUrlCtrl = TextEditingController(text: r?.imageUrl ?? '');

    _mealType     = r?.mealType ?? 'Breakfast';
    _isVegan      = r?.flags.isVegan ?? false;
    _isVegetarian = r?.flags.isVegetarian ?? false;

    // Instructions: dùng dữ liệu cũ nếu có, không thì 4 bước rỗng
    final existingSteps = r?.instructions ?? [];
    final steps = existingSteps.isNotEmpty
        ? existingSteps
        : ['', '', '', '']; // 4 bước mặc định
    _instructionCtrls =
        steps.map((s) => TextEditingController(text: s)).toList();

    // Ingredients
    final existingIngredients = r?.ingredients ?? [];
    _ingredientCtrls = existingIngredients.isNotEmpty
        ? existingIngredients
        .map((ing) => _IngredientControllers.fromIngredient(ing))
        .toList()
        : [_IngredientControllers.empty()]; // 1 ingredient rỗng mặc định
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _prepTimeCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _imageUrlCtrl.dispose();
    for (final c in _instructionCtrls) c.dispose();
    for (final c in _ingredientCtrls) c.dispose();
    super.dispose();
  }

  // ── Thêm / xóa bước instructions ─────────────────────────────────────────
  void _addStep() {
    setState(() => _instructionCtrls.add(TextEditingController()));
  }

  void _removeStep(int index) {
    if (_instructionCtrls.length <= 1) return; // tối thiểu 1 bước
    setState(() {
      _instructionCtrls[index].dispose();
      _instructionCtrls.removeAt(index);
    });
  }

  // ── Thêm / xóa ingredient ────────────────────────────────────────────────
  void _addIngredient() {
    setState(() => _ingredientCtrls.add(_IngredientControllers.empty()));
  }

  void _removeIngredient(int index) {
    if (_ingredientCtrls.length <= 1) return;
    setState(() {
      _ingredientCtrls[index].dispose();
      _ingredientCtrls.removeAt(index);
    });
  }

  // ── Lưu form ─────────────────────────────────────────────────────────────
  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    // Build instructions (lọc bỏ bước rỗng)
    final instructions = _instructionCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (instructions.isEmpty) {
      _showError('Vui lòng nhập ít nhất 1 bước hướng dẫn');
      return;
    }

    // Build ingredients (lọc bỏ dòng rỗng)
    final ingredients = _ingredientCtrls
        .where((c) => c.nameCtrl.text.trim().isNotEmpty)
        .map((c) => IngredientItem(
      id:     _uuid.v4(),
      name:   c.nameCtrl.text.trim(),
      amount: double.tryParse(c.amountCtrl.text) ?? 0,
      unit:   c.unitCtrl.text.trim(),
    ))
        .toList();

    final recipe = RecipeModel(
      id:          widget.recipe?.id ?? '',
      name:        _nameCtrl.text.trim(),
      mealType:    _mealType,
      nutrition:   RecipeNutrition(
        calories: double.tryParse(_caloriesCtrl.text) ?? 0,
        protein:  double.tryParse(_proteinCtrl.text)  ?? 0,
        carbs:    double.tryParse(_carbsCtrl.text)    ?? 0,
        fat:      double.tryParse(_fatCtrl.text)      ?? 0,
      ),
      prepTimeMin: int.tryParse(_prepTimeCtrl.text) ?? 0,
      instructions: instructions,
      flags:       RecipeFlags(
        isVegan:      _isVegan,
        isVegetarian: _isVegetarian,
      ),
      ingredients: ingredients,
      imageUrl:    _imageUrlCtrl.text.trim(),
    );

    widget.onSave(recipe);
    Navigator.of(context).pop();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
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
            // ── Header ──────────────────────────────────────────────────
            _buildHeader(isEdit),

            // ── Scrollable form ─────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên món ăn
                      _sectionLabel('Tên món ăn'),
                      _textField(
                        controller: _nameCtrl,
                        hint: 'VD: Cơm gà xối mỡ',
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                      ),
                      const SizedBox(height: 16),

                      // Bữa ăn
                      _sectionLabel('Bữa ăn (Meal Type)'),
                      _buildMealTypePicker(),
                      const SizedBox(height: 16),

                      // Dinh dưỡng
                      _sectionLabel('Dinh dưỡng'),
                      _buildNutritionRow(),
                      const SizedBox(height: 16),

                      // Thời gian chuẩn bị
                      _sectionLabel('Thời gian chuẩn bị (phút)'),
                      _textField(
                        controller: _prepTimeCtrl,
                        hint: '30',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) => v!.isEmpty ? 'Nhập thời gian' : null,
                      ),
                      const SizedBox(height: 16),

                      // Hướng dẫn nấu
                      _sectionLabel('Hướng dẫn nấu'),
                      _buildInstructionsSection(),
                      const SizedBox(height: 16),

                      // Nguyên liệu
                      _sectionLabel('Nguyên liệu'),
                      _buildIngredientsSection(),
                      const SizedBox(height: 16),

                      // Flags
                      _sectionLabel('Phân loại'),
                      _buildFlags(),
                      const SizedBox(height: 16),

                      // Image URL
                      _sectionLabel('Link ảnh (Cloudinary URL)'),
                      _textField(
                        controller: _imageUrlCtrl,
                        hint: 'https://res.cloudinary.com/...',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 24),

                      // Nút lưu
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

  Widget _buildNutritionRow() {
    return Row(
      children: [
        Expanded(child: _miniNumberField(_caloriesCtrl, 'Calo (kcal)')),
        const SizedBox(width: 8),
        Expanded(child: _miniNumberField(_proteinCtrl, 'Protein (g)')),
        const SizedBox(width: 8),
        Expanded(child: _miniNumberField(_carbsCtrl, 'Carbs (g)')),
        const SizedBox(width: 8),
        Expanded(child: _miniNumberField(_fatCtrl, 'Fat (g)')),
      ],
    );
  }

  Widget _miniNumberField(TextEditingController ctrl, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.black.withOpacity(0.5),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          validator: (v) => v!.isEmpty ? '?' : null,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: _inputDecoration(hint: '0'),
        ),
      ],
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
                // Số thứ tự bước
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
                // TextField bước
                Expanded(
                  child: TextFormField(
                    controller: _instructionCtrls[i],
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                    decoration: _inputDecoration(
                        hint: 'Nhập bước ${i + 1}...'),
                  ),
                ),
                // Nút xóa bước (ẩn nếu chỉ còn 1)
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

        // Nút thêm bước
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
    return Column(
      children: [
        // Header row
        const Row(
          children: [
            Expanded(flex: 3, child: _ColHeader(label: 'Tên nguyên liệu')),
            SizedBox(width: 8),
            Expanded(flex: 2, child: _ColHeader(label: 'Số lượng')),
            SizedBox(width: 8),
            Expanded(flex: 2, child: _ColHeader(label: 'Đơn vị')),
            SizedBox(width: 36), // space for delete btn
          ],
        ),
        const SizedBox(height: 6),

        ...List.generate(_ingredientCtrls.length, (i) {
          final ing = _ingredientCtrls[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: ing.nameCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDecoration(hint: 'VD: Gạo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: ing.amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                    ],
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDecoration(hint: '100'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: ing.unitCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDecoration(hint: 'g / ml / cái'),
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

        // Nút thêm nguyên liệu
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
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          isEdit ? 'Cập nhật món ăn' : 'Thêm món ăn',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // Helpers
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

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: _inputDecoration(hint: hint),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: Colors.black.withOpacity(0.3), fontSize: 13),
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

// ── Helper widget: tiêu đề cột ───────────────────────────────────────────────
class _ColHeader extends StatelessWidget {
  final String label;
  const _ColHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.45)));
  }
}

// ── Helper widget: toggle flag (Vegan / Chay) ────────────────────────────────
class _FlagChip extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;
  const _FlagChip(
      {required this.label,
        required this.value,
        required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

// ── Helper class: nhóm controllers cho 1 nguyên liệu ────────────────────────
class _IngredientControllers {
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  final TextEditingController unitCtrl;

  _IngredientControllers({
    required this.nameCtrl,
    required this.amountCtrl,
    required this.unitCtrl,
  });

  factory _IngredientControllers.empty() => _IngredientControllers(
    nameCtrl:   TextEditingController(),
    amountCtrl: TextEditingController(),
    unitCtrl:   TextEditingController(),
  );

  factory _IngredientControllers.fromIngredient(IngredientItem ing) =>
      _IngredientControllers(
        nameCtrl:   TextEditingController(text: ing.name),
        amountCtrl: TextEditingController(text: ing.amount.toString()),
        unitCtrl:   TextEditingController(text: ing.unit),
      );

  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
    unitCtrl.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/profile/bloc/profile_bloc.dart';

/// Edit-profile page — lets the user change display name, avatar,
/// market focus, and risk style.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  static const String routeName = '/edit-profile';

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // ── Colour constants ───────────────────────────────────────────────────────
  static const Color _navy = Color(0xFF0a1628);
  static const Color _surface = Color(0xFF0f2040);
  static const Color _neonGreen = Color(0xFF00f5a0);
  static const Color _textWhite = Color(0xFFe8f4f8);
  static const Color _textSecondary = Color(0xFFa8c4e0);
  static const Color _inputBorder = Color(0xFF1e3050);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;

  String? _selectedAvatarId;
  String? _selectedMarketFocus;
  String? _selectedRiskStyle;

  bool _isSaving = false;

  static const List<String> _avatarIds = [
    'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8',
  ];

  static const List<_LabeledOption> _marketFocusOptions = [
    _LabeledOption(id: 'crypto', label: 'Crypto'),
    _LabeledOption(id: 'fx', label: 'Forex'),
    _LabeledOption(id: 'stocks', label: 'Stocks'),
    _LabeledOption(id: 'mixed', label: 'Mixed'),
  ];

  static const List<_LabeledOption> _riskStyleOptions = [
    _LabeledOption(id: 'calm', label: 'Calm (เสี่ยงต่ำ)'),
    _LabeledOption(id: 'balanced', label: 'Balanced (สมดุล)'),
    _LabeledOption(id: 'bold', label: 'Bold (เสี่ยงสูง)'),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill from current ProfileBloc state if available.
    final state = context.read<ProfileBloc>().state;
    final user = state is ProfileLoaded ? state.user : null;
    _displayNameController = TextEditingController(
      text: user?.displayName ?? '',
    );
    _selectedAvatarId = user?.avatarId;
    _selectedMarketFocus = user?.marketFocus;
    _selectedRiskStyle = user?.riskStyle;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(
            displayName: _displayNameController.text.trim(),
            avatarId: _selectedAvatarId,
            marketFocus: _selectedMarketFocus,
            riskStyle: _selectedRiskStyle,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        title: const Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(
            color: _textWhite,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textWhite, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildLabel('ชื่อที่แสดง'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _displayNameController,
              hint: 'กรอกชื่อที่แสดง',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อ';
                }
                if (value.trim().length < 2) return 'ต้องมีอย่างน้อย 2 ตัวอักษร';
                if (value.trim().length > 30) return 'ไม่เกิน 30 ตัวอักษร';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('Avatar'),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedAvatarId,
              hint: 'เลือก Avatar',
              items: _avatarIds
                  .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedAvatarId = v),
            ),
            const SizedBox(height: 20),
            _buildLabel('Market Focus'),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedMarketFocus,
              hint: 'เลือกตลาดที่สนใจ',
              items: _marketFocusOptions
                  .map((o) => DropdownMenuItem(
                        value: o.id,
                        child: Text(o.label),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedMarketFocus = v),
            ),
            const SizedBox(height: 20),
            _buildLabel('Risk Style'),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedRiskStyle,
              hint: 'เลือกสไตล์การเทรด',
              items: _riskStyleOptions
                  .map((o) => DropdownMenuItem(
                        value: o.id,
                        child: Text(o.label),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRiskStyle = v),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _neonGreen,
                  foregroundColor: _navy,
                  disabledBackgroundColor: _neonGreen.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _navy,
                        ),
                      )
                    : const Text(
                        'บันทึก',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: _textWhite, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF3d5a78)),
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _neonGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: _surface,
          hint: Text(
            hint,
            style: const TextStyle(color: Color(0xFF3d5a78), fontSize: 15),
          ),
          style: const TextStyle(color: _textWhite, fontSize: 15),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _LabeledOption {
  const _LabeledOption({required this.id, required this.label});

  final String id;
  final String label;
}

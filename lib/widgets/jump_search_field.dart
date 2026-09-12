import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class JumpSearchField extends StatefulWidget {
  const JumpSearchField({
    super.key,
    this.hintText = 'Search',
    required this.onSearch,
  });

  final String hintText;
  final ValueChanged<String> onSearch;

  @override
  State<JumpSearchField> createState() => _JumpSearchFieldState();
}

class _JumpSearchFieldState extends State<JumpSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open([String? value]) {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSearch(value ?? _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onTap: () => _open(),
      onSubmitted: _open,
      onChanged: (value) {
        setState(() {});
        if (value.trim().isNotEmpty) _open(value);
      },
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              ),
        filled: true,
        fillColor: AppColors.surfaceHigh,
      ),
    );
  }
}

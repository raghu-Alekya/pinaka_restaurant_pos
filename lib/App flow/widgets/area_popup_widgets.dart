import 'package:flutter/material.dart';

class AreaOptionsPopup extends StatelessWidget {
  final String areaName;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const AreaOptionsPopup({
    super.key,
    required this.areaName,
    required this.onClose,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withAlpha(80),
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFD),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    Image.asset('assets/info.png', width: 70, height: 70),
                    const SizedBox(height: 14),
                    const Text(
                      'Area/Zone Info!',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1D)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Modify Area/Zone name information as needed or delete it permanently.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFA19999),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFD6464)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: onDelete,
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                  color: Color(0xFFFD6464),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF86157),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: onEdit,
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDA4A38),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class EditAreaPopup extends StatelessWidget {
  final TextEditingController controller;
  final String oldName;
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onCancel;
  final Future<void> Function(String newName) onSubmit;

  const EditAreaPopup({
    super.key,
    required this.controller,
    required this.oldName,
    required this.onCancel,
    required this.onSubmit,
    this.errorMessage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard
      child: Container(
        color: Colors.black.withAlpha(80),
        child: Center(
          child: AnimatedPadding(
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: SingleChildScrollView(
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Edit Area/Zone name',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Make changes to the Area/Zone name below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Area/Zone name',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4C5F7D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFECEBEB)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          style: const TextStyle(fontSize: 14),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(
                            hintText: 'Enter Area/Zone name',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onCancel,
                            child: Container(
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFF4C5F7D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final newName = controller.text.trim();
                              if (newName.isNotEmpty && newName != oldName) {
                                await onSubmit(newName);
                              }
                            },
                            child: Container(
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFD6464),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Text(
                                'Update',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

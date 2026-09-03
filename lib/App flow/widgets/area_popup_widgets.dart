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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFFFD6464);

    return GestureDetector(
      onTap: onClose,
      child: Material(
        color: Colors.black45,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 520,
              padding: const EdgeInsets.fromLTRB(34, 30, 30, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                      isDark
                          ? const [Color(0xFF46333A), Color(0xFF202433)]
                          : const [Color(0xFFEFCDCD), Colors.white],
                ),
                borderRadius: BorderRadius.circular(16),
                border: const Border(
                  top: BorderSide(color: primaryColor, width: 4),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x334C5F7D),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF2A2F3D) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryColor),
                        ),
                        child: Image.asset(
                          'assets/info.png',
                          width: 38,
                          height: 38,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(width: 18),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Area/Zone Info!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF373535),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              'Modify "$areaName" information as needed or delete it permanently.',
                              style: TextStyle(
                                color:
                                    isDark
                                        ? Colors.white70
                                        : const Color(0xFF656161),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Padding(
                    padding: const EdgeInsets.only(left: 70),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 150,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: onDelete,
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  isDark
                                      ? const Color(0xFF2A2F3D)
                                      : const Color(0xFFF6F6F6),
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        SizedBox(
                          width: 150,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: onEdit,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewInsets = MediaQuery.of(context).viewInsets;

    const primaryColor = Color(0xFFFD6464);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Material(
        color: Colors.black45,
        child: Center(
          child: AnimatedPadding(
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: SingleChildScrollView(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 404,
                  height: 310,
                  padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors:
                          isDark
                              ? const [Color(0xFF46333A), Color(0xFF202433)]
                              : const [Color(0xFFEFCDCD), Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: const Border(
                      top: BorderSide(color: primaryColor, width: 4),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x334C5F7D),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? const Color(0xFF2A2F3D)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: primaryColor),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 32,
                              color: primaryColor,
                            ),
                          ),

                          const SizedBox(width: 18),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Area/Zone Name',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF373535),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Text(
                                  'Make changes to the Area/Zone name below.',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? Colors.white70
                                            : const Color(0xFF656161),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.only(left: 70),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Area/Zone Name',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF4C5F7D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A2F3D)
                                    : Colors.white,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : const Color(0xFFECEBEB),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                controller: controller,
                                autofocus: true,
                                maxLines: 1,
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter Area/Zone name',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.grey,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),

                            if (errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            Row(
                              children: [
                                SizedBox(
                                  width: 130,
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: isLoading ? null : onCancel,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          isDark
                                              ? const Color(0xFF2A2F3D)
                                              : const Color(0xFFF6F6F6),
                                      side: BorderSide(
                                        color: theme.dividerColor,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? Colors.white
                                                : const Color(0xFF373535),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 14),

                                SizedBox(
                                  width: 130,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed:
                                        isLoading
                                            ? null
                                            : () async {
                                              final newName =
                                                  controller.text.trim();

                                              if (newName.isNotEmpty &&
                                                  newName != oldName) {
                                                await onSubmit(newName);
                                              }
                                            },
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child:
                                        isLoading
                                            ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Text(
                                              'Update',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

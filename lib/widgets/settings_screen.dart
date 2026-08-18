import 'package:flutter/material.dart';

class KitchenDisplaySettingsScreen extends StatefulWidget {
  const KitchenDisplaySettingsScreen({super.key});

  @override
  State<KitchenDisplaySettingsScreen> createState() =>
      _KitchenDisplaySettingsScreenState();
}

class _KitchenDisplaySettingsScreenState
    extends State<KitchenDisplaySettingsScreen> {
  final TextEditingController serverIpController = TextEditingController();

  // Order & KOT
  bool dineIn = true;
  bool takeaway = true;
  bool onlineOrders = true;
  String releaseKotOn = 'Prepare';
  bool changeKotDoubleClick = false;
  bool updateBakerStatus = false;
  bool removeKot = true;

  // Item & Combo
  bool showMasterItem = true;
  bool showAllSubItems = false;
  String displayItemGroup = 'Item with Addons';

  // KDS Display
  String displayConfiguration = 'Both';
  String categorySection = 'One Column';
  String displayKdsOn = 'Masonry View';
  bool askForDeviceNo = false;

  // Notification
  bool notificationSound = true;
  String soundVolume = 'MEDIUM';

  // Language
  String selectedLanguage = 'Default Language';

  Color get orangeColor => const Color(0xFFFF684F);
  Color get greenColor => const Color(0xFF35A95A);
  Color get pinkColor => const Color(0xFFFF5275);

  @override
  void dispose() {
    serverIpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFF008EFF),
              width: 2.5,
            ),
          ),
          child: Column(
            children: [
              _buildTitleBar(),

              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(10),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      14,
                      12,
                      14,
                      25,
                    ),
                    child: Column(
                      children: [
                        _buildActionBar(),
                        const SizedBox(height: 10),

                        _buildServerSection(),
                        const SizedBox(height: 10),

                        _buildOrderKotSection(),
                        const SizedBox(height: 10),

                        _buildItemComboSection(),
                        const SizedBox(height: 10),

                        _buildKdsDisplaySection(),
                        const SizedBox(height: 10),

                        _buildNotificationSection(),
                        const SizedBox(height: 10),

                        _buildLanguageSection(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TITLE BAR
  // ==========================================================

  Widget _buildTitleBar() {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF008EFF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.close,
              size: 21,
              color: Color(0xFF008EFF),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTION BAR
  // ==========================================================

  Widget _buildActionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FC),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _smallButton(
            'Cancel',
            width: 110,
            background: Colors.white,
            borderColor: const Color(0xFFC7CEDB),
            textColor: const Color(0xFF555555),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 10),
          _smallButton(
            'Save Changes',
            width: 125,
            background: const Color(0xFFFF5C61),
            borderColor: const Color(0xFFFF5C61),
            textColor: Colors.white,
            onPressed: _saveSettings,
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Settings saved successfully',
          style: TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  // ==========================================================
  // 1. SERVER & CONNECTION
  // ==========================================================

  Widget _buildServerSection() {
    return _section(
      number: '1.',
      title: 'Server & Connection',
      color: const Color(0xFFB34CD5),
      icon: Icons.storage_outlined,
      child: Row(
        children: [
          _label(
            'Pinaka server IP',
            width: 210,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 230,
            height: 34,
            child: TextField(
              controller: serverIpController,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF303030),
              ),
              decoration: InputDecoration(
                hintText: 'Enter your IP here',
                hintStyle: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF777777),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: Color(0xFFD2D8E5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: Color(0xFFD2D8E5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: Color(0xFF008EFF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 2. ORDER & KOT
  // ==========================================================

  Widget _buildOrderKotSection() {
    return _section(
      number: '2.',
      title: 'Order & KOT Settings',
      color: const Color(0xFF255AC9),
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          _settingRow(
            label: "View KOT's of Orders",
            child: Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _checkOption(
                  'Dine-In',
                  dineIn,
                      (v) => setState(() => dineIn = v),
                ),
                _checkOption(
                  'Takeaway',
                  takeaway,
                      (v) => setState(() => takeaway = v),
                ),
                _checkOption(
                  'Online Orders',
                  onlineOrders,
                      (v) => setState(() => onlineOrders = v),
                ),
              ],
            ),
          ),
          _settingRow(
            label: 'Release KOT on',
            child: Row(
              children: [
                _radioOption(
                  'Prepare',
                  releaseKotOn == 'Prepare',
                      () => setState(() => releaseKotOn = 'Prepare'),
                ),
                const SizedBox(width: 28),
                _radioOption(
                  'Dispatch',
                  releaseKotOn == 'Dispatch',
                      () => setState(() => releaseKotOn = 'Dispatch'),
                ),
              ],
            ),
          ),
          _settingRow(
            label: 'Change KOT status on double click',
            child: _switch(
              changeKotDoubleClick,
                  (v) => setState(() => changeKotDoubleClick = v),
            ),
          ),
          _settingRow(
            label: 'Update status of baker',
            child: _switch(
              updateBakerStatus,
                  (v) => setState(() => updateBakerStatus = v),
            ),
          ),
          _settingRow(
            label: 'Remove KOT if Food Ready / Dispatch\nfrom POS, KDS etc.',
            child: _switch(
              removeKot,
                  (v) => setState(() => removeKot = v),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 3. ITEM & COMBO
  // ==========================================================

  Widget _buildItemComboSection() {
    return _section(
      number: '3.',
      title: 'Item & Combo Settings',
      color: greenColor,
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          _settingRow(
            label: 'Combo Item Display',
            child: Wrap(
              spacing: 25,
              runSpacing: 8,
              children: [
                _checkOption(
                  'Show master item in Combo',
                  showMasterItem,
                      (v) => setState(() => showMasterItem = v),
                  activeColor: greenColor,
                ),
                _checkOption(
                  'Show all sub item in Combo',
                  showAllSubItems,
                      (v) => setState(() => showAllSubItems = v),
                  activeColor: greenColor,
                ),
              ],
            ),
          ),
          _settingRow(
            label: 'Display Item Group',
            child: Wrap(
              spacing: 25,
              runSpacing: 8,
              children: [
                _radioOption(
                  'Item Wise',
                  displayItemGroup == 'Item Wise',
                      () => setState(() => displayItemGroup = 'Item Wise'),
                  activeColor: greenColor,
                ),
                _radioOption(
                  'Item with Addons',
                  displayItemGroup == 'Item with Addons',
                      () => setState(
                        () => displayItemGroup = 'Item with Addons',
                  ),
                  activeColor: greenColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 4. KDS DISPLAY
  // ==========================================================

  Widget _buildKdsDisplaySection() {
    return _section(
      number: '4.',
      title: 'KDS Display Settings',
      color: orangeColor,
      icon: Icons.desktop_windows_outlined,
      child: Column(
        children: [
          _settingRow(
            label: 'Display Configuration',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _choiceButton(
                  'Both',
                  displayConfiguration == 'Both',
                      () => setState(
                        () => displayConfiguration = 'Both',
                  ),
                ),
                _choiceButton(
                  'KOT',
                  displayConfiguration == 'KOT',
                      () => setState(
                        () => displayConfiguration = 'KOT',
                  ),
                ),
                _choiceButton(
                  'Category',
                  displayConfiguration == 'Category',
                      () => setState(
                        () => displayConfiguration = 'Category',
                  ),
                ),
              ],
            ),
          ),
          _settingRow(
            label: 'Show Category Section On',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _choiceButton(
                  'One Column',
                  categorySection == 'One Column',
                      () => setState(
                        () => categorySection = 'One Column',
                  ),
                ),
                _choiceButton(
                  'Two Column',
                  categorySection == 'Two Column',
                      () => setState(
                        () => categorySection = 'Two Column',
                  ),
                ),
              ],
            ),
          ),
          _settingRow(
            label: 'Display KDS On',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _choiceButton(
                  'Normal View',
                  displayKdsOn == 'Normal View',
                      () => setState(
                        () => displayKdsOn = 'Normal View',
                  ),
                ),
                _choiceButton(
                  'Masonry View',
                  displayKdsOn == 'Masonry View',
                      () => setState(
                        () => displayKdsOn = 'Masonry View',
                  ),
                ),
              ],
            ),
          ),
          _settingRow(
            label: 'Ask for Device No.',
            child: _switch(
              askForDeviceNo,
                  (v) => setState(() => askForDeviceNo = v),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 5. NOTIFICATION
  // ==========================================================

  Widget _buildNotificationSection() {
    return _section(
      number: '5.',
      title: 'Notification & Sound',
      color: pinkColor,
      icon: Icons.notifications_none,
      child: Column(
        children: [
          _settingRow(
            label: 'Notification Sound',
            child: _switch(
              notificationSound,
                  (v) => setState(() => notificationSound = v),
              activeColor: pinkColor,
            ),
          ),
          _settingRow(
            label: 'Sound Volume',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _choiceButton(
                  'OFF',
                  soundVolume == 'OFF',
                      () => setState(() => soundVolume = 'OFF'),
                  activeColor: pinkColor,
                ),
                _choiceButton(
                  'LOW',
                  soundVolume == 'LOW',
                      () => setState(() => soundVolume = 'LOW'),
                  activeColor: pinkColor,
                ),
                _choiceButton(
                  'MEDIUM',
                  soundVolume == 'MEDIUM',
                      () => setState(() => soundVolume = 'MEDIUM'),
                  activeColor: pinkColor,
                ),
                _choiceButton(
                  'HIGH',
                  soundVolume == 'HIGH',
                      () => setState(() => soundVolume = 'HIGH'),
                  activeColor: pinkColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 6. LANGUAGE
  // ==========================================================

  Widget _buildLanguageSection() {
    return _section(
      number: '6.',
      title: 'Language',
      color: const Color(0xFF5143C7),
      icon: Icons.language,
      child: Row(
        children: [
          _label(
            'Select Language',
            width: 210,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 230,
            height: 34,
            child: DropdownButtonFormField<String>(
              value: selectedLanguage,
              isDense: true,
              icon: const Icon(
                Icons.arrow_drop_down,
                size: 20,
              ),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF444444),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: Color(0xFFD2D8E5),
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Default Language',
                  child: Text(
                    'Default Language',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                DropdownMenuItem(
                  value: 'English',
                  child: Text(
                    'English',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedLanguage = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION
  // ==========================================================

  Widget _section({
    required String number,
    required String title,
    required Color color,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE0E4EC),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: color,
              ),
              const SizedBox(width: 7),
              Text(
                '$number $title',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ==========================================================
  // SETTING ROW
  // ==========================================================

  Widget _settingRow({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 210,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF303030),
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LABEL
  // ==========================================================

  Widget _label(
      String text, {
        double width = 120,
      }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF303030),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ==========================================================
  // CHECKBOX
  // ==========================================================

  Widget _checkOption(
      String text,
      bool value,
      ValueChanged<bool> onChanged, {
        Color activeColor = const Color(0xFF3157C8),
      }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: activeColor,
              materialTapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF444444),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RADIO
  // ==========================================================

  Widget _radioOption(
      String text,
      bool selected,
      VoidCallback onTap, {
        Color activeColor = const Color(0xFF3157C8),
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Radio<bool>(
              value: true,
              groupValue: selected ? true : null,
              onChanged: (_) => onTap(),
              activeColor: activeColor,
              materialTapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF444444),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SWITCH
  // ==========================================================

  Widget _switch(
      bool value,
      ValueChanged<bool> onChanged, {
        Color activeColor = const Color(0xFF376BD2),
      }) {
    return SizedBox(
      width: 42,
      height: 24,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: activeColor,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFFD0D4DC),
        materialTapTargetSize:
        MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ==========================================================
  // CHOICE BUTTON
  // ==========================================================

  Widget _choiceButton(
      String text,
      bool selected,
      VoidCallback onTap, {
        Color activeColor = const Color(0xFFFF684F),
      }) {
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 30,
          constraints: const BoxConstraints(
            minWidth: 75,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFF1ED)
                : Colors.white,
            border: Border.all(
              color: selected
                  ? activeColor
                  : const Color(0xFFD4D9E3),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(
                  Icons.check_circle,
                  size: 15,
                  color: activeColor,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF555555),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SMALL BUTTON
  // ==========================================================

  Widget _smallButton(
      String text, {
        required double width,
        required Color background,
        required Color borderColor,
        required Color textColor,
        required VoidCallback onPressed,
      }) {
    return SizedBox(
      width: width,
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.zero,
          backgroundColor: background,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(
              color: borderColor,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

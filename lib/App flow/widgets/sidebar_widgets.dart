import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/category_bloc.dart';
import '../../blocs/menu_bloc.dart';

// import '../../bloc/category_bloc.dart';
// import '../../bloc/menu_bloc.dart';
// import '../bloc/category_bloc.dart';
// import '../bloc/menu_bloc.dart';

class SideBarWidgets extends StatefulWidget {

const SideBarWidgets({super.key});

  @override
  State<SideBarWidgets> createState() => _SideBarWidgetsState();
}

class _SideBarWidgetsState extends State<SideBarWidgets> {
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> sidebarItems = [
    {'label': 'Favourites', 'icon': 'assets/icon/fav_icon.png'},
    {'label': "Soup's", 'icon': 'assets/icon/soup.png'},
    {'label': 'Starters', 'icon': 'assets/icon/starter.png'},
    {'label': 'Main Course', 'icon': 'assets/icon/maincourse.png'},
    {'label': 'Tandoori', 'icon': 'assets/icon/Tandoori.png'},
    {'label': 'Chinese', 'icon': 'assets/icon/chinese.png'},
    {'label': 'Alcohol', 'icon': 'assets/icon/alcohol.png'},
    {'label': 'Beverages', 'icon': 'assets/icon/beverges.png'},
    {'label': 'Desserts', 'icon': 'assets/icon/deserts.png'},
  ];
  final Map<int, int> sectionIdMap = {
    0: 0, // Favourites
    1: 1,   // Soup
    2: 2,   // Starters
    3: 3,   // Main Course
    4: 4,   // Tandoori
    5: 5,   // Chinese
    6: 6,   // Alcohol
    7: 7,   // Beverages
    8: 8,   // Desserts
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSidebarItem({
    required String label,
    required String iconPath,
    required int index,
    required bool isSelected,
    required double itemWidth,
  }) {
    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<MenuBloc>().add(SelectMenuSection(index));
            final sectionId = sectionIdMap[index] ?? 1;
            final sectionName = label;
            context.read<CategoryBloc>().add(FetchCategoriesBySection(sectionId, sectionName));
          },

          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 68,
            height: 62,
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFCBEEF9) : const Color(0xFF574CB0),
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(iconPath, width: 22, height: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF493F9C) : const Color(0xFFF3FCFF),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth * 0.15;
    final itemWidth = sidebarWidth - 32;

    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        return Container(// reduced width
          // height: 65, //
          margin: const EdgeInsets.only(left: 12, top: 12, bottom: 16),
          width: sidebarWidth,
          decoration: BoxDecoration(
            color: const Color(0xFF493F9C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: List.generate(
                  sidebarItems.length,
                      (index) => _buildSidebarItem(
                    label: sidebarItems[index]['label']!,
                    iconPath: sidebarItems[index]['icon']!,
                    index: index,
                    isSelected: index == state.selectedIndex,
                    itemWidth: itemWidth,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

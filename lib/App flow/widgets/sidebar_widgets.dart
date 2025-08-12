import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/category_bloc.dart';
import '../events/category_event.dart';
import '../models/sidebar/category_model_.dart';
import '../states/category_states.dart';

class SideBarWidgets extends StatefulWidget {
  const SideBarWidgets({super.key});

  @override
  State<SideBarWidgets> createState() => _SideBarWidgetsState();
}

class _SideBarWidgetsState extends State<SideBarWidgets> {
  final ScrollController _scrollController = ScrollController();

  get string => null;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSidebarItem({
    required Category category,
    required bool isSelected,
  }) {
    return Semantics(
      label: category.name,
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<CategoryBloc>().add(SelectCategory(string.parse(category.id)));
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
                category.imagePath.isNotEmpty
                    ? Image.network(
                  category.imagePath,
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported, size: 22),
                )
                    : const Icon(Icons.fastfood, size: 22, color: Colors.white),
                const SizedBox(height: 6),
                Text(
                  category.name,
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

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CategoryLoaded) {
          return Container(
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
                    state.categories.length,
                        (index) {
                      final category = state.categories[index];
                      final isSelected = state.selectedCategory?.id == category.id;
                      return _buildSidebarItem(
                        category: category,
                        isSelected: isSelected,
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        } else if (state is CategoryError) {
          return Center(child: Text(state.message));
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

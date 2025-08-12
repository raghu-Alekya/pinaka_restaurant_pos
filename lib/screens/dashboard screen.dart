import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/category_bloc.dart';
import '../events/category_event.dart';
import '../models/category/minisubcategory_model.dart';
import '../models/sidebar/category_model_.dart';
import '../states/category_states.dart';
import '../widgets/subcategory_tab.dart';
import '../widgets/sidebar_widgets.dart';
import '../widgets/minisubcategory_widget.dart';
import '../widgets/topbar_widgets.dart';
import 'package:pinkapos_restar/screens/orders_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<MiniSubCategory> currentSubCategories = [];
  String? selectedFolderName;

  void openFolder(MiniSubCategory folder) {
    setState(() {
      currentSubCategories = folder.items ?? [];
      selectedFolderName = folder.name;
    });
  }

  void loadRootSubCategories(List<MiniSubCategory> root) {
    setState(() {
      currentSubCategories = root;
      selectedFolderName = null; // Clear folder when switching category
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: TopBarWidget(),
      ),
      body: Container(
        color: const Color(0xFFDEE8FF),
        child: Row(
          children: [
            Expanded(flex: 8, child: SideBarWidgets()),
            const SizedBox(width: 20),
            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, state) {
                    if (state is CategoryLoaded) {
                      if (currentSubCategories.isEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          // Load subcategories from selectedCategory or empty list
                          final subCats = state.selectedCategory?.subCategories
                              .cast<MiniSubCategory>() ??
                              <MiniSubCategory>[];
                          loadRootSubCategories(subCats);
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          subCategoryTabWidget(
                            categories: state.categories,
                            selectedIndex: state.selectedCategory != null
                                ? state.categories.indexOf(state.selectedCategory!)
                                : 0,
                            onTap: (index) {
                              final category = state.categories[index];
                              context.read<CategoryBloc>().add(SelectCategory(category.id));
                              // Update subcategories on tab select
                              loadRootSubCategories(category.subCategories.cast<MiniSubCategory>());
                            },
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  state.selectedCategory?.name ?? "No Category Selected",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: (state.selectedCategory == null && selectedFolderName == null)
                                        ? Colors.red
                                        : const Color(0xFF4C5F7D),
                                  ),
                                ),
                                if (state.selectedCategory != null) ...[
                                  const SizedBox(width: 4),
                                  const Text('>', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(width: 4),
                                  Text(
                                    selectedFolderName ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: selectedFolderName == null
                                          ? Colors.red
                                          : const Color(0xFF4C5F7D),
                                    ),
                                  ),
                                ],
                                if (selectedFolderName != null) ...[
                                  const SizedBox(width: 4),
                                  const Text('>', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(width: 4),
                                  Text(
                                    selectedFolderName!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 1),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFDEE8FF),
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(6),
                              margin: const EdgeInsets.all(6),
                              child: miniSubCategoryWidget(
                                subCategories: currentSubCategories,
                                onFolderSelected: openFolder,
                                section: state.selectedCategory ?? Category(id: '0', name: 'Default', imagePath: '', subCategories: []),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    if (state is CategoryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is CategoryError) {
                      return Center(child: Text(state.message));
                    }
                    return const Center(child: Text("Select a section from sidebar"));
                  },
                ),
              ),
            ),
            Expanded(
              flex: 38,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: OrderPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

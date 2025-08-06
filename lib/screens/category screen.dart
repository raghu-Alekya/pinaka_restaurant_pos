import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/category_bloc.dart';
import '../models/category/subcategory_model.dart';
import '../models/category/subcategory_model.dart';
import '../widgets/category_tab.dart';
import '../widgets/subcategories_widget.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<minisubcategory> currentSubCategories = [];
  String? selectedFolderName;

  void openFolder(minisubcategory folder) {
    setState(() {
      currentSubCategories = folder.subItems;
      selectedFolderName = folder.name;
    });
  }

  void loadRootSubCategories(List<minisubcategory> root) {
    setState(() {
      currentSubCategories = root;
      selectedFolderName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoaded) {
          if (currentSubCategories.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              loadRootSubCategories(state.subCategories);
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryTabWidget(
                categories: state.categories,
                selectedIndex: state.selectedIndex,
                onTap: (index) {
                  context.read<CategoryBloc>().add(SelectCategoryTab(index));
                  loadRootSubCategories(state.categories[index].subCategories);
                },
              ),
              const SizedBox(height: 8),

              // Breadcrumb section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      state.sectionName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: (state.selectedCategoryName.isEmpty && selectedFolderName == null)
                            ? Colors.red
                            : const Color(0xFF4C5F7D),
                      ),
                    ),
                    if (state.selectedCategoryName.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      const Text('>', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 4),
                      Text(
                        state.selectedCategoryName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: (selectedFolderName == null) ? Colors.red : const Color(0xFF4C5F7D),
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

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEE8FF),
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.all(6),
                  child: SubCategoryWidget(
                    subCategories: currentSubCategories,
                    section: state.section,
                    onFolderSelected: openFolder,
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
    );
  }
}

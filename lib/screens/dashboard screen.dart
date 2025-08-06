import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import '../bloc/category_bloc.dart';
import '../blocs/category_bloc.dart';
import '../models/category/subcategory_model.dart';
import '../widgets/category_tab.dart';
import '../widgets/sidebar_widgets.dart';
import '../widgets/subcategories_widget.dart';
import '../widgets/topbar_widgets.dart';
import '../screens/orders_screen.dart ';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
      selectedFolderName = null; // clear folder when switching category
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

            const SizedBox(height: 20),

            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: BlocBuilder<CategoryBloc, CategoryState>(
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

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                // const Icon(Icons.chevron_right, size: 16, color: Colors.black54),
                                Text(
                                  state.sectionName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: (state.selectedCategoryName.isEmpty && selectedFolderName == null)
                                        ? Colors.red // section active
                                        : const Color(0xFF4C5F7D), // section inactive
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
                                      color: (selectedFolderName == null)
                                          ? Colors.red // category active
                                          : const Color(0xFF4C5F7D), // category inactive
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
                                      color: Colors.red, // folder always active when selected
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
                              child: SubCategoryWidget(
                                subCategories: currentSubCategories,
                                onFolderSelected: (folder) {
                                  setState(() {
                                    // Update the breadcrumb text when a folder is clicked
                                    selectedFolderName = folder.name;
                                  });
                                },  section: state.section,
                              ),

                            ),
                          ),
                        ],
                      );
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/category_event.dart';
import '../../blocs/Bloc Event/minisubcategory_event.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Logic/category_bloc.dart';
import '../../blocs/Bloc Logic/minisubcategory_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc State/category_states.dart';
import '../../blocs/Bloc State/minisubcategory.dart';
import '../../blocs/Bloc State/order_state.dart';
import '../../models/category/items_model.dart';
import '../../models/category/minisubcategory_model.dart';
import '../../models/category/subcategory_model.dart';
import '../../models/order/guest_details.dart';
import '../../models/order/order_items.dart';
import '../../models/sidebar/category_model_.dart';
import '../../repositories/minisubcategory_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/variant_repository.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/subcategory_tab.dart';
import '../widgets/sidebar_widgets.dart';
import '../widgets/minisubcategory_widget.dart';
import '../widgets/top_bar.dart';
import '../widgets/variant_popup.dart';
import 'orders_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String token;
  final String restaurantId;
  final Guestcount guestDetails;
  final int orderId;
  final int tableId;
  final int zoneId;
  final String zoneName;
  final String tableName;

  const DashboardScreen({
    super.key,
    required this.token,
    required this.restaurantId,
    required this.guestDetails,
    required this.orderId,
    required this.tableId,
    required this.zoneId,
    required this.zoneName,
    required this.tableName, required kotList,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _bottomNavIndex = 0;
  List<MiniSubCategory> currentSubCategories = [];
  MiniSubCategory? selectedFolder;
  int? selectedSubCategoryId;
  String? selectedCategoryName;

  // Breadcrumbs
  List<String> breadcrumbNames = [];
  List<int> breadcrumbIds = [];

  late MiniSubCategoryRepository repository;
  late ProductRepository productRepository;

  @override
  void initState() {
    super.initState();
    repository = MiniSubCategoryRepository(
      baseUrl: "https://merchantrestaurant.alektasolutions.com",
      token: widget.token,
    );
    productRepository = ProductRepository(
      baseUrl: "https://merchantrestaurant.alektasolutions.com",
      token: widget.token,
    );

    _loadCategories();
  }

  void _loadCategories() {
    context.read<CategoryBloc>().add(
      LoadCategories(token: widget.token, restaurantId: widget.restaurantId),
    );
  }

  void onSubCategoryTap(SubCategory subCategory) {
    // Reset mini-subcategory state
    setState(() {
      selectedSubCategoryId = subCategory.id;
      selectedFolder = null;
      currentSubCategories = [];
      breadcrumbNames = [selectedCategoryName ?? "", subCategory.name];
      breadcrumbIds = [-1, subCategory.id];
    });

    context.read<MiniSubCategoryBloc>().add(
      FetchMiniSubCategories(subCategoryId: subCategory.id),
    );
  }

  void onFolderSelected(MiniSubCategory folder) {
    setState(() {
      selectedFolder = folder;

      // Get the current sub-category name
      final categoryState = context.read<CategoryBloc>().state;
      String subCategoryName = '';
      if (categoryState is CategoryLoaded) {
        final subCategory = categoryState.selectedCategory!.subCategories
            .firstWhere((sub) => sub.id == selectedSubCategoryId);
        subCategoryName = subCategory.name;
      }

      // Ensure sub-category is in breadcrumb at index 1
      if (breadcrumbNames.length < 2) {
        breadcrumbNames.insert(1, subCategoryName);
        breadcrumbIds.insert(1, selectedSubCategoryId ?? 0);
      }

      // Replace last breadcrumb (folder) if exists, otherwise add
      if (breadcrumbNames.length > 2) {
        breadcrumbNames[2] = folder.name;
        breadcrumbIds[2] = folder.id;
      } else {
        breadcrumbNames.add(folder.name);
        breadcrumbIds.add(folder.id);
      }

      // Update products under this folder
      currentSubCategories = folder.products
          .map((p) => MiniSubCategory(
        id: p.id,
        name: p.name,
        isFolder: false,
        products: [p],
        count: 1,
      ))
          .toList();
    });
  }

  void onItemSelected(Product product, Category section) {
    final orderBloc = context.read<OrderBloc>();
    if (product.variants.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => VariantPopupContent(
          product: product,
          itemName: product.name,
          variants: product.variants,
          onSelected: (variant) {
            orderBloc.add(
              AddOrderItem(
                OrderItems(
                  name: "${product.name} - ${variant.name}",
                  price: variant.price,
                  quantity: 1,
                  modifiers: [],
                  section: section,
                  productId: 0, variantId: null,
                ),
              ),
            );
            Navigator.pop(dialogContext);
          },
          onVariantSelected: (variant) {},
          section: section,
          orderBloc: orderBloc,
        ),
      );
    } else {
      orderBloc.add(
        AddOrderItem(
          OrderItems(
            name: product.name,
            price: double.tryParse(product.price.toString()) ?? 0.0,
            quantity: 1,
            modifiers: [],
            section: section,
            productId: 0, variantId: null,
          ),
        ),
      );
    }
  }

  Widget _buildBreadcrumbs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(breadcrumbNames.length, (index) {
          final name = breadcrumbNames[index];
          final isLast = index == breadcrumbNames.length - 1;
          return Row(
            children: [
              GestureDetector(
                onTap: isLast ? null : () => _onBreadcrumbTap(index),
                child: Text(
                  name,
                  style: TextStyle(
                    color: isLast ? Colors.red : Colors.black,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.bold,
                  ),
                ),
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right, size: 16),
                ),
            ],
          );
        }),
      ),
    );
  }

  void _onBreadcrumbTap(int index) {
    setState(() {
      // Keep root always, truncate after clicked index
      breadcrumbNames = breadcrumbNames.sublist(0, index + 1);
      breadcrumbIds = breadcrumbIds.sublist(0, index + 1);

      // Reset folder selection if clicking root
      if (index == 0) {
        selectedFolder = null;
        selectedSubCategoryId = breadcrumbIds.length > 1 ? breadcrumbIds[1] : null;

        // Keep sub-category breadcrumb if it exists
        if (selectedSubCategoryId != null && breadcrumbNames.length == 1) {
          // Example: Main Course > Biryani
          final categoryState = context.read<CategoryBloc>().state;
          if (categoryState is CategoryLoaded) {
            final subCategory = categoryState.selectedCategory!.subCategories
                .firstWhere((sub) => sub.id == selectedSubCategoryId);
            breadcrumbNames.add(subCategory.name);
          }
        }

        currentSubCategories = [];
        context.read<MiniSubCategoryBloc>().add(ResetMiniSubCategory());
      }
    });
  }
  void _onNavItemTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: TopBar(
          token: widget.token,
          restaurantId: widget.restaurantId,
          pin: 'pin',
        ),
      ),
      body: Container(
        color: const Color(0xFFDEE8FF),
        child: Row(
          children: [
            // LEFT SIDE: Sidebar + MiniSubCategory + Bottom Nav
            Expanded(
              flex: 63,
              child: Column(
                children: [
                  // Top part: Sidebar + MiniSubCategory
                  Expanded(
                    child: Row(
                      children: [
                        // Sidebar
                        Expanded(
                          flex: 8,
                          child: SideBarWidgets(
                            token: widget.token,
                            restaurantId: widget.restaurantId,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // MiniSubCategory / Category area
                        Expanded(
                          flex: 55,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child:
                            BlocBuilder<CategoryBloc, CategoryState>(
                              builder: (context, state) {
                                if (state is CategoryLoaded &&
                                    state.selectedCategory != null) {
                                  final category = state.selectedCategory!;

                                  if (selectedCategoryName != category.name) {
                                    selectedCategoryName = category.name;
                                    selectedSubCategoryId = null;
                                    currentSubCategories = [];
                                    selectedFolder = null;
                                    breadcrumbNames = [];
                                    breadcrumbIds = [];
                                    context
                                        .read<MiniSubCategoryBloc>()
                                        .add(ResetMiniSubCategory());
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      SubCategoryTabWidget(
                                        subCategories:
                                        category.subCategories ?? [],
                                        selectedIndex: category.subCategories
                                            ?.indexWhere((sub) =>
                                        sub.id ==
                                            selectedSubCategoryId) ??
                                            -1,
                                        onTap: (index) {
                                          final subCategory =
                                          category.subCategories![index];
                                          onSubCategoryTap(subCategory);
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      if (breadcrumbNames.isNotEmpty) ...[
                                        _buildBreadcrumbs(),
                                        const SizedBox(height: 8),
                                      ],
                                      Expanded(
                                        child: BlocBuilder<
                                            MiniSubCategoryBloc,
                                            MiniSubCategoryState>(
                                          builder: (context, miniState) {
                                            if (miniState
                                            is MiniSubCategoryLoading) {
                                              return const Center(
                                                  child:
                                                  CircularProgressIndicator());
                                            } else if (miniState
                                            is MiniSubCategoryLoaded) {
                                              currentSubCategories =
                                                  miniState.miniSubCategories;

                                              final variantRepo =
                                              VariantRepository(
                                                baseUrl:
                                                'https://merchantrestaurant.alektasolutions.com',
                                                token: widget.token,
                                              );

                                              return MiniSubCategoryWidget(
                                                subCategories:
                                                currentSubCategories,
                                                section: category,
                                                onFolderSelected:
                                                onFolderSelected,
                                                onItemSelected: (product) =>
                                                    onItemSelected(
                                                        product, category),
                                                fetchProducts:
                                                productRepository
                                                    .fetchProductsBySubCategory,
                                                repository: repository,
                                                tappedSubCategoryId:
                                                selectedSubCategoryId ??
                                                    -1,
                                                variantRepository: variantRepo,
                                              );
                                            } else if (miniState
                                            is MiniSubCategoryError) {
                                              return Center(
                                                  child:
                                                  Text(miniState.message));
                                            } else {
                                              return const Center(
                                                  child: Text(
                                                      'No mini subcategories available'));
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                if (state is CategoryLoading) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                if (state is CategoryError) {
                                  return Center(child: Text(state.message));
                                }

                                return const Center(
                                    child: Text("Select a section from sidebar"));
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Navigation
      SizedBox(
        height: 55, // fixed height for bottom nav
        child: BottomNavBar(
          selectedIndex: _bottomNavIndex,
          onItemTapped: _onNavItemTapped,
          userPermissions: null,
        ),
      )],
              ),
            ),
            // const SizedBox(width:1),

            // RIGHT SIDE: Order Panel (unchanged)
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: BlocBuilder<OrderBloc, OrderState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        // const SizedBox(height: 2),
                        Expanded(
                          child: OrderPanel(
                            token: widget.token,
                            restaurantId: widget.restaurantId,
                            guestcount: widget.guestDetails,
                            orderId: widget.orderId,
                            addonPrices: state.addonPrices,
                            onGuestSaved: (int value) {},
                            tableId: state.tableId,
                            tableName: state.tableName,
                            zoneId: state.zoneId,
                            zoneName: state.zoneName,
                            placedTables: [],
                            pin: 'pin',
                            restaurantName: 'restaurantName',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



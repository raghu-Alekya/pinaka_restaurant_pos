import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/category_event.dart';
import '../../blocs/Bloc Event/minisubcategory_event.dart';
import '../../blocs/Bloc Logic/category_bloc.dart';
import '../../blocs/Bloc Logic/minisubcategory_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc State/category_states.dart';
import '../../blocs/Bloc State/minisubcategory.dart';
import '../../models/category/items_model.dart';
import '../../models/category/minisubcategory_model.dart';
import '../../models/category/subcategory_model.dart';
import '../../models/order/guest_details.dart';
import '../../models/order/order_model.dart';
import '../../models/sidebar/category_model_.dart';
import '../../repositories/minisubcategory_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/variant_repository.dart';
// import '../bloc/category_bloc.dart';
// import '../bloc/minisubcategory_bloc.dart';
// import '../bloc/order_bloc.dart';
// import '../events/category_event.dart';
// import '../events/minisubcategory_event.dart';
// import '../models/category/items_model.dart';
// import '../models/category/minisubcategory_model.dart';
// import '../models/category/subcategory_model.dart';
// import '../models/order/guest_details.dart';
// import '../models/order/order_model.dart';
// import '../models/sidebar/category_model_.dart';
// import '../repository/minisubcategory_repository.dart';
// import '../repository/product_repository.dart';
// import '../repository/variant_repository.dart';
// import '../states/category_states.dart';
// import '../states/minisubcategory.dart';
import '../widgets/subcategory_tab.dart';
import '../widgets/sidebar_widgets.dart';
import '../widgets/minisubcategory_widget.dart';
import '../widgets/topbar_widgets.dart';
import '../widgets/variant_popup.dart';
import 'orders_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String token;
  final String restaurantId;
  final Guestcount guestDetails;

  const DashboardScreen({
    super.key,
    required this.token,
    required this.restaurantId,
    required this.guestDetails
  });
  get guestcount => null;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<MiniSubCategory> currentSubCategories = [];
  MiniSubCategory? selectedFolder;
  int? selectedSubCategoryId;

  // Breadcrumbs
  List<String> breadcrumbNames = [];
  List<int> breadcrumbIds = [];
  String? selectedCategoryName;

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

  void onSubCategoryTap(SubCategory subCategory) async {
    setState(() {
      selectedSubCategoryId = subCategory.id;
      selectedFolder = null;
      currentSubCategories = [];
    });

    // Fetch mini-subcategories
    context
        .read<MiniSubCategoryBloc>()
        .add(FetchMiniSubCategories(subCategoryId: subCategory.id));

    // Set breadcrumb safely
    final categoryState = context.read<CategoryBloc>().state;
    if (categoryState is CategoryLoaded) {
      final selectedCategory = categoryState.selectedCategory;
      if (selectedCategory != null) {
        selectedCategoryName = selectedCategory.name;
        breadcrumbNames = [selectedCategoryName!, subCategory.name];
        breadcrumbIds = [-1, subCategory.id]; // -1 placeholder for category
      }
    }

    final miniSubCategoryBloc = context.read<MiniSubCategoryBloc>();
    final subscription = miniSubCategoryBloc.stream.listen((state) async {
      if (state is MiniSubCategoryLoaded) {
        if (state.miniSubCategories.isNotEmpty) {
          setState(() {
            currentSubCategories = state.miniSubCategories;
          });
        } else {
          try {
            final products =
            await productRepository.fetchProductsBySubCategory(subCategory.id);
            setState(() {
              currentSubCategories = [
                MiniSubCategory(
                  id: subCategory.id,
                  name: "Products",
                  isFolder: false,
                  products: products,
                  count: products.length,
                )
              ];
            });
          } catch (e) {
            print("Error fetching direct products: $e");
          }
        }
      }
    });

    Future.delayed(const Duration(seconds: 2), () => subscription.cancel());
  }

  void onFolderSelected(MiniSubCategory folder) {
    setState(() {
      selectedFolder = folder;
      breadcrumbNames.add(folder.name);
      breadcrumbIds.add(folder.id);

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
      // Product has variants → show popup
      showDialog(
        context: context,
        builder: (dialogContext) => VariantPopupContent(
          product: product,
          itemName: product.name,
          variants: product.variants,
          onSelected: (variant) {
            // Add to cart only after selecting a variant
            orderBloc.add(
              AddOrderItem(
                OrderItems(
                  name: "${product.name} - ${variant.name}",
                  price: variant.price,
                  quantity: 1,
                  modifiers: [],
                  section: section,
                ),
              ),
            );
            Navigator.pop(dialogContext); // close the popup
          },
          onVariantSelected: (variant) {}, // optional for UI handling
        ),
      );
    } else {
      // No variants → add directly
      orderBloc.add(
        AddOrderItem(
          OrderItems(
            name: product.name,
            price: double.tryParse(product.price.toString()) ?? 0.0,
            quantity: 1,
            modifiers: [],
            section: section,
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

  void _onBreadcrumbTap(int index) async {
    if (index == breadcrumbNames.length - 1) return;

    setState(() {
      breadcrumbNames = breadcrumbNames.sublist(0, index + 1);
      breadcrumbIds = breadcrumbIds.sublist(0, index + 1);
    });

    if (index == 0) {
      selectedFolder = null;
      selectedSubCategoryId = null;
      currentSubCategories = [];
    } else if (index == 1) {
      final subCategoryId = breadcrumbIds[1];
      final categoryState = context.read<CategoryBloc>().state;
      if (categoryState is CategoryLoaded) {
        final subCategory = categoryState.selectedCategory!.subCategories
            .firstWhere((sub) => sub.id == subCategoryId);
        onSubCategoryTap(subCategory);
      }
    } else {
      final folderId = breadcrumbIds[index];
      final folder = currentSubCategories.firstWhere((f) => f.id == folderId);
      onFolderSelected(folder);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: TopBarWidget(token: widget.token, restaurantId: widget.restaurantId),
      ),
      body: Container(
        color: const Color(0xFFDEE8FF),
        child: Row(
          children: [
            Expanded(
              flex: 8,
              child: SideBarWidgets(token: widget.token, restaurantId: widget.restaurantId),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, state) {
                    if (state is CategoryLoaded) {
                      if (currentSubCategories.isEmpty &&
                          state.selectedCategory != null) {
                        currentSubCategories = state.selectedCategory!.subCategories
                            ?.map((sub) => MiniSubCategory(
                          id: sub.id,
                          name: sub.name,
                          isFolder:
                          (sub.subCategories?.isNotEmpty ?? false),
                          products: [],
                          count: 0,
                        ))
                            .toList() ??
                            [];
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SubCategoryTabWidget(
                            subCategories: state.selectedCategory?.subCategories ?? [],
                            selectedIndex: state.selectedCategory?.subCategories
                                .indexWhere(
                                    (sub) => sub.id == selectedSubCategoryId) ??
                                0,
                            onTap: (index) {
                              final subCategory =
                              state.selectedCategory!.subCategories[index];
                              onSubCategoryTap(subCategory);
                            },
                          ),
                          const SizedBox(height: 8),
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(
                          //       horizontal: 12, vertical: 8),
                          //   child: Text(
                          //     state.selectedCategory?.name ?? "No Category Selected",
                          //     style: const TextStyle(
                          //         fontSize: 14,
                          //         fontWeight: FontWeight.w600,
                          //         color: Color(0xFF4C5F7D)),
                          //   ),
                          // ),
                          if (breadcrumbNames.isNotEmpty) ...[
                            _buildBreadcrumbs(),
                            const SizedBox(height: 8),
                          ],
                          Expanded(
                            child: BlocBuilder<MiniSubCategoryBloc,
                                MiniSubCategoryState>(
                              builder: (context, miniState) {
                                if (miniState is MiniSubCategoryLoading) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (miniState is MiniSubCategoryLoaded) {
                                  currentSubCategories = miniState.miniSubCategories;

                                  if (currentSubCategories.isEmpty &&
                                      selectedSubCategoryId != null) {
                                    productRepository
                                        .fetchProductsBySubCategory(
                                        selectedSubCategoryId!)
                                        .then((products) {
                                      setState(() {
                                        currentSubCategories = [
                                          MiniSubCategory(
                                            id: selectedSubCategoryId!,
                                            name: "Direct Items",
                                            isFolder: false,
                                            products: products,
                                            count: products.length,
                                          ),
                                        ];
                                      });
                                    }).catchError((e) {
                                      print(
                                          "Error fetching direct products: $e");
                                    });
                                  }

                                  final variantRepo = VariantRepository(
                                    baseUrl:
                                    'https://merchantrestaurant.alektasolutions.com',
                                    token: 'your-token',
                                  );

                                  return MiniSubCategoryWidget(
                                    subCategories: currentSubCategories,
                                    section: state.selectedCategory!,
                                    onFolderSelected: onFolderSelected,
                                    onItemSelected: (product) =>
                                        onItemSelected(
                                            product, state.selectedCategory!),
                                    fetchProducts:
                                    productRepository.fetchProductsBySubCategory,
                                    repository: repository,
                                    tappedSubCategoryId: selectedSubCategoryId!,
                                    variantRepository: variantRepo,
                                  );
                                } else if (miniState is MiniSubCategoryError) {
                                  return Center(child: Text(miniState.message));
                                } else {
                                  return const Center(
                                      child: Text('No mini subcategories available'));
                                }
                              },
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
              flex: 40,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: OrderPanel(
                    token: widget.token, restaurantId: widget.restaurantId,
                     guestcount: widget.guestcount, onGuestSaved: (int ) {  },),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

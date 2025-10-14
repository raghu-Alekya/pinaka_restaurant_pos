import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/category_event.dart';
import '../../blocs/Bloc Event/minisubcategory_event.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Event/subcategory_event.dart';
import '../../blocs/Bloc Logic/category_bloc.dart';
import '../../blocs/Bloc Logic/minisubcategory_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/subcategory_bloc.dart';
import '../../blocs/Bloc State/category_states.dart';
import '../../blocs/Bloc State/minisubcategory.dart';
import '../../blocs/Bloc State/order_state.dart';
import '../../blocs/Bloc State/subcategory_states.dart';
import '../../models/UserPermissions.dart';
import '../../models/category/items_model.dart';
import '../../models/category/minisubcategory_model.dart';
import '../../models/category/subcategory_model.dart';
import '../../models/order/guest_details.dart';
import '../../models/order/order_items.dart';
import '../../models/sidebar/category_model_.dart';
import '../../repositories/minisubcategory_repository.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/variant_repository.dart';
import '../../utils/SessionManager.dart';
import '../widgets/NavigationHelper.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/subcategory_tab.dart';
import '../widgets/sidebar_widgets.dart';
import '../widgets/minisubcategory_widget.dart';
import '../widgets/top_bar.dart';
import '../widgets/variant_popup.dart';
import 'orders_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;
  final Guestcount guestDetails;
  final int orderId;
  final int tableId;
  final String zoneName;
  final String tableName;
  final UserPermissions? userPermissions;

  const DashboardScreen({
    super.key,
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.guestDetails,
    required this.orderId,
    required this.tableId,
    required this.zoneName,
    required this.tableName,
    required this.restaurantName,
    required this.userPermissions,
    required Map<String, dynamic> tableData,
    required int zoneId,
    required kotList,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _bottomNavIndex = 1;

  List<MiniSubCategory> currentSubCategories = [];
  MiniSubCategory? selectedFolder;
  int? selectedSubCategoryId;
  String? selectedCategoryName;

  // Breadcrumbs
  List<String> breadcrumbNames = [];
  List<int> breadcrumbIds = [];

  late MiniSubCategoryRepository miniSubRepo;
  late ProductRepository productRepo;
  UserPermissions? _userPermissions;
  Map<String, dynamic>? _selectedUser;

  @override
  void initState() {
    super.initState();
    miniSubRepo = MiniSubCategoryRepository(
      baseUrl: "https://merchantrestaurant.alektasolutions.com",
      token: widget.token,
    );
    productRepo = ProductRepository(
      baseUrl: "https://merchantrestaurant.alektasolutions.com",
      token: widget.token,
    );

    _loadCategories();
    _loadPermissions();
  }

  void _loadCategories() {
    final catBloc = context.read<CategoryBloc>();
    catBloc.add(
      LoadCategories(token: widget.token, restaurantId: widget.restaurantId),
    );

    catBloc.stream.listen((state) {
      if (state is CategoryLoaded && state.selectedCategory != null) {
        final category = state.selectedCategory!;
        selectedCategoryName = category.name;

        // Auto-select first subcategory
        if (category.subCategories != null &&
            category.subCategories!.isNotEmpty) {
          final firstSub = category.subCategories!.first;
          selectedSubCategoryId = firstSub.id;

          // Update breadcrumbs
          setState(() {
            breadcrumbNames = [category.name, firstSub.name];
            breadcrumbIds = [-1, firstSub.id];
          });

          // Trigger subcategory selection
          context.read<SubCategoryBloc>().add(
            SelectSubCategory(subCategory: firstSub),
          );

          // Fetch mini-subcategories
          context.read<MiniSubCategoryBloc>().add(
            FetchMiniSubCategories(subCategoryId: firstSub.id),
          );
        }
      }
    });
  }

  void onSubCategoryTap(SubCategory subCategory) {
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

      // Add folder to breadcrumbs
      if (breadcrumbNames.length > 2) {
        breadcrumbNames[2] = folder.name;
        breadcrumbIds[2] = folder.id;
      } else {
        breadcrumbNames.add(folder.name);
        breadcrumbIds.add(folder.id);
      }

      // Map folder products to MiniSubCategory list
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

    print("Tapped product: ${product.name}, variants: ${product.variants.length}");

    if (product.variants.isNotEmpty) {
      showDialog(
        context: context, // use parent context, not dialog builder context
        barrierDismissible: true,
        builder: (dialogContext) {
          return VariantPopupContent(
            product: product,
            itemName: product.name,
            variants: product.variants,
            section: section,
            orderBloc: orderBloc,
            onSelected: (variant) {
              orderBloc.add(
                AddOrderItem(
                  OrderItems(
                    name: "${product.name} - ${variant.name}",
                    price: variant.price,
                    quantity: 1,
                    modifiers: [],
                    section: section,
                    productId: product.id,
                    variantId: variant.id,
                  ),
                ),
              );
              Navigator.pop(dialogContext);
            },
            onVariantSelected: (variant) {}, // optional
          );
        },
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
            productId: product.id,
            variantId: null,
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
      breadcrumbNames = breadcrumbNames.sublist(0, index + 1);
      breadcrumbIds = breadcrumbIds.sublist(0, index + 1);

      if (index == 0) {
        // Reset selection if clicked root
        selectedSubCategoryId = null;
        selectedFolder = null;
        currentSubCategories = [];
        context.read<MiniSubCategoryBloc>().add(ResetMiniSubCategory());
      }
    });
  }

  void _onNavItemTapped(int index) {
    NavigationHelper.handleNavigation(
      context,
      _bottomNavIndex,
      index,
      widget.pin,
      widget.token,
      widget.restaurantId,
      widget.restaurantName,
      widget.userPermissions,
    );
  }
  Future<void> _loadPermissions() async {
    final savedPermissions = await SessionManager.loadPermissions();
    if (savedPermissions != null) {
      setState(() {
        _userPermissions = savedPermissions;
        _selectedUser = {
          "id": savedPermissions.userId,
          "name": savedPermissions.displayName,
          "role": savedPermissions.role,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        token: widget.token,
        pin: widget.pin,
        userPermissions: _userPermissions,
        onPermissionsReceived: (permissions) async {
          setState(() {
            _userPermissions = permissions;
            _selectedUser = {
              "id": permissions.userId,
              "name": permissions.displayName,
              "role": permissions.role,
            };
          });
        },
      ),
      body: Container(
        color: const Color(0xFFDEE8FF),
        child: Row(
          children: [
            // LEFT SIDE
            Expanded(
              flex: 63,
              child: Column(
                children: [
                  // Sidebar + SubCategory
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 8,
                          child: SideBarWidgets(
                            token: widget.token,
                            restaurantId: widget.restaurantId,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 55,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: BlocBuilder<CategoryBloc, CategoryState>(
                              builder: (context, catState) {
                                if (catState is CategoryLoading) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (catState is CategoryError) {
                                  return Center(child: Text(catState.message));
                                } else if (catState is CategoryLoaded &&
                                    catState.selectedCategory != null) {
                                  final category = catState.selectedCategory!;

                                  return Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      SubCategoryTabWidget(
                                        subCategories: category.subCategories ?? [],
                                        selectedIndex: category.subCategories != null
                                            ? category.subCategories!
                                            .indexWhere((sub) => sub.id == selectedSubCategoryId)
                                            : -1,
                                        onTap: (index) {
                                          final sub = category.subCategories![index];
                                          setState(() {
                                            selectedSubCategoryId = sub.id;
                                          });
                                          onSubCategoryTap(sub);
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
                                                subCategories: currentSubCategories,
                                                section: category,
                                                onFolderSelected: onFolderSelected,
                                                onItemSelected: (product) => onItemSelected(product, category),
                                                fetchProducts: productRepo.fetchProductsBySubCategory, // Corrected
                                                repository: miniSubRepo, // If required, pass the correct repo
                                                tappedSubCategoryId: selectedSubCategoryId ?? -1,
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
                                      )
                                    ],
                                  );
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
                    height: 55,
                    child: BottomNavBar(
                      selectedIndex: _bottomNavIndex,
                      onItemTapped: _onNavItemTapped,
                      userPermissions: _userPermissions,
                    ),
                  ),
                ],
              ),
            ),

            // RIGHT SIDE: Order Panel
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: BlocBuilder<OrderBloc, OrderState>(
                  builder: (context, state) {
                    return OrderPanel(
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
                      pin: widget.pin,
                      restaurantName: widget.restaurantName,
                      userId: _userPermissions?.userId ?? '',
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

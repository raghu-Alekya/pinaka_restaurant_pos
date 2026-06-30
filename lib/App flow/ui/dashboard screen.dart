import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinaka_restaurant_pos/App%20flow/ui/tables_screen.dart';
import 'package:pinaka_restaurant_pos/repositories/variant_repository.dart';

import '../../blocs/Bloc Event/category_event.dart';
import '../../blocs/Bloc Event/minisubcategory_event.dart';
import '../../blocs/Bloc Event/order_event.dart';
import '../../blocs/Bloc Event/serach_product_event.dart';
import '../../blocs/Bloc Event/subcategory_event.dart';
import '../../blocs/Bloc Logic/category_bloc.dart';
import '../../blocs/Bloc Logic/minisubcategory_bloc.dart';
import '../../blocs/Bloc Logic/order_bloc.dart';
import '../../blocs/Bloc Logic/search_product_bloc.dart';
import '../../blocs/Bloc Logic/subcategory_bloc.dart';
import '../../blocs/Bloc State/category_states.dart';
import '../../blocs/Bloc State/minisubcategory.dart';
import '../../blocs/Bloc State/order_state.dart';
import '../../blocs/Bloc State/search_product_state.dart';
import '../../blocs/Bloc State/subcategory_states.dart';
import '../../constants/constants.dart';
import '../../models/UserPermissions.dart';
import '../../models/category/items_model.dart';
import '../../models/category/minisubcategory_model.dart';
import '../../models/category/subcategory_model.dart';
import '../../models/order/guest_details.dart';
import '../../models/order/order_items.dart';
import '../../models/search/search_model.dart';
import '../../models/sidebar/category_model_.dart';
import '../../repositories/minisubcategory_repository.dart';
import '../../repositories/modifier_repository.dart';
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
  final List<Map<String, dynamic>> loadedTables;

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
    required this.loadedTables,

  });


  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with RouteAware {


  int _bottomNavIndex = 1;
  StreamSubscription<CategoryState>? _categorySubscription;

  List<MiniSubCategory> currentSubCategories = [];
  MiniSubCategory? selectedFolder;
  int? selectedSubCategoryId;
  String? selectedCategoryName;

  // Breadcrumbs
  List<String> breadcrumbNames = [];
  List<int> breadcrumbIds = [];


  late MiniSubCategoryRepository miniSubRepo;
  late ProductRepository productRepo;
  late VariantRepository variantRepository;

  UserPermissions? _userPermissions;
  Map<String, dynamic>? _selectedUser;
  final LayerLink _searchLink = LayerLink();
  OverlayEntry? _searchOverlay;
  bool _isSearchActive = false;
  final FocusNode _searchFocusNode = FocusNode();
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  bool _searchEditable = false;
  final TextEditingController _searchController = TextEditingController();




  @override
  void initState() {
    super.initState();
    miniSubRepo = MiniSubCategoryRepository();

    productRepo = ProductRepository(
      // baseUrl: AppConstants.baseDomain,
    );

    variantRepository = VariantRepository(
      // baseUrl: AppConstants.baseDomain,
      token: widget.token,
    );
    // 🔥 Force keyboard to close when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _searchEditable = false;
      });
      _searchFocusNode.unfocus();
    });



    _loadCategories();
    _loadPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this as RouteAware, ModalRoute.of(context)! as PageRoute);
  }



  @override
  void dispose() {
    _categorySubscription?.cancel();
    _searchController.dispose();
    routeObserver.unsubscribe(this as RouteAware);
    _searchFocusNode.dispose();
    super.dispose();
  }
  @override
  void didPopNext() {
    debugPrint("🔥 Returned to Dashboard — closing keyboard");
    // Called when returning to this screen
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    _removeSearchOverlay();
  }



  void _loadCategories() {
    context.read<CategoryBloc>().add(
      LoadCategories(
        token: widget.token,
        restaurantId: widget.restaurantId,
      ),
    );
  }

  void onSubCategoryTap(SubCategory subCategory) {
    setState(() {
      selectedSubCategoryId = subCategory.id;
      selectedFolder = null;
      currentSubCategories = [];

      breadcrumbNames = [
        selectedCategoryName!,
        subCategory.name,
      ];

      breadcrumbIds = [
        -1,
        subCategory.id,
      ];
    });

    context.read<SubCategoryBloc>().add(
      SelectSubCategory(subCategory: subCategory),
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
  void _showVariantPopup(
      BuildContext context,
      Product product,
      OrderBloc orderBloc,
      Category section,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => VariantPopupContent(
        key: UniqueKey(),
        product: product,
        itemName: product.name,
        variants: product.variants,
        section: section,
        orderBloc: orderBloc,
        onSelected: (variant) {
          orderBloc.add(
            AddOrderItem(
              OrderItems(
                productId: product.id,
                variationId: variant.id,
                name: "${product.name} - ${variant.name}",
                quantity: 1,
                price: variant.price,
                amount: variant.price,
                section: section,
                hasOptions: true,
              ),
            ),
          );
          Navigator.pop(context);
        },
        onVariantSelected: (_) {},
      ),
    );
  }


  void _showSearchOverlay(List<Search_ProductModel> products) {
    _removeSearchOverlay();

    _searchOverlay = OverlayEntry(
        builder: (context) => Positioned(
          width: 300,
          child: CompositedTransformFollower(
            link: _searchLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 38),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 300, // 🔽 DECREASE HEIGHT HERE
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return ListTile(
                        dense: true,
                        title: Text(
                          product.name,
                          style: const TextStyle(fontSize: 14),
                        ),

                        onTap: () async {
                          setState(() {
                            _searchEditable = false;
                          });

                          FocusScope.of(context).requestFocus(_searchFocusNode);

                          final orderBloc = context.read<OrderBloc>();

                          // 🔵 VARIATION PRODUCT
                          if (product.type == 'variation' && product.parentId != null) {
                            // 🔄 Show loader
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );

                            try {
                              final variants =
                              await variantRepository.fetchVariantsByProduct(product.parentId!);

                              Navigator.pop(context); // close loader

                              if (variants.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No variants available')
                                    ,duration: Duration(seconds: 1),),
                                );
                                return;
                              }

                              // ✅ Convert to Product (NOW variants exist)
                              final productForSelection = Product(
                                id: product.parentId!,
                                name: product.name,
                                price: product.price.toDouble(),
                                variants: variants,
                                images: const [],
                                modifiers: const [],
                                addOns: const [],
                                isCombo: false,
                                hasOptions: true,
                                isVariantProduct: true,
                              );

                              // 🔥 Reuse SAME logic
                              onItemSelected(
                                productForSelection,
                                Category(
                                  id: '-1',
                                  name: 'Search',
                                  imagepath: '',
                                  subCategories: const [],
                                ),
                              );
                              _searchController.clear();

                            } catch (e) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to load variants'),
                                  duration: Duration(seconds: 1),),
                              );
                            }

                            _removeSearchOverlay();
                            context.read<SearchProductBloc>().add(SearchClearProducts());
                            return;
                          }

                          // 🟢 SIMPLE PRODUCT
                          final simpleProduct = Product(
                            id: product.id,
                            name: product.name,
                            price: product.price.toDouble(),
                            variants: const [],
                            images: const [],
                            modifiers: const [],
                            addOns: const [],
                            isCombo: false,
                            hasOptions: false,
                            isVariantProduct: false,
                          );

                          onItemSelected(
                            simpleProduct,
                            Category(
                              id: '-1',
                              name: 'Search',
                              imagepath: '',
                              subCategories: const [],
                            ),
                          );
                          _searchController.clear();

                          _removeSearchOverlay();
                          context.read<SearchProductBloc>().add(SearchClearProducts());
                        }



                    );},
                ),
              ),
            ),
          ),
        ));

    Overlay.of(context).insert(_searchOverlay!);
  }
  void _showNoProductsOverlay() {
    _removeSearchOverlay();
    _removeOverlayOnly();
    _searchOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _searchLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 38),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              child: const Text(
                "No Products Found",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_searchOverlay!);
  }
  void _removeOverlayOnly() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  void _removeSearchOverlay() {
    setState(() {
      _searchEditable = false; // 🔒 lock input
    });

    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    _searchOverlay?.remove();
    _searchOverlay = null;
  }
  void _clearSearchField() {
    // 1️⃣ Clear text
    _searchController.clear();

    // 2️⃣ Reset flags
    _isSearchActive = false;
    _searchEditable = false;

    // 3️⃣ Remove overlay
    _removeSearchOverlay();

    // 4️⃣ Clear search bloc results
    context.read<SearchProductBloc>().add(SearchClearProducts());

    // 5️⃣ Remove keyboard focus
    FocusScope.of(context).unfocus();
  }




  void onItemSelected(Product product, Category section) {
    final orderBloc = context.read<OrderBloc>();

    print("Tapped product: ${product.name}, variants: ${product.variants.length}");

    if (product.variants.isNotEmpty) {
      showDialog(
        context: context, // use parent context, not dialog builder context
        barrierDismissible: false,
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
                    variationId: variant.id,

                    // ✅ base amount (item total)
                    amount: variant.price * 1,
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
            variationId: null,

            // ✅ base amount
            amount: (double.tryParse(product.price.toString()) ?? 0.0) * 1,
          ),
        ),

      );
    }
  }


  Widget _buildBreadcrumbs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // LEFT: Scrollable Breadcrumbs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(breadcrumbNames.length, (index) {
                  final name = breadcrumbNames[index];
                  final isLast = index == breadcrumbNames.length - 1;

                  return Row(
                    children: [
                      GestureDetector(
                        onTap: (isLast || index == 0)
                            ? null
                            : () => _onBreadcrumbTap(index),
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            color: isLast ? Colors.red : Colors.black,
                            fontWeight:
                            isLast ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (!isLast)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.chevron_right, size: 16),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(width: 3),

          // RIGHT: Search Bar (Fixed Position)
          Align(
            alignment: Alignment.centerRight,
            child: CompositedTransformTarget(
              link: _searchLink,
              child: Container(
                width: 230,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,

                  autofocus: false,

                  // 🔐 KEY LINE
                  readOnly: !_searchEditable,

                  decoration: const InputDecoration(
                    hintText: "Search item",
                    prefixIcon: Icon(Icons.search, size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),

                  onTap: () {
                    if (!_searchEditable) {
                      setState(() {
                        _searchEditable = true; // 🔓 unlock typing
                      });

                      // delay ensures Flutter updates readOnly before focus
                      Future.microtask(() {
                        FocusScope.of(context).requestFocus(_searchFocusNode);
                      });
                    }
                  },

                  onChanged: (value) {
                    final query = value.trim();
                    _isSearchActive = query.isNotEmpty;

                    if (query.isEmpty) {
                      _removeSearchOverlay();
                      context.read<SearchProductBloc>().add(SearchClearProducts());
                      return;
                    }

                    if (query.length >= 2) {
                      context
                          .read<SearchProductBloc>()
                          .add(SearchFetchProducts(search: query));
                    }
                  },
                ),
              ),
            ),
          ),





        ],
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

  void _onNavItemTapped(int index) async {
    setState(() {
      _searchEditable = false;
    });
    _searchController.clear();

    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    final permissions =
        widget.userPermissions ?? await SessionManager.loadPermissions();
    // 🔍 DEBUG LINE — ADD IT HERE
    debugPrint("BOTTOM NAV PERMS: ${permissions?.displayName}");


    // NavigationHelper.handleNavigation(
    //   context,
    //   _bottomNavIndex,
    //   index,
    //   widget.pin,
    //   widget.token,
    //   widget.restaurantId,
    //   widget.restaurantName,
    //   permissions, // ✅ NEVER NULL NOW
    // );
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
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _searchFocusNode.unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          appBar: TopBar(
            token: widget.token,
            pin: widget.pin,
            userPermissions: _userPermissions,
            restaurantId: widget.restaurantId,
            restaurantName: widget.restaurantName,
            isOrderPanel: true,
            isHomeScreen: false,
            showTablesIcon: true,// Show Tables icon only on Dashboard
            // onTablesTap: () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (_) => TablesScreen(
            //         token: widget.token,
            //         pin: widget.pin,
            //         restaurantId: widget.restaurantId,
            //         restaurantName: widget.restaurantName,
            //         userPermissions: _userPermissions, loadedTables: [],
            //       ),
            //     ),
            //   );
            // },
            onPermissionsReceived: (permissions) {
              setState(() {
                _userPermissions = permissions;
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
                                onCategorySelected: (category) {
                                  setState(() {
                                    selectedCategoryName = category.name;

                                    breadcrumbNames = [category.name];
                                    breadcrumbIds = [int.parse(category.id)];
                                    selectedFolder = null;
                                    currentSubCategories = [];
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              flex: 55,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),

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
                                          const SizedBox(height: 8),
                                          if (breadcrumbNames.isNotEmpty) ...[
                                            _buildBreadcrumbs(),
                                            const SizedBox(height: 8),
                                          ],
                                          BlocBuilder<SubCategoryBloc, SubCategoryState>(
                                            builder: (context, subState) {
                                              if (subState is! SubCategoryLoaded) {
                                                return const SizedBox();
                                              }

                                              final selectedIndex = subState.subcategories.indexWhere(
                                                    (e) => e.id == subState.selectedSubCategory,
                                              );

                                              return SubCategoryTabWidget(
                                                subCategories: subState.subcategories,
                                                selectedIndex: selectedIndex,
                                                onTap: (index) {
                                                  final subCategory = subState.subcategories[index];

                                                  onSubCategoryTap(subCategory);

                                                  context.read<SubCategoryBloc>().add(
                                                    SelectSubCategory(subCategory: subCategory),
                                                  );
                                                },
                                              );
                                            },
                                          ),

                                          const SizedBox(height: 6),
                                          // if (breadcrumbNames.isNotEmpty) ...[
                                          //   _buildBreadcrumbs(),
                                          //   const SizedBox(height: 8),
                                          // ],
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
                                                    // baseUrl:
                                                    // 'https://merchantrestaurant.alektasolutions.com',
                                                    token: widget.token,
                                                  );
                                                  final modifierRepo = ModifierRepository(
                                                    token: widget.token,
                                                  );

                                                  final subState = context.watch<SubCategoryBloc>().state;

                                                  return MiniSubCategoryWidget(
                                                    subCategories: currentSubCategories,
                                                    section: category,
                                                    onFolderSelected: onFolderSelected,
                                                    onItemSelected: (product) => onItemSelected(product, category),
                                                    fetchProducts: productRepo.fetchProductsBySubCategory,
                                                    repository: miniSubRepo,
                                                    tappedSubCategoryId: subState is SubCategoryLoaded
                                                        ? (subState.selectedSubCategory ?? -1)
                                                        : -1,
                                                    variantRepository: variantRepo,
                                                    modifierRepository: modifierRepo,
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
                      // SizedBox(
                      //   height: 55,
                      //   child: BottomNavBar(
                      //     selectedIndex: _bottomNavIndex,
                      //     onItemTapped: _onNavItemTapped,
                      //     userPermissions: _userPermissions,
                      //   ),
                      // ),
                    ],
                  ),
                ),

                // RIGHT SIDE: Order Panel
                Expanded(
                  flex: 49,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 12, 12, 12),
                    child: BlocBuilder<OrderBloc, OrderState>(
                      builder: (context, state) {
                        return OrderPanel(
                          token: widget.token,
                          loadedTables: widget.loadedTables,
                          restaurantId: widget.restaurantId,
                          guestcount: state.guestDetails,

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
                // ✅ ADD THIS BLOCK (ONLY ONCE)
                BlocListener<SearchProductBloc, SearchProductState>(
                  listener: (context, state) {
                    debugPrint("🧠 Search State Changed → $state");
                    if (!_isSearchActive) {
                      _removeSearchOverlay();
                      return;
                    }

                    if (state is SearchProductLoaded) {
                      debugPrint(
                          "📥 Overlay showing ${state.products.length} items");
                      _showSearchOverlay(state.products);
                    }

                    else if (state is SearchProductEmpty) {
                      _showNoProductsOverlay(); // 👈 SHOW MESSAGE
                    }

                    else if (state is SearchProductInitial ||
                        state is SearchProductError) {
                      _removeSearchOverlay();
                    }
                  },
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ));
  }
}
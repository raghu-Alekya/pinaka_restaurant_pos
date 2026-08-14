import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_captain_app/constants/color_constants.dart';
import 'package:restaurant_captain_app/features/search_products/search_products_bloc/search_bloc.dart';
import 'package:restaurant_captain_app/features/search_products/search_products_bloc/search_event.dart';
import 'package:restaurant_captain_app/features/search_products/search_products_bloc/search_state.dart';
import 'package:restaurant_captain_app/features/search_products/search_products_domain/search_entity.dart';

import '../home_screen/order_menu/entities/product_entity.dart';

class SearchScreen extends StatefulWidget {
  final Function(ProductEntity) onAddToCart;

  const SearchScreen({
    Key? key,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Search',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Search input row, separate from the AppBar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Search for Category/item',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _controller.clear();
                      context.read<SearchBloc>().add(ClearSearch());
                      setState(() {});
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (value) {
                  setState(() {}); // toggles the clear (×) icon
                  context.read<SearchBloc>().add(SearchQueryChanged(query: value));
                },
              ),
            ),
          ),

          // ── Results / empty state ──
          Expanded(
            child: BlocConsumer<SearchBloc, SearchState>(
              listener: (context, state) {
                if (state is SearchError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      duration: const Duration(milliseconds:2),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SearchLoaded) {
                  if (state.results.isEmpty) {
                    return const _SearchEmptyState(message: 'No results found');
                  }
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: state.results.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = state.results[index];
                      final bool isInStock = item.inStock == 'Yes';
                      return _SearchResultRow(
                        item: item,
                        isInStock: isInStock,
                        onTap: () {
                          if (!isInStock) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('This item is out of stock'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          final product = ProductEntity(
                            id: item.id,
                            name: item.name,
                            price: item.price,
                            inStock: true,
                          );
                          widget.onAddToCart(product);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${item.name} to cart'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      );
                    },
                  );
                } else if (state is SearchError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Search failed',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            final query = _controller.text.trim();
                            if (query.isNotEmpty) {
                              context.read<SearchBloc>().add(SearchQueryChanged(query: query));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                // Initial state — nothing typed yet.
                return const _SearchEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Result Row (plain list style, matches design) ───
class _SearchResultRow extends StatelessWidget {
  final SearchResultItem item;
  final bool isInStock;
  final VoidCallback onTap;

  const _SearchResultRow({
    required this.item,
    required this.isInStock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isInStock ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    // NOTE: assumes SearchResultItem has a `category` field —
                    // rename this if your entity calls it something else.
                    'Price: ${item.price}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isInStock ? ColorConstants.primaryColor : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.north_west_rounded,
              size: 16,
              color: isInStock ? Colors.grey.shade400 : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state (no query yet, or no results) ───
class _SearchEmptyState extends StatelessWidget {
  final String? message;

  const _SearchEmptyState({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              // TODO: point this at your actual illustration asset path,
              // and make sure it's declared under `flutter: assets:` in
              // pubspec.yaml.
              'assets/images/search_em`pty.png',
              width: 220,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.search_off_rounded,
                size: 96,
                color: Colors.grey.shade300,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
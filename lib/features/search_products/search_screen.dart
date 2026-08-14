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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
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
                },
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (value) {
              context.read<SearchBloc>().add(SearchQueryChanged(query: value));
            },
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<SearchBloc, SearchState>(
        listener: (context, state) {
          if (state is SearchError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is SearchLoaded) {
            if (state.results.isEmpty) {
              return const Center(
                child: Text(
                  'No results found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.results.length,
              itemBuilder: (context, index) {
                final item = state.results[index];
                return _SearchResultCard(
                  item: item,
                  onTap: () {
                    final product = ProductEntity(
                      id: item.id,
                      name: item.name,
                      price: item.price,
                      inStock: item.inStock == 'Yes',
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
                  Text(
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
                      // Retry the current search
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
          return const Center(
            child: Text(
              'Search for items',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}

// ─── Search Result Card ───
class _SearchResultCard extends StatelessWidget {
  final SearchResultItem item;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: ColorConstants.primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.fastfood,
            color: ColorConstants.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '\$${item.price}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: item.inStock != 'Yes'
            ? const Chip(
          label: Text(
            'Out of Stock',
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        )
            : const Icon(
          Icons.add_circle,
          color: ColorConstants.primaryColor,
        ),
      ),
    );
  }
}
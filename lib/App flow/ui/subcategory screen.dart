import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/Bloc Event/subcategory_event.dart';
import '../../blocs/Bloc Logic/subcategory_bloc.dart';
import '../../blocs/Bloc State/subcategory_states.dart';
import '../../models/category/subcategory_model.dart';
// import '../bloc/subcategory_bloc.dart';
// import '../events/subcategory_event.dart';
// import '../models/category/subcategory_model.dart';
// import '../states/subcategory_states.dart';

class SubCategoryScreen extends StatefulWidget {
  final String categoryId;
  final String token;

  const SubCategoryScreen({
    super.key,
    required this.categoryId,
    required this.token,
  });

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  @override
  void initState() {
    super.initState();

    // Trigger subcategory fetch when screen loads
    context.read<SubCategoryBloc>().add(
      LoadSubCategories(
        token: widget.token,
        categoryId: widget.categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sub Categories"),
      ),
      body: BlocBuilder<SubCategoryBloc, SubCategoryState>(
        builder: (context, state) {
          if (state is SubCategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SubCategoryLoaded) {
            final List<SubCategory> subCategories = state.subcategories;

            if (subCategories.isEmpty) {
              return const Center(
                child: Text("No Sub Categories Found"),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: subCategories.length,
              itemBuilder: (context, index) {
                final subCategory = subCategories[index];

                return GestureDetector(
                  onTap: () {
                    debugPrint("Selected SubCategory: ${subCategory.name}");
                    // TODO: Navigate or update dashboard with selected subcategory
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        subCategory.imagePath != null &&
                            subCategory.imagePath!.isNotEmpty
                            ? Image.network(
                          subCategory.imagePath!,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported,
                              size: 40),
                        )
                            : const Icon(Icons.image, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          subCategory.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (state is SubCategoryError) {
            return Center(
              child: Text(
                "Error: ${state.message}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }
}

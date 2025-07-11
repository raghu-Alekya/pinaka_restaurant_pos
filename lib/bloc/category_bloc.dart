import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/category/category_model.dart';
import '../models/category/subcategory_model.dart';
import '../models/sidebar/menu_selection.dart';  // Import MenuSection

// EVENTS
abstract class CategoryEvent {}

class FetchCategoriesBySection extends CategoryEvent {
  final int sectionId;
  final String sectionName;

  FetchCategoriesBySection(this.sectionId, this.sectionName);
}

class SelectCategoryTab extends CategoryEvent {
  final int selectedIndex;
  SelectCategoryTab(this.selectedIndex);
}

// STATES
abstract class CategoryState {}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<subcategory> categories;
  final int selectedIndex;
  final String sectionName;

  CategoryLoaded(this.categories, this.selectedIndex, this.sectionName);

  List<minisubcategory> get subCategories =>
      categories[selectedIndex].subCategories;

  String get selectedCategoryName => categories[selectedIndex].name;

  category get section => categories[selectedIndex].section; // ✅ Added section getter
}

class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
}

// BLOC
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(CategoryInitial()) {
    on<FetchCategoriesBySection>(_onFetchCategoriesBySection);
    on<SelectCategoryTab>(_onSelectCategoryTab);
  }

  Future<void> _onFetchCategoriesBySection(
      FetchCategoriesBySection event,
      Emitter<CategoryState> emit,
      ) async {
    emit(CategoryLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final dummySection = category(name: event.sectionName, categories: []);  // ✅ Dummy section

      final allCategories = [
        subcategory(
          id: 1,
          name: "Veg Soups",
          imagepath: "assets/icons/veg_soup.png",
          sectionId: 1,
          subCategories: [
            minisubcategory(name: "Tomato Soup", imagePath: "", isFolder: false, price: 120),
            minisubcategory(name: "Sweet Corn Soup", imagePath: "", isFolder: false, price: 130),
            minisubcategory(name: "Mushroom Soup", imagePath: "", isFolder: false, price: 150),
          ],
          section: dummySection,
        ),
        subcategory(
          id: 2,
          name: "Non-Veg Soups",
          imagepath: "assets/icons/nonveg_soup.png",
          sectionId: 1,
          subCategories: [
            minisubcategory(name: "Chicken Clear Soup", imagePath: "", isFolder: false, price: 150, isVeg: false),
            minisubcategory(name: "Chicken Manchow Soup", imagePath: "", isFolder: false, price: 160, isVeg: false),
          ],
          section: dummySection,
        ),
        subcategory(
          id: 3,
          name: "Special Soups",
          imagepath: "assets/icons/special_soup.png",
          sectionId: 1,
          subCategories: [
            minisubcategory(name: "Seafood Soup", imagePath: "", isFolder: false, price: 200, isVeg: false),
          ],
          section: dummySection,
        ),
        subcategory(
          id: 4,
          name: "Biryani",
          sectionId: 3,
          imagepath: "",
          subCategories: [
            minisubcategory(
              name: "Veg Biryani",
              imagePath: "",
              isFolder: true,
              isVeg: true,
              subItems: [
                minisubcategory(name: "bhimavaram royyala", imagePath: "assets/icon/paneer_tikka.png", price: 150, isVeg: true),
                minisubcategory(name: "Veg Dum Biryani", imagePath: "", price: 140, isVeg: true),
              ],
            ),
            minisubcategory(
              name: "Non-Veg Biryani",
              imagePath: "",
              isFolder: true,
              isVeg: false,
              subItems: [
                minisubcategory(name: "Chicken Biryani", imagePath: "", price: 180, isVeg: false),
                minisubcategory(name: "Mutton Biryani", imagePath: "", price: 220, isVeg: false),
              ],
            ),
          ],
          section: dummySection,
        ),
      ];

      final filtered = allCategories
          .where((c) => c.sectionId == event.sectionId)
          .toList();

      emit(CategoryLoaded(filtered, 0, event.sectionName));
    } catch (_) {
      emit(CategoryError("Failed to load categories"));
    }
  }

  void _onSelectCategoryTab(
      SelectCategoryTab event,
      Emitter<CategoryState> emit,
      ) {
    if (state is CategoryLoaded) {
      final loadedState = state as CategoryLoaded;
      emit(CategoryLoaded(
        loadedState.categories,
        event.selectedIndex,
        loadedState.sectionName,
      ));
    }
  }
}

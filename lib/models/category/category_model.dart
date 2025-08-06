import 'subcategory_model.dart';
import '../sidebar/menu_selection.dart';  // Make sure this import is correct

class subcategory {
  final int id;
  final String name;
  final String imagepath;
  final int sectionId;
  final List<minisubcategory> subCategories;
  final category section;

  subcategory({
    required this.id,
    required this.name,
    required this.imagepath,
    required this.sectionId,
    required this.subCategories,
    required this.section,
  });

  /// Fix: Accept MenuSection as second argument
  factory subcategory.fromJson(Map<String, dynamic> json, category section) {
    return subcategory(
      id: json['id'],
      name: json['name'],
      imagepath: json['imagepath'],
      sectionId: json['sectionId'],
      subCategories: (json['subCategories'] as List<dynamic>?)
          ?.map((item) => minisubcategory.fromJson(item))
          .toList() ??
          [],
      section: section,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagepath': imagepath,
    'sectionId': sectionId,
    'subCategories': subCategories.map((s) => s.toJson()).toList(),
    // ⚠️ Note: section is not included in JSON output. Add if needed.
  };
}

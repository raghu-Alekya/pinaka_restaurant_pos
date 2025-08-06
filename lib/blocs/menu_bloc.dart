import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/sidebar/menu_selection.dart';

/// EVENTS
abstract class MenuEvent {}

class SelectMenuSection extends MenuEvent {
  final int index;
  SelectMenuSection(this.index);
}

/// STATES
class MenuState {
  final int selectedIndex;
  final category selectedSection;

  MenuState({required this.selectedIndex, required this.selectedSection});

  MenuState copyWith({int? selectedIndex, category? selectedSection}) {
    return MenuState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      selectedSection: selectedSection ?? this.selectedSection,
    );
  }
}

/// BLOC
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final List<category> menuSections = [
    category(name: "Favourites", categories: []),
    category(name: "Alcohol", categories: []),
    category(name: "Soups", categories: []),
    category(name: "Starters", categories: []),
    category(name: "Main Course", categories: []),
    category(name: "Tandoori", categories: []),
    category(name: "Chinese", categories: []),
    category(name: "Beverages", categories: []),
    category(name: "Desserts", categories: []),
  ];

  MenuBloc()
      : super(MenuState(
    selectedIndex: 0,
    selectedSection: category(name: "Favourites", categories: []),
  )) {
    on<SelectMenuSection>((event, emit) {
      emit(MenuState(
        selectedIndex: event.index,
        selectedSection: menuSections[event.index],
      ));
    });
  }
}

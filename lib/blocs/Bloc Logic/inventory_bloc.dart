// import 'package:bloc/bloc.dart';
// // import '../../repositories/beverage_inventory_repository.dart';
// import '../../repositories/inventory_repository/beverage_iventory_repository.dart';
// import '../Bloc Event/inventory _event.dart';
// // import '../Bloc Event/inventory_event.dart';
// import '../Bloc State/inventory_state.dart';
//
//
//
// class ProductBloc extends Bloc<ProductEvent, ProductState> {
//   final ProductRepository repository;
//
//   ProductBloc(this.repository) : super(ProductInitial()) {
//     on<FetchProducts>((event, emit) async {
//       emit(ProductLoading());
//
//       try {
//         final response = await repository.getProducts(
//           search: event.search,
//           sku: event.sku,
//           filter: event.filter ?? 'Most Popular',
//           categoryId: event.categoryId ?? 177,
//         );
//
//         emit(ProductLoaded(response.products ?? []));
//       } catch (e) {
//         emit(ProductError(e.toString()));
//       }
//     });
//   }
// }
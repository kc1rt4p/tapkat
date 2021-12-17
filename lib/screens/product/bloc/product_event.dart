part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object> get props => [];
}

class SaveOffer extends ProductEvent {
  final String userid;
  final String productname;
  final String productdesc;
  final double price;
  final String type;
  final SelectedMedia selectedMedia;

  SaveOffer({
    required this.userid,
    required this.productname,
    required this.productdesc,
    required this.price,
    required this.type,
    required this.selectedMedia,
  });
}

part of 'review_bloc.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();
  
  @override
  List<Object> get props => [];
}

class ReviewInitial extends ReviewState {}

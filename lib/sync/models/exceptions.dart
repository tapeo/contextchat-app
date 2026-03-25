class BranchNotFoundException implements Exception {
  final String branch;
  BranchNotFoundException(this.branch);
  @override
  String toString() => 'Branch "$branch" not found';
}

class EmptyRepositoryException implements Exception {
  final String message;
  EmptyRepositoryException(this.message);
  @override
  String toString() => message;
}

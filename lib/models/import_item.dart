class ImportItem {
  final String rawTitle;
  final String seriesTitle;
  final double volumeNumber;
  final String type; // lightNovel, manga, comic, book
  final String status; // active, wishlist, completed
  final bool isOwned;
  final bool isGift;
  final String availability; // available, outOfStock, outOfPrint, announced
  final double price;
  final DateTime? releaseOrPurchaseDate;
  final List<String> tags;
  final String sourceFormat; // json, csv, xlsx, goodreads, storygraph
  bool isSelected;

  ImportItem({
    required this.rawTitle,
    required this.seriesTitle,
    required this.volumeNumber,
    this.type = 'lightNovel',
    this.status = 'active',
    this.isOwned = true,
    this.isGift = false,
    this.availability = 'available',
    this.price = 0.0,
    this.releaseOrPurchaseDate,
    this.tags = const [],
    this.sourceFormat = 'csv',
    this.isSelected = true,
  });

  ImportItem copyWith({
    String? rawTitle,
    String? seriesTitle,
    double? volumeNumber,
    String? type,
    String? status,
    bool? isOwned,
    bool? isGift,
    String? availability,
    double? price,
    DateTime? releaseOrPurchaseDate,
    List<String>? tags,
    String? sourceFormat,
    bool? isSelected,
  }) {
    return ImportItem(
      rawTitle: rawTitle ?? this.rawTitle,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      volumeNumber: volumeNumber ?? this.volumeNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      isOwned: isOwned ?? this.isOwned,
      isGift: isGift ?? this.isGift,
      availability: availability ?? this.availability,
      price: price ?? this.price,
      releaseOrPurchaseDate: releaseOrPurchaseDate ?? this.releaseOrPurchaseDate,
      tags: tags ?? this.tags,
      sourceFormat: sourceFormat ?? this.sourceFormat,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

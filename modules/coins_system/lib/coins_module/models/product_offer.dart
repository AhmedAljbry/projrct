class ProductOffer {
  const ProductOffer({
    required this.productId,
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.coins,
    this.rawPrice = 0,
    this.currencyCode = '',
  });

  final String productId;
  final String title;
  final String description;
  final String priceLabel;
  final int coins;
  final double rawPrice;
  final String currencyCode;
}

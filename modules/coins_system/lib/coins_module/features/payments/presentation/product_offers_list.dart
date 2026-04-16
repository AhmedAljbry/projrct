import 'package:flutter/material.dart';

import '../../../models/product_offer.dart';

class ProductOffersList extends StatelessWidget {
  const ProductOffersList({
    super.key,
    required this.products,
    required this.onBuy,
  });

  final List<ProductOffer> products;
  final ValueChanged<ProductOffer> onBuy;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: Colors.white,
          title: Text(product.title),
          subtitle: Text('${product.coins} coins • ${product.description}'),
          trailing: FilledButton(
            onPressed: () => onBuy(product),
            child: Text(product.priceLabel),
          ),
        );
      },
    );
  }
}

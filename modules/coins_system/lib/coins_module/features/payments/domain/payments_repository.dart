import '../../../models/product_offer.dart';
import '../../../models/reward_result.dart';

abstract class PaymentsRepository {
  Future<List<ProductOffer>> loadProducts();
  Future<RewardResult> buyProduct(String productId);
  Future<void> dispose();
}

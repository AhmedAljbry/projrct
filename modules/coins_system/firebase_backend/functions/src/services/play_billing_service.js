const { google } = require('googleapis');
const { HttpsError } = require('firebase-functions/v2/https');

async function verifyProductPurchase({ packageName, productId, purchaseToken }) {
  const auth = new google.auth.GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  const authClient = await auth.getClient();
  const androidpublisher = google.androidpublisher({
    version: 'v3',
    auth: authClient,
  });

  const response = await androidpublisher.purchases.products.get({
    packageName,
    productId,
    token: purchaseToken,
  });

  const purchase = response.data;
  if (!purchase) {
    throw new HttpsError('not-found', 'Purchase not found.');
  }

  if (purchase.purchaseState !== 0) {
    throw new HttpsError('failed-precondition', 'Purchase is not completed.');
  }

  if (purchase.acknowledgementState === 0) {
    await androidpublisher.purchases.products.acknowledge({
      packageName,
      productId,
      token: purchaseToken,
      requestBody: {},
    });
  }

  return purchase;
}

module.exports = {
  verifyProductPurchase,
};

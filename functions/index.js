const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.addNumbers = onCall(
  { region: "asia-east2" },
  (request) => {
    const data = request.data;
    const a = parseFloat(data.a);
    const b = parseFloat(data.b);
    if (isNaN(a) || isNaN(b)) {
      throw new HttpsError(
          'invalid-argument',
          'Tham số "a" và "b" phải là số hợp lệ.'
      );
    }
    return { result: a + b };
  }
);
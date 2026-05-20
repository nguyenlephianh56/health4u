const admin = require('firebase-admin');

const serviceAccount = require('./secret/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testFirestore() {
  try {
    const snapshot = await db.collection('users').get();

    snapshot.forEach(doc => {

      const data = doc.data();

      delete data.password_hash;

      console.log(doc.id, data);

    });

  } catch (error) {
    console.error(error);
  }
}

testFirestore();
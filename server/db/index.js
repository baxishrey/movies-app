const mongoose = require('mongoose');

const mongoHost = process.env.MONGODB_URL || '127.0.0.1';

mongoose
  .connect(`mongodb://${mongoHost}:27017/cinema`, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    reconnectTries: 50,
    reconnectInterval: 10000,
  })
  .catch((e) => {
    console.error('Connection error', e.message);
  });

const db = mongoose.connection;

module.exports = db;

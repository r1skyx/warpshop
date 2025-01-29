const mysql = require('mysql');

// db connection
const connection = mysql.createConnection({
  host: '172.23.0.2',
  user: 'root',
  password: 'password',
  database: 'warpshop',
  port:3306
})

connection.connect()

module.exports = connection;
const express = require('express');
const router =  require('./routes/customerOrders');
const port = 3000

const app = express();
app.use('/api/customerorders',router)

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
var express = require('express');
var router = express.Router();
const connection = require('../config/dbconfig')

const replyInfoObj = {
  tError:{replyInfo:'technical error'},
  rError:{replyInfo:'request error'}
}

/* GET CustOrder with quantity from-to query */
router.get('/', function(req, res, next) {
  const query = req.query
  if(!(query.qFr && query.qTo)){
    res.status(400).send(replyInfoObj.rError)
  }
  const qFr = Number(query.qFr)
  const qTo = Number(query.qTo)

  if ((!qFr || !qTo) || (typeof qFr !== 'number' || typeof qTo !== 'number')){
    res.status(400).send(replyInfoObj.rError)
    return;
  }
  if (qFr>qTo){
    res.status(400).send(replyInfoObj.rError)
    return;
  }
  if (connection.state !== 'authenticated'){
    res.status(503).send(replyInfoObj.tError)
    return;
  }

  connection.query(`SELECT CustOrder.* FROM CustOrder
  JOIN OrderElement OE ON CustOrder.ID = OE.OrderID
  WHERE OE.Quantity>=${query.qFr} AND OE.Quantity<=${query.qTo}`,
  (err, rows, fields)=>{
    if (err) throw err
    const results = JSON.parse(JSON.stringify(rows))
    if(results.length>100){
      res.status(400).send(replyInfoObj.rError)
      return;
    }
    let replyInfo = 'ok'
    res.status(200).send({replyInfo, results})
  })
  return;
});


/* GET CustOrder based on OrderID */
router.get('/:id', function(req, res, next) {
  const id = Number(req.params.id)
  
  if (!id){
    res.status(400).send(replyInfoObj.rError);
    return;
  }
  
  if (connection.state !== 'authenticated'){
    res.status(503).send(replyInfoObj.tError)
    return;
  }

  connection.query(`SELECT * FROM CustOrder
  WHERE ID=${id}`,
  (err, rows, fields)=>{
    if (err) throw err
    const results = JSON.parse(JSON.stringify(rows))
    if(results.length>100){
      res.status(400).send(replyInfoObj.rError)
      return;
    }
    let replyInfo = 'ok'
    res.status(200).send({replyInfo, results})
  })
  return
});

module.exports = router;

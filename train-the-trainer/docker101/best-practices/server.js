var express = require('express');
var bodyParser = require('body-parser');
var app = express();

//Allow all requests from all domains
app.all('/*', function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "X-Requested-With, Content-Type, Accept");
  res.header("Access-Control-Allow-Methods", "POST, GET");
  next();
});

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: false}));

var animals = [
    {
        "id": "234kjw",
        "text": "octopus"
    },
    {
        "id": "as82w",
        "text": "penguin"
    },
    {
        "id": "234sk1",
        "text": "whale"
    }
];


app.get('/animals', function(req, res) {
    console.log("GET From SERVER");
    res.send(animals);
});

app.post('/animals', function(req, res) {
    var animal = req.body;
    console.log(req.body);
    animals.push(animal);
    res.status(200).send("Successfully posted animal\n");
});

console.log("🐙🐧🐋 Server running. Retreive animals from http://localhost:6069/animals")
app.listen(6069);

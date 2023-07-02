// Importing libraries
require("dotenv").config();
const express = require("express")
const {Web3} = require('web3');
const Axios = require("axios");
const cors = require("cors");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const session = require("express-session");
const passport = require("passport");
const passpoerLocalMongoose = require("passport-local-mongoose");


//Middlewares
const app = express();
app.use(session({
    secret: process.env.SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: false
    }
}));

app.use(passport.initialize());
app.use(passport.session());
app.use(cors({
    credentials: true,
    origin: process.env.REACT_URL
}));
app.use(bodyParser.urlencoded({
extended: true
}));
app.use(bodyParser.json());

mongoose.set("strictQuery", true);

//Getting Contract abhi and assigning chain
const Contract = require(__dirname+"/NoobsTender.json")
const web3 = new Web3(process.env.CHAIN);

//Connecting to Database
mongoose.connect("mongodb+srv://sourabhchoudhary:"+ process.env.MONGO_PASSWORD +"@cluster0.hch1sgl.mongodb.net/Tenders");

//Assignning mongoose Schmeas

const CompanySchema = new mongoose.Schema({
    companyName: String,
    din: Number,
    bid: Number,
    address: String,
    transactionHash: String,
    tokenId: Number,
    tenderId: Number,
    ownerName:String,
    email: String,
    phoneNumber: Number,
})

const TenderSchema = new mongoose.Schema({
    TenderName : String,
    TenderId : Number,
    OpenTime : Number,
    transactionHash: String
})

const AdminData = new mongoose.Schema({
    username: String,
    password: String,
    token: String
})

//Adding passport local mongoose plugin
AdminData.plugin(passpoerLocalMongoose);

// Create monggose models

const Company = mongoose.model("Company", CompanySchema);
const Tender = mongoose.model("Tender", TenderSchema);
const Admin = mongoose.model("AdminData", AdminData);

// Creating passport strategy

passport.use(Admin.createStrategy());

//Serializing and Deserializing User


passport.serializeUser(function (user, done) {
    done(null, user.id);
  });
  passport.deserializeUser(function (id, done) {
    Admin.findById(id, function (err, user) {
      done(err, user);
    });
  });

//Assigning Abi for my contrat

const myContract = new web3.eth.Contract(Contract.abi, process.env.CONTRACTADDRESS, {
    from: process.env.NOOBSWALLET.toLowerCase()
}); 

//Function to convert text to hex

function hexEncode(company){
        var result = '';
        for (var i=0; i<company.length; i++) {
          result += company.charCodeAt(i).toString(16);
        }
        return result;
}

  //Route for registration of a company
app.post("/register", async function(req,res){
    res.header("Access-Control-Allow-Origin", process.env.REACT_URL);
    console.log("In");
    await web3.eth.accounts.wallet.add(process.env.PRIVATE_KEY);
    console.log(req.body.din.toString());
    await myContract.methods.register("0x"+hexEncode(req.body.company), "0x"+hexEncode(req.body.din.toString()), req.body.bid, req.body.address.toLowerCase()).send({from: process.env.NOOBSWALLET.toLowerCase(),gas:process.env.GAS})
    .then(async receipt=>{
        console.log(receipt);
        await myContract.methods.getTenderDetails().call()
        .then(receipt2=>{
            const company = new Company({
                companyName :req.body.company,
                din: req.body.din,
                bid: req.body.bid,
                address: req.body.address,
                transactionHash: receipt.logs[0].transactionHash,
                tokenId: Number(receipt2[Object.keys(receipt2)[2]]),
                tenderId: Number(receipt2[Object.keys(receipt2)[0]]),
                ownerName: req.body.ownerName,
                email: req.body.email,
                phoneNumber: req.body.phoneNumber
            });
            company.save();
            res.send({transactionHash:receipt.logs[0].transactionHash, tokenId: Number(receipt2[Object.keys(receipt2)[2]])});
        })
        .catch(err=>{
            console.log(err);
            res.send("Error!");
        })
    })
    .catch(err=>{
        console.log(err);
        res.send("Error!");
    });
});

//Route to start a tender process by admin

app.post("/startTender", async function(req,res){
    if(req.isAuthenticated()){
    await web3.eth.accounts.wallet.add(process.env.PRIVATE_KEY);
    await myContract.methods.startTendor("0x"+hexEncode(req.body.TenderName), req.body.TenderId, req.body.openTime).send({from: process.env.NOOBSWALLET.toLowerCase(), gas:process.env.GAS})
    .then(receipt=>{
        console.log(receipt);

        const tender = new Tender({
        TenderName: req.body.tenderName,
        TenderId : req.body.TenderId,
        OpenTime : req.body.openTime,
        transactionHash: receipt.transactionHash
        });
        tender.save();
        res.send(receipt.transactionHash);
    })
    .catch(err=>{
        console.log(err);
        res.send("Error!");
    });
}
})

//Route to get winner

app.get("/getWinner", async function(req,res){
    res.header("Access-Control-Allow-Origin", process.env.REACT_URL);
    console.log("In");
    await myContract.methods.getTenderDetails().call()
    .then(receipt=>{
        console.log(Number(receipt[Object.keys(receipt)[0]]));
        res.send({tenderId: Number(receipt[Object.keys(receipt)[0]]), winnerId: Number(receipt[Object.keys(receipt)[1]])});
    })
    .catch(err=>{
        console.log(err);
        res.send("Error");
    });
});

    //Route to get details about a token Id

app.get("/tenderDetails/:tokenId", async function(req,res){
    await Company.findOne({tokenId:req.params.tokenId})
    .then(response=>{
        res.send(response);
    })
    .catch(err=>{
        console.log(err);
        res.send("Error!!");
    });
});


    //Signup Route currently closed as there is only one login and password for admin
// app.post("/signup", function (req, res) {
//     Admin.register({
//       username: req.body.username
//     }, req.body.password, function (err, user) {
//       if (err) {
//         console.log(err);
//         res.send("Error!!");
//       } else {
//         passport.authenticate("local", { failureRedirect: process.env.REACT_URL + "/login" })(req, res, function () {
//           res.send("Registered")
//         });
//       }
//     });
//   });

    //Login  Route


  app.post("/login", function (req, res) {
    const user = new Admin({
      username: req.body.username,
      password: req.body.password
    });
    req.login(user, function (err) {
      if (err) {
        res.send(false)
      } else {
        passport.authenticate("local", { failureRedirect: process.env.REACT_URL + "/login" })(req, res, function () {
          res.send(true)
        });
      }
    });
  });

const port=8282||process.env.PORT;
app.listen(port,function(){
    console.log("server running at port: "+port);
});

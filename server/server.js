const express = require('express');
const app = express();
var moment = require('moment');
moment().format();
var Mta = require('mta-gtfs');
var config = require('./config');
var mta = new Mta(config);

var mta_stations = require('./mta_stations.json');

var cache = {
	"arrivals":{}
};

var mta_lines = {
	// north to south
	// todo: for A express it needs to skip stations
	"A":["A02", "A03", "A05", "A06", "A07", "A09", "A10", "A11", "A12", "A14", "A15", "A16", "A17", "A18", "A19", "A20", "A21", "A22", "A24", "A25", "A27", "A28", "A30", "A31", "A32", "A33", "A34", "A36", "A38", "A40", "A41", "A42", "A43", "A44", "A45", "A46", "A47", "A48", "A49", "A50", "A51", "A52", "A53", "A54", "A55", "A57", "A59", "A60", "A61", "A63", "A64", "A65"],
	// C train from 168 st. to Euclid
	"C":["A09", "A10", "A11", "A12", "A14", "A15", "A16", "A17", "A18", "A19", "A20", "A21", "A22", "A24", "A25", "A27", "A28", "A30", "A31", "A32", "A33", "A34", "A36", "A38", "A40", "A41", "A42", "A43", "A44", "A45", "A46", "A47", "A48", "A49", "A50", "A51", "A52", "A53", "A54", "A55"],
	// G from Queens to south Brooklyn
	"G":["G22", "G24", "G26", "G28", "G29", "G30", "G31", "G32", "G33", "G34", "G35", "G36", "A42", "F20", "F21", "F22", "F23", "F24", "F25", "F26", "F27"],
	// L train from Manhattan 8th ave to Bushwick
	"L":["L01", "L02", "L03", "L05", "L06", "L08", "L10", "L11", "L12", "L13", "L14", "L15", "L16", "L17", "L19", "L20", "L21", "L22", "L24", "L25", "L26", "L27", "L28", "L29"]
};


// returns an array of trains ["G","A","C"] that visit provided station
function trainsAtStation(stationID){
	var trains = [];
	var lineKeys = Object.keys(mta_lines);
	for(var i = 0; i < lineKeys.length; i++){
		var key = lineKeys[i];
		if(mta_lines[ key ].includes(stationID)){ trains.push(key); }
	}
	return trains;
}

// array of MTA stations sorted near to far to the provided location, up to #count
function stationsCloseTo(latitude, longitude, count){
	if(count == undefined){ count = 20; }
	if(count <= 0){ count = 1; }
	return Object.values(mta_stations)
		.filter(function(el){return el.parent_station === "";})
		.sort(function(a,b){
			var aLat = latitude - parseFloat(a.stop_lat);
			var aLon = longitude - parseFloat(a.stop_lon);
			var bLat = latitude - parseFloat(b.stop_lat);
			var bLon = longitude - parseFloat(b.stop_lon);
			var aDist = Math.sqrt(Math.pow(aLat, 2) + Math.pow(aLon,2));
			var bDist = Math.sqrt(Math.pow(bLat, 2) + Math.pow(bLon,2));
			return aDist - bDist;
		}).slice(0,count);
}

function prevStation(station, train, direction){
	var stations = mta_lines[train];
	if (stations === undefined){ return undefined; }
	var result = undefined;
	var index = stations.findIndex(function(el){ return el === station; });
	if(index === -1){ return undefined; }
	// if index is out of bounds result will be undefined
	switch(direction){
		case "N": result = stations[ index + 1 ]; break;
		case "S": result = stations[ index - 1 ]; break;
	}
	return result;
}

function nextStation(station, train, direction){
	var stations = mta_lines[train];
	if (stations === undefined){ return undefined; }
	var result = undefined;
	var index = stations.findIndex(function(el){ return el === station; });
	if(index === -1){ return undefined; }
	// if index is out of bounds result will be undefined
	switch(direction){
		case "N": result = stations[ index - 1 ]; break;
		case "S": result = stations[ index + 1 ]; break;
	}
	return result;
}


// mta.stop().then(function (result) {
//   console.log(result);
// }).catch(function (err) {
//   console.log(err);
// });

// mta.stop('L14').then(function (result) {
//   console.log(result);
// });

// mta.schedule('L14', 2).then(function (result, error) {
//   console.log(result);
//   console.log(error);
// });

// expecting query: /location?latitude=40.7347179&longitude=-73.9911541
app.get('/location', (req,res) => {
	if(req.query !== undefined && req.query.latitude !== undefined && req.query.longitude !== undefined){
		var latitude = parseFloat(req.query.latitude);
		var longitude = parseFloat(req.query.longitude);
		if(isNaN(latitude) || isNaN(longitude)){
			res.json({"error":"please provide a proper query string with latitude and longitude: /location?latitude=40.7347179&longitude=-73.9911541"});
			return;
		}
		var closeStations = stationsCloseTo(latitude, longitude, 3);

		// var northbound = {};
		// closeStations.forEach(function(el){
		// 	var stationID = el["stop_id"];
		// 	var trainArray = trainsAtStation(stationID);
		// 	northbound[ stationID ] = trainArray.map(function(train){
		// 		var neighbors = {};
		// 		neighbors[train] = {
		// 			"prev" : prevStation(stationID, train, "N"),
		// 			"next" : nextStation(stationID, train, "N")
		// 		};
		// 		return neighbors;
		// 	});
		// });
		// closeStations.forEach(function(el){
		// 	getMTAandPredictTrainLocations(el);
		// });
		// res.json({"N":northbound, "stations":closeStations, "id":stopIDs});

		var stopIDs = closeStations.map(function(el){
			return el["stop_id"];
		});

		var neighbors = {};

		closeStations.map(function(el){ return el["stop_id"];})
			.forEach(function(stationID){
				neighbors[stationID] = {"N":{},"S":{}};
				trainsAtStation(stationID).forEach(function(train){
					neighbors[stationID]["N"][train] = {
						["prev"] : prevStation(stationID, train, "N"),
						["next"] : nextStation(stationID, train, "N")
					}
					neighbors[stationID]["S"][train] = {
						["prev"] : prevStation(stationID, train, "S"),
						["next"] : nextStation(stationID, train, "S")
					}
				});
			});

		// neighborhood stations includes all near stations, and their prev and next stations
		var hood = stopIDs.slice();

		Object.keys(neighbors).forEach(function(stationID) {
			Object.keys(neighbors[stationID]["N"]).forEach(function(train){
				hood.push(neighbors[stationID]["N"][train]["prev"]);
				hood.push(neighbors[stationID]["N"][train]["next"]);
			});
			Object.keys(neighbors[stationID]["S"]).forEach(function(train){
				hood.push(neighbors[stationID]["S"][train]["prev"]);
				hood.push(neighbors[stationID]["S"][train]["next"]);
			});
		});
		// remove duplicates
		hood = hood.filter(function(item, pos, self) {
			return self.indexOf(item) == pos;
		})


		res.json({"hood":hood, "neighbors":neighbors, "stations":closeStations, "id":stopIDs});

		// var neighbors = stopIDs.map(function(el){
		// 	var trainArray = trainsAtStation(el);
		// 	var obj = {"N":{},"S":{}};
		// 	obj[el]["N"] = trainArray.map(function(train){
		// 		var innerObj = {};
		// 		innerObj[train] = {
		// 			"prev" : prevStation(el, train, "N"),
		// 			"next" : nextStation(el, train, "N")
		// 		};
		// 		return innerObj;
		// 	}).reduce(function(acc, cur, i) {
		// 		acc[i] = cur;
		// 		return acc;
		// 	}, {});
		// 	obj[el]["S"] = trainArray.map(function(train){
		// 		var innerObj = {};
		// 		innerObj[train] = {
		// 			"prev" : prevStation(el, train, "S"),
		// 			"next" : nextStation(el, train, "S")
		// 		};
		// 		return innerObj;
		// 	}).reduce((obj, [key, value]) => (
		// 		Object.assign(obj, { [key]: value })
		// 	), {});
		// 	return obj;
		// }).reduce((obj, [key, value]) => (
		// 	Object.assign(obj, { [key]: value })
		// ), {});
		// res.json({"neighbors":neighbors, "stations":closeStations, "id":stopIDs});
	}
});

app.get('/status', (req,res) => {
	mta.status().then(function(result){
		res.json(result);
	});
});

app.get('/stops', (req,res) => {
	mta.stop().then(function (result) {
		res.json(result);
	}).catch(function (err) {
		console.log(err);
	});
});

app.get('/query', (req,res) => {
	res.json({"query":req.query});
});

app.get('/live', (req,res) => {
	var queryString = req.query.stations;
	var stationArray = [];
	if(queryString != undefined && queryString.length > 0){
		var queryArray = queryString.split(',');
		var printString = "";
		var stations = queryArray.map(function(el){
			return mta_stations[el];
		});

		stations.forEach(function(el){
			var newString = el.stop_name + ": " + el.stop_lat + ", " + el.stop_lon + "\n";
			printString += newString;
		});

		// res.json({});
		// res.json(mta_stations);
		// for(stationName in queryArray){
		// 	var mtaStation = mta_stations[stationName];
		// 	stationArray.push(mta_stations[stationName])
		// 	if(mtaStation != undefined){
		// 		printString += mtaStation.stop_name + ": " + mtaStation.stop_lat + ", " + mtaStation.stop_lon + "\n";
		// 	}
		// }
		res.json({"stations":stations,"string":printString, "array":queryArray,"mta":mta_stations});
	}
});

app.get('/A46', (req,res) => {
	if(cache.arrivals["A46"] !== undefined){
		var schedule = cache.arrivals["A46"];
		res.json({"schedule":schedule, "now":moment.unix(Math.round((new Date()).getTime() / 1000)).format("MMMM Do YYYY, h:mm:ss a")});
	} else{
		mta.schedule('A46', 26).then(function (result, error) {
			var schedule = result.schedule.A46
			schedule["fetch"] = Math.round((new Date()).getTime() / 1000);
			cache.arrivals["A46"] = schedule;
			res.json({"schedule":schedule, "now":moment.unix(Math.round((new Date()).getTime() / 1000)).format("MMMM Do YYYY, h:mm:ss a")});
		});
	}
});


app.get('/L14', (req,res) => {
	mta.schedule('L14', 2).then(function (result, error) {
		// console.log(result);
		// console.log(error);
		var arrivals = [];
		// res.json(result);
		// console.log(result);
		var times = result.schedule.L14.N.map(function(el){
			return moment.unix(el.arrivalTime).format("MMMM Do YYYY, h:mm:ss a");
		});
		// console.log(times);
		res.json(times);
		// result.schedule.L14.S
	});
});


app.get('/', (req,res) => res.send('Hello'));

app.get('/test', (req,res) => {
	console.log(req);
	// res.write('some test');
	// res.write(req.query.say);
	// res.send(200);
	const reply = {one:1, two:2};
	res.json(reply);
})
// app.listen(3000, () => console.log('example is running on 3000'));


app.listen(process.env.PORT || 3000, function(){
	console.log("listening");
});

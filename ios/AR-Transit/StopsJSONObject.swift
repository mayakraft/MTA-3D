//
//  StopsJSONObject.swift
//  AR-Transit
//
//  Created by Robby on 1/25/18.
//  Copyright © 2018 Robby Kraft. All rights reserved.
//

import Foundation

//{
//"stop_id": "101",
//"stop_code": "",
//"stop_name": "Van Cortlandt Park - 242 St",
//"stop_desc": "",
//"stop_lat": "40.889248",
//"stop_lon": "-73.898583",
//"zone_id": "",
//"stop_url": "",
//"location_type": "1",
//"parent_station": ""
//}

struct StationJSON:Decodable{
	var stop_id:String
	var stop_code:String
	var stop_name:String
	var stop_desc:String
	var stop_lat:String
	var stop_lon:String
	var zone_id:String
	var stop_url:String
	var location_type:String
	var parent_station:String
}

struct Station:Decodable{
	var stop_id:String
	var stop_code:String
	var stop_name:String
	var stop_desc:String
	var stop_lat:Double
	var stop_lon:Double
	var zone_id:String
	var stop_url:String
	var location_type:String
	var parent_station:String
}


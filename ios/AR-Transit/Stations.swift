//
//  Stations.swift
//  AR-Transit
//
//  Created by Robby on 1/25/18.
//  Copyright © 2018 Robby Kraft. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class Stations {
	
	static let shared = Stations()
	
	var stations:[Station]?
	var sortedStations:[Station]?

	var myLocation:CLLocation?{
		didSet{
			if let s = self.stations, let location = myLocation{
				self.sortedStations = s.sorted(by: { (a:Station, b:Station) -> Bool in
					let aLat = location.coordinate.latitude - a.stop_lat
					let aLon = location.coordinate.longitude - a.stop_lon
					let bLat = location.coordinate.latitude - b.stop_lat
					let bLon = location.coordinate.longitude - b.stop_lon
					let aDist = sqrt(pow(aLat, 2) + pow(aLon,2))
					let bDist = sqrt(pow(bLat, 2) + pow(bLon,2))
					return aDist < bDist
				})
			}
		}
	}
	
	fileprivate init(){
		
	}

}


class StationAnnotation: NSObject, MKAnnotation {
	let title: String?
	let locationName: String
	let discipline: String
	let coordinate: CLLocationCoordinate2D
	
	init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D) {
		self.title = title
		self.locationName = locationName
		self.discipline = discipline
		self.coordinate = coordinate
		super.init()
	}
}

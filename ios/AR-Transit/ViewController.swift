//
//  ViewController.swift
//  BusAR
//
//  Created by Robby on 11/15/17.
//  Copyright © 2017 Robby Kraft. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import GLKit
import ImageIO

extension Double {
	func rounded(toPlaces places:Int) -> Double {
		let divisor = pow(10.0, Double(places))
		return (self * divisor).rounded() / divisor
	}
}

class ViewController: GLKViewController, VideoFeedDelegate, PanoramaDelegate{

	let locationManager = CLLocationManager()
	let mapView = MKMapView()
//	let label = UILabel()
	
	let regionRadius: CLLocationDistance = 200

	var timer:Timer?
	
	let panoramaView = PanoramaView()
	
	var videoFeed:VideoFeed!
	var previewView = UIView()
	
	let openCV = OpenCVClass()
	
	let mapScrollView = UIScrollView()
	
	let labelView = UIView()

	var locationGPS:CLLocation?{
		willSet(newLocation){
			if self.locationGPS == nil{
				print("setting initial location")
				if let location = newLocation{
					self.centerMapOnLocation(location: location)
				}
			}
		}
		didSet{
			if let loc = locationGPS{
				Stations.shared.myLocation = loc
				
				let annotations = Stations.shared.sortedStations?.prefix(upTo: 15)
					.map({ (station) -> StationAnnotation in
						return StationAnnotation(title: station.stop_name, locationName: station.stop_code, discipline: "", coordinate: CLLocationCoordinate2D(latitude: station.stop_lat, longitude: station.stop_lon))
					})
				mapView.addAnnotations(annotations!)
				
				let locations = annotations!.map({ (annotation) -> XYPoint in
					let dLat = loc.coordinate.latitude - annotation.coordinate.latitude
					let dLon = loc.coordinate.longitude - annotation.coordinate.longitude
					let scale = 500.0
					return XYPoint(x: dLat * scale, y: dLon * scale)
				})
				// north
//				let dLat = loc.coordinate.latitude - (loc.coordinate.latitude+0.001)
//				let dLon = loc.coordinate.longitude - (loc.coordinate.longitude)
				// east
//				let dLat = loc.coordinate.latitude - (loc.coordinate.latitude)
//				let dLon = loc.coordinate.longitude - (loc.coordinate.longitude+0.001)
//				let scale = 10000.0
//				let locations = [XYPoint(x: dLat * scale, y: dLon * scale)]
				self.panoramaView?.stationLocations = locations
			}
//			if let location = locationGPS{
//				let latitude = location.coordinate.latitude
//				let longitude = location.coordinate.longitude
//				self.label.text = "\(latitude.rounded(toPlaces: 5)) \(longitude.rounded(toPlaces: 5))"
//				self.label.sizeToFit()
//				self.label.center = self.view.center
//			}
		}
	}
	
	func screenLocationsDidUpdate(_ screenLocations: [Any]!) {
		for subview in labelView.subviews{
			subview.removeFromSuperview()
		}
		
		let screenBounds = UIScreen.main.bounds
		if Stations.shared.sortedStations != nil{
			for i in 0..<screenLocations.count{
				let name = Stations.shared.sortedStations![i].stop_name
				let xypoint:XYPoint = screenLocations[i] as! XYPoint
				let point:CGPoint = CGPoint(x: xypoint.x, y: xypoint.y)
				if screenBounds.contains(point){
					let label = UILabel()
					label.textColor = .white
					label.text = name
					label.sizeToFit()
					labelView.addSubview(label)
					label.center = point
				}
			}
		}
		
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
//		let size = UIScreen.main.nativeScale
		
		self.view = panoramaView
		panoramaView?.setImage(UIImage(named: "equirectangular-projection-lines.png"))
//		panoramaView?.setRectImage(UIImage(named: "white.png"))
		panoramaView?.orientToDevice = true
		panoramaView?.pinchToZoom = true
		panoramaView?.panoDelegate = self
		
		self.previewView.backgroundColor = .clear
		self.previewView.frame = UIScreen.main.bounds
//		self.view.addSubview(self.previewView)
		
		self.videoFeed = VideoFeed()
		self.videoFeed.delegate = self
		self.videoFeed.previewLayer.frame = previewView.bounds
		previewView.layer.addSublayer(self.videoFeed.previewLayer)

		////////////////////////////////////////////
		
		
		let stationJSONURL:URL = Bundle.main.url(forResource: "stops.json", withExtension: nil)!
		do{
			let stationData:Data = try Data(contentsOf: stationJSONURL)
			do{
				let stationJson = try JSONDecoder().decode([StationJSON].self, from: stationData)
				Stations.shared.stations = stationJson.map({ (json) -> Station in
					return Station.init(stop_id: json.stop_id, stop_code: json.stop_code, stop_name: json.stop_name, stop_desc: json.stop_desc, stop_lat: Double(json.stop_lat)!, stop_lon: Double(json.stop_lon)!, zone_id: json.zone_id, stop_url: json.stop_url, location_type: json.location_type, parent_station: json.parent_station)
				}).filter({ (station) -> Bool in
					return station.parent_station == ""
				})
			} catch{
				
			}
		} catch{
			
		}


		locationManager.requestWhenInUseAuthorization()
		locationManager.distanceFilter = kCLDistanceFilterNone;
		locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
		locationManager.startUpdatingLocation()

		
		
		labelView.frame = UIScreen.main.bounds
		labelView.backgroundColor = .clear
		self.view.addSubview(labelView)
		
		
		var vmin = self.view.bounds.size.width
		let mapW = vmin * 0.66
		if self.view.bounds.size.height < self.view.bounds.size.width { vmin = self.view.bounds.size.height }
		
		mapScrollView.frame = CGRect(x: 0, y: self.view.frame.size.height - mapW, width: self.view.frame.size.width, height: mapW)
		mapScrollView.contentSize = CGSize(width: self.view.frame.size.width, height: mapW*2)
		mapScrollView.isPagingEnabled = true
		self.view.addSubview(mapScrollView)

		mapView.frame = CGRect(x: 0, y: 0, width: mapW, height: mapW)
		mapView.center = CGPoint(x: self.view.frame.size.width*0.5, y: mapW*1.5)
		mapView.showsUserLocation = true
		self.mapScrollView.addSubview(mapView)
		

//		self.view.addSubview(label)
//		self.label.textColor = .black
//		self.label.text = "Latitude Longitude"
//		self.label.textAlignment = .center
//		self.label.sizeToFit()
//		self.label.center = self.view.center
		
		self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(loop), userInfo: nil, repeats: true)
		
		Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { (timer) in
			print(Stations.shared.sortedStations!)
		}
		
		
	}
	
	override func glkView(_ view: GLKView, drawIn rect: CGRect) {
		panoramaView?.draw()
	}

//	func re(size:CGSize, uiImage:UIImage) -> UIImage?{
//		uiImage.size.applying(CGAffineTransform(scaleX: size.width / uiImage.size.width, y: size.height / uiImage.size.height))
//		let hasAlpha = true
//		let scale: CGFloat = 0.0
//		UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
//		uiImage.draw(in: CGRect(origin: CGPoint(x:0, y:0), size: size))
//		let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
//		UIGraphicsEndImageContext()
//		return scaledImage
//	}

	func frame(image: CGImage) {
		let textureSize = CGSize(width:512, height:1024)
		if let scaledImage = openCV.resize(textureSize, cgImage: image){
			self.panoramaView?.setTexture(scaledImage.takeUnretainedValue())
		}
	}
	
	func captured(image: UIImage) { }
	
	@objc func loop(){
		if let location = self.locationManager.location{
			self.locationGPS = location
		}
	}

	func centerMapOnLocation(location: CLLocation) {
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
		mapView.setRegion(coordinateRegion, animated: true)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

}


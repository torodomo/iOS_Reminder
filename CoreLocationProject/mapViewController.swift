//
//  mapViewController.swift
//  CoreLocationProject
//
//  Created by Toro Roan on 9/14/17.
//  Copyright © 2017 Eat_JR. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation
import UserNotifications


class MapViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var locLabel: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var startup: Bool = false
    
    let locationManager = CLLocationManager()
    
    weak var delegate: MapViewDel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in }
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
    }
    
    @IBAction func searchButton(_ sender: Any) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self as UISearchBarDelegate
        present(searchController, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        
        self.view.addSubview(activityIndicator)
        
        //Hide Search Bar
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        //Create Search Request
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        
        activeSearch.start { (response, error) in
            
            activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            if response == nil
            {
                print ("error")
            }
            else
            {
                // Remove Annotations
                let annotations = self.mapView.annotations
                self.mapView.removeAnnotations(annotations)
                
                //Getting Data
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                // Create Annotaitions
                let annotation = MKPointAnnotation()
                annotation.title = searchBar.text
                annotation.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                self.mapView.addAnnotation(annotation)
                
                let area = CLCircularRegion(center: annotation.coordinate, radius: 50, identifier: "geofence")
                
                self.mapView.removeOverlays(self.mapView.overlays)
                self.locationManager.startMonitoring(for: area)
                let circle = MKCircle(center: annotation.coordinate, radius: area.radius)
                self.mapView.add(circle)
                
                //Zooming in on annotation
                let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude!, longitude!)
                let span = MKCoordinateSpanMake(0.1, 0.1)
                let region = MKCoordinateRegionMake(coordinate, span)
                self.mapView.setRegion(region, animated: true)
                
                let location = CLLocation(latitude: latitude!, longitude: longitude!)
                
                CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (loc, error) in
                    if let data = loc?[0]{
                        self.locLabel.text = data.subThoroughfare! + " " + data.thoroughfare! + " " + data.locality! + " " + data.administrativeArea! + " " + data.postalCode!
                        self.delegate?.addLocation(by: self, with: self.locLabel.text)
                    }
                })
                
            }
        }
        
        
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Clear", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.badge = 1
        content.sound = .default()
        let request = UNNotificationRequest(identifier: "notif", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
}


extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
        if !startup{
            let location = locations[locations.count - 1]
            mapView.setRegion(MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500), animated: false)
            startup = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let title = "Reminder"
        let message = "Stuff you need to do"
        showAlert(title: title, message: message)
        showNotification(title: title, message: message)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let title = "Reminder"
        let message = "Have you completed it?"
        showAlert(title: title, message: message)
        showNotification(title: title, message: message)
    }
    
    
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circleOverlay = overlay as? MKCircle
            else {
                return MKOverlayRenderer()
            }
        let circleRenderer = MKCircleRenderer(circle: circleOverlay)
        circleRenderer.strokeColor = .blue
        circleRenderer.fillColor = .blue
        circleRenderer.alpha = 0.5
        return circleRenderer
    }
}

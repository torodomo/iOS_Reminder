//
//  MainViewController.swift
//  bucketList3
//
//  Created by Andrew Lau on 9/13/17.
//  Copyright © 2017 Andrew Lau. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import MapKit
import UserNotifications
import UserNotificationsUI
import AVFoundation
import AudioToolbox



class MainViewController: UITableViewController, AddItemDel, CLLocationManagerDelegate, MKMapViewDelegate, UNUserNotificationCenterDelegate {
    
    let requestIdentifier = "SampleRequest" //identifier is to cancel the notification request
    
    let locationManager = CLLocationManager()
    var bucket = [Tasks]()
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var startUp: Bool = false
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in }
        findAllItems()
        allTaskLocater()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        animatTable()
    }
    
    func animatTable() {
        
        self.tableView.reloadData()
        
        let cells = tableView.visibleCells
        let tableHeight: CGFloat = tableView.bounds.size.height
        
        for (index,cell) in cells.enumerated() {
            cell.transform = CGAffineTransform(translationX: 0, y: tableHeight)
            UIView.animate(withDuration: 1.0, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                cell.transform = CGAffineTransform(translationX: 0, y: 0);
            }, completion: nil)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bucket.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bucketCell", for: indexPath)
        cell.textLabel?.text = bucket[indexPath.row].name!
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddItem"{
            let navigationController = segue.destination as! UINavigationController
            let addItemViewController = navigationController.topViewController as! AddItemViewController
            addItemViewController.delegate = self
            
            if let indexPath = sender{
                let index = indexPath as! NSIndexPath
                let item = bucket[index.row]
            
                addItemViewController.indexPath = index
                addItemViewController.item = item.name!
                addItemViewController.note = item.notes!
                addItemViewController.sound = Int(item.sound)
                addItemViewController.loc = item.location!
                
                addItemViewController.navigationItem.title = "Details"
            }
        }
    }
    
    func cancelButtonPressed(by controller: AddItemViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func savePressedbutton(by controller: AddItemViewController, name: String, location: String, sound: Int, notes: String?, from indexPath: NSIndexPath?) {
        if let index = indexPath{
            let items = bucket[index.row]
            items.name = name
            items.sound = Int32(sound)
            items.location = location
            items.notes = notes
        }
        else{
            let items = NSEntityDescription.insertNewObject(forEntityName: "Tasks", into: managedObjectContext) as! Tasks
            items.name = name
            items.sound = Int32(sound)
            items.location = location
            items.notes = notes
            bucket.append(items)
            
        }
        do {
            try managedObjectContext.save()
        } catch {
            print ("\(error)")
        }

        tableView.reloadData()
        allTaskLocater()
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetail", sender: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete =  UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let item = self.bucket[indexPath.row]
            self.managedObjectContext.delete(item)
            
            do{
                try self.managedObjectContext.save()
            } catch {
                print("\(error)")
                
            }
            self.bucket.remove(at: indexPath.row)
            tableView.reloadData()
            self.allTaskLocater()
            self.animatTable()
        }
        let edit = UITableViewRowAction(style: .default, title: "More") { (action, indexPath) in
            self.performSegue(withIdentifier: "AddItem", sender: indexPath)
            
            tableView.reloadData()
            self.allTaskLocater()
        }
        edit.backgroundColor = UIColor.lightGray
        return [delete, edit]
    }
    
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "AddItem", sender: nil)
    }
    
    func findAllItems() {
        let itemRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tasks")
        do {
            let results = try managedObjectContext.fetch(itemRequest)
            bucket = results as! [Tasks]
            
        } catch {
            print("\(error)")
        }
    }
    
    func allTaskLocater(){
        let allAnnotations = mapView.annotations
        mapView.removeAnnotations(allAnnotations)
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
        
        for task in bucket{
            if let location = task.location {
                CLGeocoder().geocodeAddressString(location) { (data, error) in
                    
                    if let d = data?[0] {
                        let loc = CLLocationCoordinate2DMake((d.location?.coordinate.latitude)!, (d.location?.coordinate.longitude)!)
                       // let span = MKCoordinateSpanMake(0.01, 0.01)
                        //let region = MKCoordinateRegion(center: loc, span: span)  //need to zoom in on current location instead
                        
                        let dropPin = MKPointAnnotation()
                        dropPin.coordinate = loc
                        dropPin.title = task.name
                        dropPin.subtitle = task.location
                        
                        let area = CLCircularRegion(center: dropPin.coordinate, radius: 500, identifier: "geofence")
                        
                        self.locationManager.startMonitoring(for: area)
                        let circle = MKCircle(center: dropPin.coordinate, radius: area.radius)
                        self.mapView.addAnnotation(dropPin)
                        self.mapView.add(circle)

                    }
                }
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.startUpdatingLocation()
        if startUp == false{
            mapView.showsUserLocation = true
            let location = locations[0]
            mapView.setRegion(MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500), animated: false)
            startUp = true
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let title = "Reminder"
        let message = "There is stuff you need to do!"
        showAlert(title: title, message: message)
        triggerNotification(title: title, message: message)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let title = "Reminder"
        let message = "Delete completed remiders"
        print(manager)
        showAlert(title: title, message: message)
        triggerNotification(title: title, message: message)
    }
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
//    func showNotification(title: String, message: String) {
//        let content = UNMutableNotificationContent()
//        content.title = title
//        content.body = message
//        content.badge = 1
//        content.sound = .default()
//        let request = UNNotificationRequest(identifier: "notif", content: content, trigger: nil)
//        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
//    }

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
    
    func triggerNotification(title: String, message: String){
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.badge = 1
        content.sound = .default()
        
        // Deliver the notification in five seconds.
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5.0, repeats: false)
        let request = UNNotificationRequest(identifier:requestIdentifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().add(request){(error) in
        }
    }
    
    @IBAction func stopNotification(_ sender: AnyObject) {
        
        print("Removed all pending notifications")
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
        
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("Tapped in notification")
    }
    
    //This is key callback to present notification while the app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("Notification being triggered")
        //You can either present alert ,sound or increase badge while the app is in foreground too with ios 10
        //to distinguish between notifications
        if notification.request.identifier == requestIdentifier{
            
            completionHandler( [.alert,.sound,.badge])
            
        }
    }
}

//
//  AddItemViewController.swift
//  bucketList3
//
//  Created by Andrew Lau on 9/13/17.
//  Copyright © 2017 Andrew Lau. All rights reserved.
//

import UIKit
import CoreData
import MapKit



class AddItemViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate, MapViewDel {

    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var locationField: UITextField!
    
    @IBOutlet weak var soundLabel: UIPickerView!
    @IBOutlet weak var noteField: UITextField!
    
    let sounds = ["Alarm", "Calypso","Spell", "Typewriters"]
    let soundsInt = [1005,1022,1032,1035]
    
    var delegate: AddItemDel?
    var item: String?
    var loc: String?
    var note: String?
    var sound: Int?
    var indexPath: NSIndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameField.text = item
        locationField.text = loc
        noteField.text = note
        soundLabel.dataSource = self
        soundLabel.delegate = self
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

    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.cancelButtonPressed(by: self)
    }
    
    @IBAction func savePressedButton(_ sender: UIBarButtonItem) {
        delegate?.savePressedbutton(by: self, name: nameField.text!, location: locationField.text!, sound: soundsInt[soundLabel.selectedRow(inComponent: 0)],notes: noteField.text, from: indexPath)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sounds[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sounds.count
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let mapView = segue.destination as! MapViewController
        mapView.delegate = self
    }
    
    func addLocation(by controller: MapViewController, with data: String?) {
        locationField.text = data
    }
}

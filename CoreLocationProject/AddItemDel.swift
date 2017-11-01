//
//  AddItemDel.swift
//  bucketList3
//
//  Created by Andrew Lau on 9/13/17.
//  Copyright © 2017 Andrew Lau. All rights reserved.
//

import UIKit

protocol AddItemDel: class {
    func cancelButtonPressed(by controller: AddItemViewController)
    func savePressedbutton(by controller: AddItemViewController, name: String, location: String, sound: Int, notes: String?, from indexPath: NSIndexPath?)
}

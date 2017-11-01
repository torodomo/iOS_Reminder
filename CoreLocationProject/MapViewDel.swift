//
//  MapViewDel.swift
//  CoreLocationProject
//
//  Created by Andrew Lau on 9/14/17.
//  Copyright © 2017 Eat_JR. All rights reserved.
//

import UIKit

protocol MapViewDel: class {
    func addLocation(by controller: MapViewController,with data: String?)
}

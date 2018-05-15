//
//  CWFMapViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 7/7/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class CWFMapViewController: CWFBaseViewController, MKMapViewDelegate {

    let mapView = MKMapView()
    var addressToDisplay : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = NSLocalizedString("Map", comment: "map")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismiss(_:)))

        mapView.mapType = .standard
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        
        self.view.addSubview(mapView)
        
        let xConstraint = NSLayoutConstraint(item: mapView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: mapView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let hConstraint = NSLayoutConstraint(item: mapView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        let wConstraint = NSLayoutConstraint(item: mapView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        
        view.addConstraints([xConstraint, yConstraint, hConstraint, wConstraint])
        
        setupAddress()
    }
    
    func setupAddress() {
        let addressAsString = addressToDisplay[0] + ", " + addressToDisplay[1]
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(addressAsString) { [weak self] placemarks, error in
            if error == nil {
                if let placemark = placemarks?.first, let location = placemark.location {
                    let mark = MKPlacemark(placemark: placemark)
                    if var region = self?.mapView.region {
                        region.center = location.coordinate
                        region.span.longitudeDelta /= 1000.0
                        region.span.latitudeDelta /= 1000.0
                        self?.mapView.setRegion(region, animated: true)
                        self?.mapView.addAnnotation(mark)
                    }
                }
            }
            else {
                let errorAlert = UIAlertController(title: NSLocalizedString("Location Not Found", comment: "no location"), message:NSLocalizedString("Maps could not find the location \n\(addressAsString)", comment: "could not find location"), preferredStyle: .alert)
                let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
                errorAlert.addAction(okAction)
                
                self?.present(errorAlert, animated: true, completion: nil)
            }
        }
        
//        let dropPin = MKPointAnnotation()
//        dropPin.coordinate = CLLocationCoordinate2DMake(40.730, -74.003)
//        dropPin.title = "Here you go"
//
//        mapView.addAnnotation(dropPin)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismiss(_ sender:UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }


}

//
//  ViewController.swift
//  Escort Client
//
//  Created by Viet Hong Nguyen on 4/22/19.
//  Copyright © 2019 Viet Hong Nguyen. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import PusherSwift
import UserNotifications
import GooglePlaces

class ViewController: UIViewController, GMSMapViewDelegate {
    
    let pusher = Pusher(
        key: AppConstants.PUSHER_KEY,
        options: PusherClientOptions(host: .cluster(AppConstants.PUSHER_CLUSTER))
    )
    
    var latitude = 42.2520
    var longitude = -71.8234
    var eta = ""
    
    /*
    var latitude = 42.2595
    var longitude = -71.8261
    */
    //BigY
    var dest_latitude = 42.2595
    var dest_longitude = -71.8261
    
    var locationMarker: GMSMarker!
    
    //MARK: Outlets
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingOverlay: UIView!
    
    
    @IBOutlet weak var orderButton: UIButton!
    @IBOutlet weak var orderStatusView: UIView!
    @IBOutlet weak var orderStatus: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var driverDetailsView: UIView!
    @IBOutlet weak var ETA: UILabel!
    
    @IBOutlet weak var destination: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.camera = GMSCameraPosition.camera(withLatitude:latitude, longitude:longitude, zoom:15.0)
        mapView.delegate = self
        locationMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        locationMarker.map = mapView
        
        orderStatusView.layer.cornerRadius = 5
        orderStatusView.layer.shadowOffset = CGSize(width: 0, height: 0)
        orderStatusView.layer.shadowColor = UIColor.black.cgColor
        orderStatusView.layer.shadowOpacity = 0.3
        
        updateView(status: .Neutral, msg: nil)
        listenForUpdates()
    }
    
    @IBAction func destinationPressed(_ sender: Any) {
        destination.resignFirstResponder()
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        present(acController, animated: true, completion: nil)
    }
    
    
    @IBAction func orderButtonPressed(_ sender: Any) {
        updateView(status: .Searching, msg: nil)
        
        if (inServiceRange(latitude: latitude, longtitude: longitude)){
            sendRequest(.post) { successful in
                guard successful else {
                    return self.updateView(status: .Neutral, msg: "No drivers available.")
                }
            }
        }
        else{
            return self.updateView(status: .Neutral, msg: "Sorry, you are out of the service range.")
        }
        
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        sendRequest(.delete) { successful in
            guard successful == false else {
                return self.updateView(status: .Neutral, msg: nil)
            }
        }
    }
    
    private func inServiceRange(latitude: Double, longtitude: Double) -> Bool {
        if (latitude > 42.2520 + 0.0106 || latitude < 42.2520 - 0.0106 || longtitude > -71.8234 + 0.0106 || longtitude < -71.8234 - 0.0106){
            return false
        }
        else{
            return true
        }
    }
    
    private func updateView(status: RideStatus, msg: String?) {
        switch status {
        case .Neutral:
            driverDetailsView.isHidden = true
            loadingOverlay.isHidden = true
            orderStatus.text = msg != nil ? msg! : "Tap the button below to get an escort."
            orderButton.setTitleColor(UIColor.white, for: .normal)
            orderButton.isHidden = false
            cancelButton.isHidden = true
            loadingIndicator.stopAnimating()
            
        case .Searching:
            loadingOverlay.isHidden = false
            orderStatus.text = msg != nil ? msg! : "Please hold, dispatching to escort..."
            orderButton.setTitleColor(UIColor.clear, for: .normal)
            loadingIndicator.startAnimating()
            
        case .FoundRide, .Arrived:
            driverDetailsView.isHidden = false
            loadingOverlay.isHidden = true
            
            if status == .FoundRide {
                //notification
                let content = UNMutableNotificationContent()
                content.title = "Ride Status Update"
                content.subtitle = "from PlzHold"
                content.body = "Your ride is on it's way"
                let trigger  = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: "notifictaion.id.01", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                
                orderStatus.text = msg != nil ? msg! : "Your ride is on it's way"
            } else {
                //notification
                let content = UNMutableNotificationContent()
                content.title = "Ride Status Update"
                content.subtitle = "from PlzHold"
                content.body = "Your ride arrived! Meet outside."
                let trigger  = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: "notifictaion.id.02", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                
                ETA.text = msg != nil ? msg! : eta
                orderStatus.text = msg != nil ? msg! : "Your escort is waiting, please meet outside."
            }
            
            orderButton.isHidden = true
            cancelButton.isHidden = false
            loadingIndicator.stopAnimating()
            
        case .OnTrip:
            orderStatus.text = msg != nil ? msg! : "Your ride is in progress. Enjoy."
            cancelButton.isEnabled = false
            
        case .EndedTrip:
            //notification
            let content = UNMutableNotificationContent()
            content.title = "Ride Status Update"
            content.subtitle = "from PlzHold"
            content.body = "Ride complete. Have a nice day!"
            let trigger  = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "notifictaion.id.03", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            
            orderStatus.text = msg != nil ? msg! : "Ride complete. Have a nice day!"
            orderButton.setTitleColor(UIColor.white, for: .normal)
            driverDetailsView.isHidden = true
            cancelButton.isEnabled = true
            orderButton.isHidden = false
            cancelButton.isHidden = true
        }
    }
    
    private func sendRequest(_ method: HTTPMethod, handler: @escaping(Bool) -> Void) {
        Alamofire.request(AppConstants.API_URL + "/request", method: method, parameters: ["user_id": AppConstants.USER_ID, "longitude": longitude, "latitude": latitude])
            .validate()
            .responseJSON { response in
                guard response.result.isSuccess,
                    let data = response.result.value as? [String:Bool],
                    let status = data["status"] else { return handler(false) }
                
                handler(status)
        }
    }
    
    private func listenForUpdates() {
        let channel = pusher.subscribe("cabs")
        
        let _ = channel.bind(eventName: "status-update") { data in
            if let data = data as? [String:AnyObject] {
                if let status = data["status"] as? String, let rideStatus = RideStatus(rawValue: status) {
                    if rideStatus == .FoundRide {
                        self.eta = String(describing: data["driver"]!["ETA"])
                    }
                    self.updateView(status: rideStatus, msg: nil)
                }
            }
        }
        
        pusher.connect()
    }

}

extension ViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        // Get the place name from 'GMSAutocompleteViewController'
        // Then display the name in textField
        destination.text = place.name
        // Dismiss the GMSAutocompleteViewController when something is selected
        dismiss(animated: true, completion: nil)
    }
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // Handle the error
        print("Error: ", error.localizedDescription)
    }
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        // Dismiss when the user canceled the action
        dismiss(animated: true, completion: nil)
    }
}

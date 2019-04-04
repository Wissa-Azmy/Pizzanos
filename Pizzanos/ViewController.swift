//
//  ViewController.swift
//  Pizzanos
//
//  Created by Wissa Azmy on 4/3/19.
//  Copyright © 2019 Wissa Azmy. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController {
    
    var isGrantedNotificationAccess = false
    var pizzaNumber = 0
    let pizzaSteps = ["Make Pizza", "Roll Dough", "Add Sauce", "Add Cheese", "Bake", "Done"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { (granted, error) in
            self.isGrantedNotificationAccess = granted
            
            if !granted {
                // Show uesr alert complaininng
            }
        }
    }
    
    // Update Notification content before read by the user while it's still in the pending notification queue.
    private func updatePizzaSteps(request: UNNotificationRequest) {
        if request.identifier.hasPrefix("message.pizza") {
            // content.userInfo property is set in the makePizzaContent method
            var stepNumber = request.content.userInfo["step"] as! Int
            // Need clarification on the % operator usage here
            stepNumber = (stepNumber + 1) % pizzaSteps.count
            let updatedContent = makePizzaContent()
            updatedContent.body = pizzaSteps[stepNumber]
            updatedContent.subtitle = request.content.subtitle
            updatedContent.userInfo["step"] = stepNumber
            // Re-adding the notification to the pending queue with the same identifier will remove the old one
            addNotification(trigger: request.trigger, content: updatedContent, identifier: request.identifier)
        }
    }

    private func makePizzaContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Making pizza"
        content.body = "A timed Pizza step"
        content.userInfo = ["step": 0]
        
        return content
    }
    
    private func addNotification(trigger: UNNotificationTrigger?, content: UNMutableNotificationContent, identifier: String) {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if error != nil {
                print("Couldn't fire the notification for the following error: \(error?.localizedDescription)")
            }
        }
    }
    
    @IBAction func scheduleBtn(_ sender: UIButton) {
        if isGrantedNotificationAccess {
            let content = UNMutableNotificationContent()
            content.title = "A scheduled Pizza"
            content.body = "Time to make Pizza"
            let dateComps: Set<Calendar.Component> = [.second,.hour,.minute]
            var date = Calendar.current.dateComponents(dateComps, from: Date())
            date.second = date.second! + 15
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
            addNotification(trigger: trigger, content: content, identifier: "message.scheduled")
        }
    }
    
    @IBAction func makeBtn(_ sender: UIButton) {
        if isGrantedNotificationAccess {
            let content = makePizzaContent()
            pizzaNumber += 1
            content.subtitle = "Pizza \(pizzaNumber)"
//            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10.0, repeats: false)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60.0, repeats: true)
            addNotification(trigger: trigger, content: content, identifier: "message.pizza.\(pizzaNumber)")
        }
    }

    @IBAction func nextBtn(_ sender: UIButton) {
        if isGrantedNotificationAccess {
            UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
                if let request = requests.first {
                    if request.identifier.hasPrefix("message.pizza") {
                        // Send notification request to the Update method for the request to be updated with the new content.
                        self.updatePizzaSteps(request: request)
                    } else {
                        // If first message doesn't has 'message.pizza' identifier
                        // Then re-add it to the end of the pending notification queue to get to the one that follows in the next Btn tap
                        // Using the unique identifier the pending notification queue doesn't allow duplicates,
                        // so the first one will be removed.
                        let content = request.content.mutableCopy() as! UNMutableNotificationContent
                        self.addNotification(trigger: request.trigger, content: content, identifier: request.identifier)
                    }
                }
            }
        }
    }
    
    @IBAction func viewPendingBtn(_ sender: UIButton) {
        if isGrantedNotificationAccess {
            UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
                print("\(Date()) --> \(requests.count) pending notifications...")
                
                for request in requests {
                    print("\(request.identifier) with Body: \(request.content.body)")
                }
            }
        }
    }
    
    @IBAction func viewDeliveredBtn(_ sender: UIButton) {
        if isGrantedNotificationAccess {
            UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
                print("\n\n\(Date()) --> \(notifications.count) delivered notifications.")
                
                for notification in notifications {
                    print("\(notification.request.identifier) with Body: \(notification.request.content.body)")
                }
            }
        }
    }
    
    @IBAction func removeBtn(_ sender: UIButton) {
        if isGrantedNotificationAccess {
            UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
                if let request = requests.first {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
                }
            }
        }
    }
}


extension ViewController: UNUserNotificationCenterDelegate {
    // To enable in-App notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound,.alert])
    }
}


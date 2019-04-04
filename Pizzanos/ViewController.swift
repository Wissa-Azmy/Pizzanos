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
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10.0, repeats: false)
            addNotification(trigger: trigger, content: content, identifier: "message.pizza.\(pizzaNumber)")
        }
    }

    @IBAction func nextBtn(_ sender: UIButton) {
        if isGrantedNotificationAccess {
            
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
            
        }
    }
}


extension ViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound,.alert])
    }
}


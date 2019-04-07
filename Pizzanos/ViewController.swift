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
    var pizzaStepNumber = 0
    let pizzaSteps = ["Make Pizza", "Roll Dough", "Add Sauce", "Add Cheese", "Add other ingredients", "Bake", "Done"]

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
            updatedContent.attachments = pizzaStepImg(step: stepNumber)
            // Re-adding the notification to the pending queue with the same identifier will remove the old one
            addNotification(trigger: request.trigger, content: updatedContent, identifier: request.identifier)
        }
    }

    private func makePizzaContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Making pizza"
        content.body = "A timed Pizza step"
        content.userInfo = ["step": 0]
        content.categoryIdentifier = "pizza.category"
        
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
            content.categoryIdentifier = "schedule.category"
//            content.attachments = notificationAttachment(for: "pizza.video", resource: "PizzaMovie", type: "mp4")
            content.attachments = notificationAttachment(for: "EHuliUke.music", resource: "EHuliUke", type: "mp3")
            let dateComps: Set<Calendar.Component> = [.second,.hour,.minute]
            var date = Calendar.current.dateComponents(dateComps, from: Date())
            date.second = date.second! + 5
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
            addNotification(trigger: trigger, content: content, identifier: "message.scheduled")
        }
    }
    
    @IBAction func makeBtn(_ sender: UIButton) {
        if isGrantedNotificationAccess {
            let content = makePizzaContent()
            content.subtitle = pizzaSteps[pizzaStepNumber]
//            content.attachments = pizzaStepImg(step: pizzaStepNumber)
            content.attachments = pizzaGif()
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
//            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60.0, repeats: true)
            addNotification(trigger: trigger, content: content, identifier: "message.pizza.\(pizzaStepNumber)")
            pizzaStepNumber += 1
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
    
    // MARK: - Attachments methods
    func pizzaStepImg(step: Int) -> [UNNotificationAttachment] {
        let stepString = String(step)
        let identifier = "pizza.step" + stepString
        let resource = "MakePizza_" + stepString
        
        return notificationAttachment(for: identifier, resource: resource, type: "jpg")
    }
    
    
    func pizzaGif() -> [UNNotificationAttachment] {
        
        guard let path = Bundle.main.path(forResource: "MakePizza_0", ofType: "gif") else {return[]}
        let fileURL = URL(fileURLWithPath: path)
        
        do {
            let attachment = try UNNotificationAttachment(
                identifier: "pizza.gif",
                url: fileURL,
                // Change the frame you want to use as your Gif thumbnail
                options: [UNNotificationAttachmentOptionsThumbnailTimeKey: 11]
            )
            return [attachment]
        } catch let error {
            print("\(error.localizedDescription)")
        }
        
        return []
    }

    
    func notificationAttachment(for identifier: String, resource: String, type: String) -> [UNNotificationAttachment] {
        let extendedIdentifier = identifier + "." + type
        guard let path = Bundle.main.path(forResource: resource, ofType: type) else {return[]}
        let fileURL = URL(fileURLWithPath: path)
        
        do {
            let attachment = try UNNotificationAttachment(identifier: extendedIdentifier, url: fileURL, options: nil)
            return [attachment]
        } catch let error {
            print("\(error.localizedDescription)")
        }
        
        return []
    }
}


extension ViewController: UNUserNotificationCenterDelegate {
    // To enable in-App notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound,.alert])
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let action = response.actionIdentifier
        let request = response.notification.request
        
        if action == "next.action" {
            updatePizzaSteps(request: request)
        } else if action == "stop.action" {
            // This line is useless if the trigger repeat value is false meaning that it's not a repeating notification
            // for the current one that receiving the action has already been removed from the peding queue
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
        } else if action == "text.input" {
            let textResponse = response as! UNTextInputNotificationResponse
            let newContent = request.content.mutableCopy() as! UNMutableNotificationContent
            newContent.subtitle = textResponse.userText
            addNotification(trigger: request.trigger, content: newContent, identifier: request.identifier)
        } else {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 05, repeats: false)
            let newRequest = UNNotificationRequest(identifier: request.identifier, content: request.content, trigger: trigger)
            UNUserNotificationCenter.current().add(newRequest) { (error) in
                if error != nil {
                    print("\(error!.localizedDescription)")
                }
            }
        }
        
        completionHandler()
    }
}


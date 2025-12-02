//
//  RemoteCourseRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//

import Foundation
import FirebaseFirestore

final class CourseRepository {
    
    private let db = Firestore.firestore()
    let collectionName: String = "courses"
    
    
    // MARK: General Course
    func addOrUpdateCourse(_ course: Course, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(course.id)
        
        do {
            try ref.setData(from: course, merge: true) { error in
                completion(error == nil)
            }
        } catch {
            print("❌ Firestore encoding error: \(error)")
            completion(false)
        }
    }
    
    /// Fetches a Course by ID from Firestore
    func fetchCourse(id: String, completion: @escaping (Course?) -> Void) {
        let ref = db.collection(collectionName).document(id)
        
        ref.getDocument { snapshot, error in
            if let error = error {
                print("❌ Firestore fetch error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(nil)
                return
            }
            
            do {
                // Decode the document directly into your Course model
                let course = try snapshot.data(as: Course.self)
                DispatchQueue.main.async { completion(course) }
            } catch {
                print("❌ Firestore decoding error: \(error)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
    
    func fetchCourseByName(_ name: String, completion: @escaping (Course?) -> Void) {
        db.collection(collectionName)
            .whereField("name", isEqualTo: name)
            .limit(to: 1)   // just in case multiple exist
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Firestore query error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    completion(nil)
                    return
                }
                
                do {
                    let course = try document.data(as: Course.self)
                    DispatchQueue.main.async { completion(course) }
                } catch {
                    print("❌ Firestore decoding error: \(error)")
                    DispatchQueue.main.async { completion(nil) }
                }
            }
    }
    
    func courseNameExistsAndSupported(_ name: String, completion: @escaping (Bool) -> Void) {
        db.collection(collectionName)
            .whereField("name", isEqualTo: name)
            .whereField("supported", isEqualTo: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Firestore query error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                let exists = snapshot?.documents.isEmpty == false
                completion(exists)
            }
    }

    
    func findOrCreateCourseWithMapItem(location: MapItemDTO, completion: @escaping (Bool) -> Void) {
        let courseID = CourseIDGenerator.generateCourseID(from: location)
        let ref = db.collection(collectionName).document(courseID)
        
        ref.getDocument { snapshot, error in
            if let error = error {
                print("❌ Firestore fetch error: \(error)")
                completion(false)
                return
            }
            
            if let course = try? snapshot?.data(as: Course.self), snapshot?.exists == true {
                // Course exists → success
                completion(true)
            } else {
                // Create new course
                let newCourse = Course(id: courseID, name: location.name ?? "N/A", supported: false, password: PasswordGenerator.generate(.strong()))
                do {
                    try ref.setData(from: newCourse)
                    completion(true)
                } catch {
                    print("❌ Firestore write error: \(error)")
                    completion(false)
                }
            }
        }
    }
    
    func findCourseIDWithPassword(withPassword password: String, completion: @escaping (String?) -> Void) {
        db.collection(collectionName)
            .whereField("password", isEqualTo: password)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Firestore query error: \(error)")
                    completion(nil)
                    return
                }
                
                guard let doc = snapshot?.documents.first else {
                    completion(nil)   // No course has this password
                    return
                }
                
                completion(doc.documentID)
            }
    }
    
    func fetchCourseIDs(prefix: String, completion: @escaping ([SmallCourse]) -> Void) {
        let end = prefix + "\u{f8ff}"
        db.collection(collectionName)
            .whereField(FieldPath.documentID(), isGreaterThanOrEqualTo: prefix)
            .whereField(FieldPath.documentID(), isLessThanOrEqualTo: end)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                
                guard let docs = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let courses: [SmallCourse] = docs.map { doc in
                    let name = doc["name"] as? String ?? "Unnamed"
                    return SmallCourse(id: doc.documentID, name: name)
                }
                
                completion(courses)
            }
    }
    
    // MARK: Email
    func addEmail(newEmail: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(courseID)

        ref.updateData([
            "emails": FieldValue.arrayUnion([newEmail])
        ]) { error in
            if let error = error {
                print("❌ Failed to add email: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func removeEmail(email: String, courseID: String, completion: @escaping (Bool) -> Void) {
        db.collection(collectionName)
            .document(courseID)
            .updateData([
                "emails": FieldValue.arrayRemove([email])
            ]) { error in
                completion(error == nil)
            }
    }
    
    // MARK: Admin Id
    func addAdminIDtoCourse(adminID: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(courseID)

        ref.updateData([
            "adminIDs": FieldValue.arrayUnion([adminID])
        ]) { error in
            if let error = error {
                print("❌ Failed to add email: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func removAdminIDfromCourse(email: String, courseID: String, completion: @escaping (Bool) -> Void) {
        db.collection(collectionName)
            .document(courseID)
            .updateData([
                "adminIDs": FieldValue.arrayRemove([email])
            ]) { error in
                completion(error == nil)
            }
    }
    
    
    func keepOnlyAdminID(id: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let docRef = db.collection(collectionName).document(courseID)
        
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                completion(false)
                return
            }
            
            // Get current adminIDs array
            let adminIDs = data["adminIDs"] as? [String] ?? []
            
            // Keep only the one you want
            let updatedAdminIDs = adminIDs.contains(id) ? [id] : []
            
            // Update the document
            docRef.updateData([
                "adminIDs": updatedAdminIDs
            ]) { error in
                completion(error == nil)
            }
        }
    }

    
    // MARK: - Check if email exists in course
    func isEmailInCourse(email: String, courseID: String, completion: @escaping (Bool) -> Void) {
        let ref = db.collection(collectionName).document(courseID)
        
        ref.getDocument { snapshot, error in
            if let error = error {
                print("❌ Fetch error: \(error)")
                completion(false)
                return
            }
            
            guard let data = snapshot?.data() else {
                // Document doesn't exist → email not present
                completion(false)
                return
            }
            
            let emails = data["emails"] as? [String] ?? []
            completion(emails.contains(email))
        }
    }

    
    // MARK: Daily Counts
    enum DailyMetric: String {
        case activeUsers
        case gamesPlayed
        case newPlayers
        case returningPlayers
    }
    
    // MARK: - Unified Daily Metric Updater
    func updateDailyMetric(courseID: String, metric: DailyMetric, increment: Int = 1) {
        let ref = db.collection(collectionName).document(courseID)
        
        // Format "MM-dd-YYYY"
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-YYYY"
        let todayID = formatter.string(from: Date())
        
        ref.getDocument { snapshot, error in
            guard error == nil else { return }
            
            var dailyCounts = (snapshot?.data()?["dailyCounts"] as? [[String: Any]]) ?? []
            
            // Find today's entry
            if let index = dailyCounts.firstIndex(where: { $0["id"] as? String == todayID }) {
                
                // Get existing value for this metric
                let currentValue = dailyCounts[index][metric.rawValue] as? Int ?? 0
                dailyCounts[index][metric.rawValue] = currentValue + increment
                
            } else {
                // Missing today's entry → create one
                dailyCounts.append([
                    "id": todayID,
                    "activeUsers": metric == .activeUsers ? increment : 0,
                    "gamesPlayed": metric == .gamesPlayed ? increment : 0,
                    "newPlayers": metric == .newPlayers ? increment : 0,
                    "returningPlayers": metric == .newPlayers ? increment : 0
                ])
            }
            
            ref.updateData(["dailyCounts": dailyCounts])
        }
    }
    
    func updateDailyCount(courseID: String, increment: Int = 1) {
        updateDailyMetric(courseID: courseID, metric: .activeUsers, increment: increment)
    }
    
    func updateGameCount(courseID: String, increment: Int = 1) {
        updateDailyMetric(courseID: courseID, metric: .gamesPlayed, increment: increment)
    }
    
    func updateNewPlayers(courseID: String, increment: Int = 1) {
        updateDailyMetric(courseID: courseID, metric: .newPlayers, increment: increment)
    }
    
    func updateReturningPlayers(courseID: String, increment: Int = 1) {
        updateDailyMetric(courseID: courseID, metric: .returningPlayers, increment: increment)
    }
    
    // MARK: Peak Analytics
    func incPeakAnalytics(courseID: String, increment: Int = 1) {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let weekday = Calendar.current.component(.weekday, from: now) - 1 // Sunday = 0

        let docRef = db.collection(collectionName).document(courseID)

        docRef.getDocument { snap, error in
            guard error == nil else { return }

            // 1. If the doc does NOT exist, initialize it and RECALL this function.
            if snap?.exists == false {
                let emptyHourly = Array(repeating: 0, count: 24)
                let emptyDaily = Array(repeating: 0, count: 7)

                docRef.setData([
                    "id": "peakAnalytics",
                    "hourlyCounts": emptyHourly,
                    "dailyCounts": emptyDaily
                ]) { _ in
                    // Re-call once initialization is done
                    self.incPeakAnalytics(courseID: courseID, increment: increment)
                }

                return
            }

            // 2. If it exists, safely increment hour + weekday
            docRef.updateData([
                "hourlyCounts.\(hour)": FieldValue.increment(Int64(increment)),
                "dailyCounts.\(weekday)": FieldValue.increment(Int64(increment))
            ])
        }
    }

    // MARK: Hole Analytics
    func addToHoleAnalytics(courseID: String, game: Game, increment: Int = 1) {
        let docRef = db.collection(collectionName).document(courseID)

        docRef.getDocument { snap, error in
            guard error == nil else { return }

            // 1. If doc does NOT exist, initialize it first
            if snap?.exists == false {
                docRef.setData([
                    "id": "holeAnalytics",
                    "totalStrokesPerHole": Array(repeating: 0, count: game.numberOfHoles),
                    "playsPerHole": Array(repeating: 0, count: game.numberOfHoles)
                ]) { _ in
                    // AFTER initializing, call the function again to apply increments
                    self.addToHoleAnalytics(courseID: courseID, game: game, increment: increment)
                }
                return
            }

            // 2. Apply increments
            for player in game.players {
                for hole in player.holes {
                    guard hole.strokes != 0 else { continue }

                    docRef.updateData([
                        "totalStrokesPerHole.\(hole.number - 1)": FieldValue.increment(Int64(hole.strokes)),
                        "playsPerHole.\(hole.number - 1)": FieldValue.increment(Int64(increment))
                    ])
                }
            }
        }
    }
    
    func addRoundTime(courseID: String, startTime: Date, endTime: Date) {
        let docRef = db.collection(collectionName).document(courseID)
        
        // Compute the duration in seconds
        let roundLengthSeconds = Int(endTime.timeIntervalSince(startTime))
        
        docRef.getDocument { snap, error in
            guard error == nil else {
                print("❌ Firestore fetch error: \(error!.localizedDescription)")
                return
            }
            
            // 1. If doc does NOT exist, initialize it first
            if snap?.exists == false {
                let initialData: [String: Any] = [
                    "id": "roundTimeAnalytics",
                    "totalRoundSeconds": roundLengthSeconds,
                ]
                docRef.setData(initialData) { error in
                    if let error = error {
                        print("❌ Failed to create roundTimeAnalytics: \(error)")
                    }
                }
                return
            }
            
            // 2. Doc exists → increment values atomically
            docRef.updateData([
                "totalRoundSeconds": FieldValue.increment(Int64(roundLengthSeconds)),
            ]) { error in
                if let error = error {
                    print("❌ Failed to update roundTimeAnalytics: \(error)")
                }
            }
        }
    }
}

struct SmallCourse: Identifiable {
    let id: String
    let name: String
}

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
            
            // ⭐ CHECK SNAPSHOT EXISTS (not decoding)
            if let snapshot = snapshot, snapshot.exists {
                print("Found existing course: \(courseID)")
                completion(true)
                return
            }
            
            // Create new course
            let newCourse = Course(
                id: courseID,
                name: location.name ?? "N/A",
                supported: false,
                password: PasswordGenerator.generate(.strong())
            )
            
            do {
                try ref.setData(from: newCourse)
                print("Created new course: \(courseID)")
                completion(true)
            } catch {
                print("❌ Firestore write error: \(error)")
                completion(false)
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
            guard let data = snapshot?.data(), error == nil else { return }

            // 1. Load dictionary (or empty)
            var dailyCounts = data["dailyCount"] as? [String: [String: Int]] ?? [:]

            // 2. Get or create today's entry
            var todayEntry: [String: Int] = dailyCounts[todayID] ?? [
                "activeUsers": 0,
                "gamesPlayed": 0,
                "newPlayers": 0,
                "returningPlayers": 0
            ]

            // 3. Increment the appropriate metric
            todayEntry[metric.rawValue, default: 0] += increment

            // 4. Save back into the dictionary
            dailyCounts[todayID] = todayEntry

            // 5. Upload the nested dictionary
            ref.updateData(["dailyCount": dailyCounts])
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
            guard let data = snap?.data(), error == nil else { return }

            // ===============================
            // 1. Get nested object or create empty
            // ===============================
            let peak = data["peakAnalytics"] as? [String: Any] ?? [:]

            // Load arrays or initialize
            var hourly = peak["hourlyCounts"] as? [Int] ?? Array(repeating: 0, count: 24)
            var daily  = peak["dailyCounts"] as? [Int] ?? Array(repeating: 0, count: 7)

            // Ensure lengths are correct
            if hourly.count != 24 { hourly = Array(repeating: 0, count: 24) }
            if daily.count  != 7  { daily  = Array(repeating: 0, count: 7) }

            // ===============================
            // 2. Increment values
            // ===============================
            hourly[hour] += increment
            daily[weekday] += increment

            // ===============================
            // 3. Rebuild nested object
            // ===============================
            let updatedPeak: [String: Any] = [
                "id": "peakAnalytics",
                "hourlyCounts": hourly,
                "dailyCounts": daily
            ]

            // ===============================
            // 4. Write back under nested key
            // ===============================
            docRef.setData(
                ["peakAnalytics": updatedPeak],
                merge: true
            )
        }
    }


    // MARK: Hole Analytics
    func addToHoleAnalytics(courseID: String, game: Game, increment: Int = 1) {
        let docRef = db.collection(collectionName).document(courseID)

        docRef.getDocument { snap, error in
            guard let data = snap?.data(), error == nil else { return }
            
            let holeAnalytics = data["holeAnalytics"] as? [String: Any] ?? [:]
            
            var totalStrokes = holeAnalytics["totalStrokesPerHole"] as? [Int] ?? Array(repeating: 0, count: game.numberOfHoles)
            var playsPerHole  = holeAnalytics["playsPerHole"] as? [Int] ?? Array(repeating: 0, count: game.numberOfHoles)
            
            for player in game.players {
                for hole in player.holes {
                    guard hole.strokes != 0 else { continue }
                    
                    totalStrokes[hole.number - 1] += hole.strokes
                    playsPerHole[hole.number - 1] += increment
                }
            }
            
            let updatedHole: [String: Any] = [
                "id": "holeAnalytics",
                "totalStrokesPerHole": totalStrokes,
                "playsPerHole": playsPerHole
            ]

            docRef.setData(
                ["holeAnalytics": updatedHole],
                merge: true
            )
        }
    }
    
    func addRoundTime(courseID: String, startTime: Date, endTime: Date) {
        let docRef = db.collection(collectionName).document(courseID)

        let roundLengthSeconds = Int(endTime.timeIntervalSince(startTime))

        docRef.getDocument { snap, error in
            guard let data = snap?.data(), error == nil else {
                print("❌ Firestore fetch error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // ===============================
            // 1. Load nested object if it exists
            // ===============================
            let roundTime = data["roundTimeAnalytics"] as? [String: Any] ?? [:]

            let existingSeconds = roundTime["totalRoundSeconds"] as? Int ?? 0

            // ===============================
            // 2. Build updated nested structure
            // ===============================
            let updatedRoundTime: [String: Any] = [
                "id": "roundTimeAnalytics",
                "totalRoundSeconds": existingSeconds + roundLengthSeconds
            ]

            // ===============================
            // 3. Write nested object back
            // ===============================
            docRef.setData(
                ["roundTimeAnalytics": updatedRoundTime],
                merge: true
            ) { error in
                if let error = error {
                    print("❌ Failed to update roundTimeAnalytics: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct SmallCourse: Identifiable {
    let id: String
    let name: String
}

//
//  AddToLeaderBoardButton.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/12/25.
//
import SwiftUI

struct AddToLeaderBoardButton: View{
    
    @State var alert: Bool = false
    
    var authModel: any AuthViewManager
    
    @State var course: Course?
    
    @State var email: String = ""
    
    @State var added: Bool = false
    
    let player: Player
    
    var body: some View {
        if let course = course, AdminCodeResolver.isAdminCodeThere(code: AdminCodeResolver.getCode(id: course.id)) && !(ProfanityFilter.containsBlockedWord(player.name) && player.incomplete) && !added && AdminCodeResolver.idToTier(course.id)! >= 2{
            Button{
                alert = true
            } label: {
                ZStack{
                    RoundedRectangle(cornerRadius: 25)
                        .foregroundStyle(.blue)
                    HStack{
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundStyle(.white)
                        Text("Leaderboard")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 120, height: 20)
            }
            .alert("Enter a valid email to add to leaderboard?", isPresented: $alert) {
                TextField("Name", text: $email)
        
                Button("Add") {addToLeaderBoard(max: 20, course: course)}
                    .disabled(!email.isValidEmail)
                Button("Cancel", role: .cancel) {}
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    func addToLeaderBoard(max numberOfPlayers: Int, course: Course) {
        var updatedCourse = course
        
        if course.leaderBoard!.count > numberOfPlayers {
            if updatedCourse.leaderBoard?[numberOfPlayers - 1].totalStrokes ?? 60 < player.toDTO().totalStrokes {
                updatedCourse.allPlayers?.append(player.toDTO())
                if let playerToRemove = updatedCourse.leaderBoard?[numberOfPlayers - 1],
                   let index = updatedCourse.allPlayers?.firstIndex(of: playerToRemove) {
                    updatedCourse.allPlayers?.remove(at: index)
                }
                updatedCourse.emails?.append(email)
                self.course = updatedCourse
                authModel.addOrUpdateCourse(updatedCourse) { _ in }
                withAnimation {
                    added = true
                }
            }
        } else {
            updatedCourse.allPlayers?.append(player.toDTO())
            updatedCourse.emails?.append(email)
            self.course = updatedCourse
            authModel.addOrUpdateCourse(updatedCourse) { _ in }
            withAnimation {
                added = true
            }
        }
    }
}

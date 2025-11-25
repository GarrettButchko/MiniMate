//
//  AddToLeaderBoardButton.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/12/25.
//
import SwiftUI

struct AddToLeaderBoardButton: View{
    
    @State var course: Course?
    @State var alert: Bool = false
    @State var added: Bool = false
    @State var email: String = ""
    
    let player: Player
    
    let adminCodeResolver = AdminCodeResolver()
    let courseLeaderBoardRepo = CourseLeaderboardRepository()
    
    var body: some View {
        if let course = course, adminCodeResolver.isAdminCodeThere(code: adminCodeResolver.getCode(id: course.id)) && !(ProfanityFilter.containsBlockedWord(player.name) && player.incomplete) && !added && adminCodeResolver.idToTier(course.id)! >= 2{
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
        
                Button("Add") {
                    courseLeaderBoardRepo.addPlayerToLiveLeaderboard(player: player, course: course, email: email, max: 20, added: $added, courseRepository: CourseRepository()) { _ in }
                }
                    .disabled(!email.isValidEmail)
                Button("Cancel", role: .cancel) {}
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}


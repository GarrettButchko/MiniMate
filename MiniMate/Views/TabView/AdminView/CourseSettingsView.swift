//
//  CourseSettingsView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/10/25.
//
import SwiftUI
import MarqueeText

struct CourseSettingsView: View {
    
    @ObservedObject var authModel: AuthViewModel
    @State var course: Course
    
    @State var editCourse: Bool = false
    
    @State var showingPickerLogo: Bool = false
    @State var showingPickerAd: Bool = false
    
    @State var image: UIImage? = nil
    
    @State private var colorStringToDelete: String? = nil
    @State private var parIndexToDelete: Int? = nil
    @State private var showDeleteColor: Bool = false
    @State private var showColor: Bool = false
    
    let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown, .gray, .black
    ]
    
    let courseRepo = CourseRepository()
    
    init(authModel: AuthViewModel, course: Course) {
        self.authModel = authModel
        self.course = course
    }
    
    var body: some View {
        VStack{
            headerView
                .padding()
            ZStack{
                formView
                
                colorPicker
                    .opacity(showColor ? 1 : 0)
                    .animation(.spring(duration: 0.25, bounce: 0.4), value: showColor)
                    .allowsHitTesting(showColor)
            }
        }
    }
    
    private var colorPicker: some View {
        ZStack {
            // Background blur
            Rectangle()
                .foregroundStyle(.ultraThinMaterial)
                .ignoresSafeArea()
                
            // Popup card
            VStack(spacing: 20) {
                Text("Pick a Color")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 20) {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            withAnimation() {
                                course.colorsS?.append(colorToString(color))
                                courseRepo.addOrUpdateCourse(course) { _ in }
                                showColor = false
                            }
                        } label: {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 30, height: 30)
                                }
                        }
                    }
                }
                
                Button {
                    withAnimation() {
                        showColor = false
                    }
                } label: {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .padding()
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var headerView: some View {
        VStack{
            Capsule()
                .frame(width: 38, height: 6)
                .foregroundColor(.gray)
            HStack {
                Text("Settings")
                    .font(.title).fontWeight(.bold)
                Spacer()
            }
        }
    }
    
    
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNewPassword = false
    @State private var showPassword: Bool = false
    @State private var showChangePasswordMenu: Bool = false
    
    private var isValidPassword: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    private var formView: some View {
        
        Form{
            if let courseTier = course.tier, courseTier >= 2 || authModel.userModel?.adminType == "CREATOR"{
                Section("Course") {
                    
                    // -----
                    
                    HStack {
                        Text("Id:")
                        Spacer()
                        MarqueeText(
                            text: course.id,
                            font: UIFont.preferredFont(forTextStyle: .body),
                            leftFade: 16,
                            rightFade: 16,
                            startDelay: 2 // recommend 1–2 seconds for a subtle Apple-like pause
                        )
                    }
                    
                    // -----
                    
                    HStack {
                        Text("Name:")
                        Spacer()
                        Text(course.name)
                    }
                    
                    // -----
                    
                    HStack {
                        Text("Tier:")
                        Spacer()
                        Text(String(courseTier))
                    }
                    
                    // ------
                    
                    HStack{
                        Text("Password:")
                        
                        if showPassword {
                            Text(course.password)
                        } else {
                            Text("••••••••••")
                        }
                        Spacer()
                        Button {
                            showPassword.toggle()
                        } label: {
                            !showPassword ? Image(systemName: "eye").foregroundColor(.blue) : Image(systemName: "eye.slash").foregroundColor(.blue)
                        }
                        
                    }
                    
                    Button {
                        withAnimation(){
                            showChangePasswordMenu.toggle()
                        }
                    } label: {
                        showChangePasswordMenu ? Text("Hide") : Text("Change Password")
                            .foregroundColor(.blue)
                    }
                    
                    
                    if showChangePasswordMenu {
    
                        VStack{
                            TextField("New Password", text: $newPassword)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                                )
                        
                            // Confirm Password
                            TextField("Confirm Password", text: $confirmPassword)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                                )
                            
                            // Save button
                            Button(action: {
                                guard !newPassword.isEmpty, newPassword == confirmPassword else { return }
                                
                                course.password = newPassword
                                
                                courseRepo.addOrUpdateCourse(course) { complete in
                                    if complete {
                                        if let userID = authModel.userModel?.id {
                                            courseRepo.keepOnlyAdminID(id: userID, courseID: course.id) { _ in }
                                        }
                                    }
                                }
                                
                                newPassword = ""
                                confirmPassword = ""
                                showNewPassword = false
                                showChangePasswordMenu = false
                            }) {
                                ZStack{
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            isValidPassword
                                            ? Color.blue
                                            : Color.gray
                                        )
                                    HStack{
                                        Text(" ")
                                        Spacer()
                                        Text("Save")
                                        Spacer()
                                        Text(" ")
                                    }
                                    .padding()
                                    .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .disabled(!isValidPassword)
                        }
                    }

                    // ------
                    
                    HStack {
                        Text("Logo:")
                        Spacer()
                        Button {
                            withAnimation{
                                showingPickerLogo = true
                            }
                        } label: {
                            if let courseLogo = course.logo{
                                AsyncImage(url: URL(string: courseLogo)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 60)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60)
                                            .clipped()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60)
                                            .foregroundColor(.gray)
                                            .background(Color.gray.opacity(0.2))
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60)
                                    .foregroundColor(.gray)
                                    .background(Color.gray.opacity(0.2))
                            }
                        }
                        .sheet(isPresented: $showingPickerLogo) {
                            PhotoPicker(image: $image)
                                .onChange(of: image) { old ,newImage in
                                    guard let img = newImage else { return }
                                    authModel.uploadCompanyImages(img, id: course.id, key: "logoImage"){ result in
                                        switch result {
                                        case .success(let url):
                                            course.logo = url.absoluteString
                                            courseRepo.addOrUpdateCourse(course) { _ in }
                                        case .failure(let error):
                                            print("❌ Photo upload failed:", error)
                                        }
                                    }
                                }
                        }
                    }
                    
                    VStack {
                        HStack{
                            Text("Colors for course:")
                            Spacer()
                        }
                        ScrollView(Axis.Set.horizontal) {
                            HStack{
                                ForEach(course.colors, id: \.self){ color in
                                    Button {
                                        if let colorIndex = course.colors.firstIndex(of: color) {
                                            colorStringToDelete = course.colorsS?[colorIndex]
                                        }
                                    } label: {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 40, height: 40)
                                            .overlay(content: {
                                                Circle()
                                                    .fill(color)
                                                    .frame(width: 30, height: 30)
                                            })
                                    }
                                    .alert("Delete color?", isPresented: Binding<Bool>(
                                        get: { colorStringToDelete != nil },
                                        set: { newValue in if !newValue { colorStringToDelete = nil } }
                                    )) {
                                        Button("Delete", role: .destructive, action: {
                                            if let colorString = colorStringToDelete, let index = course.colorsS?.firstIndex(of: colorString) {
                                                withAnimation{
                                                    _ = course.colorsS?.remove(at: index)
                                                }
                                                courseRepo.addOrUpdateCourse(course) { _ in }
                                                colorStringToDelete = nil
                                            }
                                        })
                                        Button("Cancel", role: .cancel, action: { colorStringToDelete = nil })
                                    } message: {
                                        Text("Are you sure you want to delete this color?")
                                    }
                                    
                                    
                                    
                                }
                                Button {
                                    withAnimation(){
                                        showColor = true
                                    }
                                } label: {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 40, height: 40)
                                        .overlay {
                                            Image(systemName: "plus")
                                                .resizable()
                                                .frame(width: 20, height: 20)
                                        }
                                }
                                
                            }
                        }
                    }
                    
                    HStack {
                        Text("Link:")
                        Spacer()
                        TextField("Link", text: Binding(
                            get: { course.link ?? "" },
                            set: {
                                course.link = $0.isEmpty ? nil : $0
                                courseRepo.addOrUpdateCourse(course) { _ in }
                            }
                        ))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                        )
                    }
                }
            }
            
            if let courseTier = course.tier, courseTier >= 2 {
                Section("Ad") {
                    VStack {
                        HStack{
                            Text(" ")
                            Spacer()
                            Text("Ad Title:")
                            Spacer()
                            Text(" ")
                        }
                        
                        Spacer()
                        TextEditor(text: Binding(
                            get: { course.adTitle ?? "" },
                            set: {
                                // Limit to 10 characters manually
                                let newValue = String($0.prefix(40))
                                course.adTitle = newValue.isEmpty ? nil : newValue
                                courseRepo.addOrUpdateCourse(course) { _ in }
                            }
                        ))
                        .frame(minHeight: 40, maxHeight: 80)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                        )
                    }
                    VStack {
                        HStack{
                            Text(" ")
                            Spacer()
                            Text("Ad Description:")
                            Spacer()
                            Text(" ")
                        }
                        Spacer()
                        TextEditor(text: Binding(
                            get: { course.adDescription ?? "" },
                            set: {
                                let newValue = String($0.prefix(80))
                                course.adDescription = newValue.isEmpty ? nil : newValue
                                courseRepo.addOrUpdateCourse(course) { _ in }
                            }
                        ))
                        .frame(minHeight: 60, maxHeight: 120)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                        )
                    }
                    
                    HStack {
                        Text("Ad Link:")
                        Spacer()
                        TextField("Ad Link", text: Binding(
                            get: { course.adLink ?? "" },
                            set: {
                                course.adLink = $0.isEmpty ? nil : $0
                                courseRepo.addOrUpdateCourse(course) { _ in }
                            }
                        ))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                        )
                    }
                    HStack {
                        Text("Ad Image:")
                        Spacer()
                        Button {
                            withAnimation{
                                showingPickerAd = true
                            }
                        } label: {
                            if let courseImage = course.adImage{
                                AsyncImage(url: URL(string: courseImage)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 60)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .clipped()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60)
                                            .foregroundColor(.gray)
                                            .background(Color.gray.opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60)
                                    .foregroundColor(.gray)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .sheet(isPresented: $showingPickerAd) {
                            PhotoPicker(image: $image)
                                .onChange(of: image) { old ,newImage in
                                    guard let img = newImage else { return }
                                    authModel.uploadCompanyImages(img, id: course.id, key: "adImage"){ result in
                                        switch result {
                                        case .success(let url):
                                            course.adImage = url.absoluteString
                                            courseRepo.addOrUpdateCourse(course) { _ in }
                                        case .failure(let error):
                                            print("❌ Photo upload failed:", error)
                                        }
                                    }
                                }
                        }
                    }
                }
            }
            
            
            Section ("Pars"){
                ForEach(course.holes) { hole in
                    HStack{
                        Text("Hole \(hole.number):")
                        Spacer()
                        
                        NumberPickerView(selectedNumber: Binding(
                            get: { hole.par},
                            set: {
                                course.pars?[hole.number] = $0
                                courseRepo.addOrUpdateCourse(course) { _ in }
                            }
                        ), minNumber: 0, maxNumber: 10)
                        .frame(width: 75)
                    }
                }
                .onDelete { indices in
                    let filteredIndices = indices.filter { $0 != 0 }
                    for index in filteredIndices {
                        withAnimation(){
                            _ = course.pars?.remove(at: index)
                            courseRepo.addOrUpdateCourse(course) { _ in }
                        }
                    }
                }
                
                
                Button {
                    withAnimation(){
                        course.pars?.append(0)
                        courseRepo.addOrUpdateCourse(course) { _ in }
                    }
                } label: {
                    HStack{
                        Image(systemName: "plus")
                        Text("Add Par")
                    }
                }
            }
        }
    }
    
    func colorToString(_ color: Color) -> String {
        return String(describing: color)
    }
}

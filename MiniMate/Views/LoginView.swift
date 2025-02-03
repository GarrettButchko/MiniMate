import SwiftUI

struct LoginView: View {
    @StateObject var authViewModel: AuthViewModel
    @StateObject var viewManager: ViewManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button("Sign Up") {
                authViewModel.createUser(email: email, password: password) { result in
                    switch result {
                    case .success:
                        errorMessage = nil
                        withAnimation(){
                            viewManager.navigateToMain()
                        }
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .buttonStyle(.bordered)
            
            Button("Login") {
                authViewModel.signIn(email: email, password: password) { result in
                    switch result {
                    case .success:
                        errorMessage = nil
                        withAnimation(){
                            viewManager.navigateToMain()
                        }
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle("Firebase Auth")
    }
}


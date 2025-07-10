import SwiftUI

struct ButtonSkim {
    var color: Color
    var systemImage: String
    var function: (() -> Void)? = nil
    var string: String? = nil
    var isShared: Bool {
        if function == nil && string != nil {
            return true
        } else {
            return false
        }
    }
}

struct SkimButtonView: View {
    let buttonSkim: ButtonSkim
    let offsetX: CGFloat

    var body: some View {
        Button {
            buttonSkim.function!()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(buttonSkim.color))
                if offsetX < -50 {
                    Image(systemName: buttonSkim.systemImage)
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

struct SkimShareLinkView: View {
    let buttonSkim: ButtonSkim
    let offsetX: CGFloat

    var body: some View {
        ShareLink(item: buttonSkim.string!) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(buttonSkim.color))
                if offsetX < -50 {
                    Image(systemName: buttonSkim.systemImage)
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

struct SwipeableRowModifier: ViewModifier {
    @Binding var editingID: String?
    @State var offsetX: CGFloat = 0
    @State private var lastOffsetX: CGFloat = 0
    var id: String
    
    let buttonOne: ButtonSkim?
    let buttonTwo: ButtonSkim?
    
    let deleteFunction: (() -> Void)?
    let buttonPressFunction: () -> Void

    func body(content: Content) -> some View {
        content
            .offset(x: editingID == id ? offsetX : 0)
            .animation(.easeOut(duration: 0.3), value: offsetX)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 { // dragging left only
                            let totalOffset = lastOffsetX + value.translation.width
                            offsetX = totalOffset
                            if editingID != id{
                                editingID = id
                            }
                        }
                        if lastOffsetX + value.translation.width < 0 { // dragging left only
                            let totalOffset = lastOffsetX + value.translation.width
                            offsetX = totalOffset
                        }
                        if value.translation.width == -220 {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -220 {
                            // Slide off screen
                            if let deleteFunction = deleteFunction {
                                withAnimation(){
                                    deleteFunction()
                                }
                            }
                            
                        } else if value.translation.width > -220 && value.translation.width < -50 {
                            
                            withAnimation {
                                offsetX = -100
                            }
                            
                        } else {
                            withAnimation {
                                offsetX = 0
                                editingID = nil
                            }
                        }
                        
                        lastOffsetX = offsetX
                    }
            )
            .onTapGesture {
                if editingID != id {
                    buttonPressFunction()
                }
            }
    
    
    if editingID == id && offsetX < -10{
        
        VStack{
            if let deleteFunc = deleteFunction{
                if offsetX > -220 {
                    if let buttonOne = buttonOne {
                        if buttonOne.isShared {
                            SkimShareLinkView(buttonSkim: buttonOne, offsetX: offsetX)
                        } else {
                            SkimButtonView(buttonSkim: buttonOne, offsetX: offsetX)
                        }
                    }
                    if let buttonTwo = buttonTwo {
                        if buttonTwo.isShared {
                            SkimShareLinkView(buttonSkim: buttonTwo, offsetX: offsetX)
                        } else {
                            SkimButtonView(buttonSkim: buttonTwo, offsetX: offsetX)
                        }
                    }
                }
                
                Button {
                    deleteFunc()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.red)
                        if offsetX < -50{
                            Image(systemName: "xmark")
                                .foregroundStyle(.white)
                                .font(.title2)
                        }
                    }
                }
            } else {
                if let buttonOne = buttonOne {
                    if buttonOne.isShared {
                        SkimShareLinkView(buttonSkim: buttonOne, offsetX: offsetX)
                    } else {
                        SkimButtonView(buttonSkim: buttonOne, offsetX: offsetX)
                    }
                }
                if let buttonTwo = buttonTwo {
                    if buttonTwo.isShared {
                        SkimShareLinkView(buttonSkim: buttonTwo, offsetX: offsetX)
                    } else {
                        SkimButtonView(buttonSkim: buttonTwo, offsetX: offsetX)
                    }
                }
            }
            
            
        }
        .offset(x: editingID == id ? offsetX : 0)
        .frame(width: -offsetX - 10)
        .animation(.easeOut(duration: 0.3), value: offsetX)
        .padding(.trailing, 20)
        .transition(.opacity)
        .padding([.trailing, .vertical])
    }
    }
}

extension View {
    func swipeMod(editingID: Binding<String?>, id: String, buttonPressFunction: @escaping () -> Void, buttonOne: ButtonSkim? = nil, buttonTwo: ButtonSkim? = nil, deleteFunction: (() -> Void)? = nil) -> some View {
        self.modifier(SwipeableRowModifier(
            editingID: editingID,
            id: id,
            buttonOne: buttonOne,
            buttonTwo: buttonTwo,
            deleteFunction: deleteFunction,
            buttonPressFunction: buttonPressFunction
        ))
    }
}

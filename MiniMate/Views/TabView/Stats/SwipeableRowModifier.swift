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
    @Binding var offsetX: CGFloat
    
    var body: some View {
        Button {
            buttonSkim.function!()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(buttonSkim.color))
                if offsetX < -35 {
                    Image(systemName: buttonSkim.systemImage)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .opacity(offsetX < -50 ? 1 : 0)
                        
                }
            }
        }
    }
}

struct SkimShareLinkView: View {
    let buttonSkim: ButtonSkim
    @Binding var offsetX: CGFloat
    
    var body: some View {
        ShareLink(item: buttonSkim.string!) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(buttonSkim.color))
                if offsetX < -35 {
                    Image(systemName: buttonSkim.systemImage)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .opacity(offsetX < -50 ? 1 : 0)
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
    
    let pausePoint: CGFloat = -100
    let commitPoint: CGFloat = -50
    let resetPoint: CGFloat = 0
    let deletePoint: CGFloat = -220
    
    let buttonOne: ButtonSkim?
    let buttonTwo: ButtonSkim?
    
    let deleteFunction: (() -> Void)?
    let buttonPressFunction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .offset(x: offsetX)
            .animation(.easeOut(duration: 0.3), value: offsetX)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only handle horizontal drags, ignore vertical drags so scrolling works
                        
                            if value.translation.width < resetPoint { // dragging left only
                                withAnimation(){
                                    let totalOffset = lastOffsetX + value.translation.width
                                    offsetX = totalOffset
                                    if editingID != id {
                                        editingID = id
                                    }
                                }
                            }
                            if lastOffsetX + value.translation.width < resetPoint { // dragging left only
                                withAnimation(){
                                    let totalOffset = lastOffsetX + value.translation.width
                                    offsetX = totalOffset
                                }
                            }
                            if offsetX == deletePoint {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                        
                    }
                    .onEnded { value in
                        // Only handle horizontal drags
                        
                            if offsetX < -220 {
                                // Slide off screen
                                if let deleteFunction = deleteFunction {
                                    withAnimation(){
                                        deleteFunction()
                                    }
                                }
                            } else if offsetX > deletePoint && offsetX < commitPoint {
                                withAnimation {
                                    offsetX = -100
                                }
                            } else {
                                withAnimation(){
                                    editingID = nil
                                }
                                
                            }
                            withAnimation(){
                                lastOffsetX = offsetX
                            }
                        
                    }
            )
            .onTapGesture {
                if editingID != id {
                    buttonPressFunction()
                }
            }
            .onChange(of: editingID) { oldValue, newValue in
                if newValue != id {
                    withAnimation(){
                        offsetX = resetPoint
                        lastOffsetX = resetPoint
                    }
                }
            }
        
        
        if editingID == id && offsetX < -10{
            
            VStack{
                if let deleteFunc = deleteFunction{
                    if offsetX > deletePoint {
                        if let buttonOne = buttonOne {
                            if buttonOne.isShared {
                                SkimShareLinkView(buttonSkim: buttonOne, offsetX: $offsetX)
                            } else {
                                SkimButtonView(buttonSkim: buttonOne, offsetX: $offsetX)
                            }
                        }
                        if let buttonTwo = buttonTwo {
                            if buttonTwo.isShared {
                                SkimShareLinkView(buttonSkim: buttonTwo, offsetX: $offsetX)
                            } else {
                                SkimButtonView(buttonSkim: buttonTwo, offsetX: $offsetX)
                            }
                        }
                    }
                    
                    Button {
                        deleteFunc()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.red)
                            if offsetX < -35 {
                                Image(systemName: "xmark")
                                    .foregroundStyle(.white)
                                    .font(.title2)
                                    .opacity(offsetX < -50 ? 1 : 0)
                            }
                            
                        }
                    }
                } else {
                    if let buttonOne = buttonOne {
                        if buttonOne.isShared {
                            SkimShareLinkView(buttonSkim: buttonOne, offsetX: $offsetX)
                        } else {
                            SkimButtonView(buttonSkim: buttonOne, offsetX: $offsetX)
                        }
                    }
                    if let buttonTwo = buttonTwo {
                        if buttonTwo.isShared {
                            SkimShareLinkView(buttonSkim: buttonTwo, offsetX: $offsetX)
                        } else {
                            SkimButtonView(buttonSkim: buttonTwo, offsetX: $offsetX)
                        }
                    }
                }
            }
            .offset(x: offsetX)
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


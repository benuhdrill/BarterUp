struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        if isActive {
            if authManager.isAuthenticated {
                HomeView()
            } else {
                LoginView()
            }
        } else {
            VStack {
                Image("BarterUpLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
                Text("BarterUp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.primaryGreen)
            }
            .scaleEffect(size)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.2)) {
                    self.size = 0.9
                    self.opacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}
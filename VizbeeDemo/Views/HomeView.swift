import SwiftUI
import AVFAudio
import VizbeeKit

struct HomeView: View {
    @ObservedObject private var castingViewModel: CastingViewModel
    @State private var isSettingsActive = false
    @Environment(\.colorScheme) private var colorScheme
    
    private let bottomInset: CGFloat = 80
    
    init(castingViewModel: CastingViewModel) {
        self.castingViewModel = castingViewModel
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(VideoData.videos) { video in
                    NavigationLink(destination: DetailView(video: video)) {
                        VideoRow(video: video)
                    }
                }
                
                // Footer view for bottom inset
                Section(footer:
                    Color.clear
                        .frame(height: bottomInset)
                        .listRowInsets(EdgeInsets())
                ) {}
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle("\(Constants.Labels.appTitle)", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    isSettingsActive = true
                }) {
                    Image(Constants.Images.settings)
                        .renderingMode(.template)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                },
                trailing: HStack(spacing: 12) {
                           Button(action: {
                               printAirPlayState()
                           }) {
                               Image(systemName: "ladybug")
                                   .foregroundColor(colorScheme == .dark ? .white : .black)
                           }
                    
                        AirPlayButton(tintColor: colorScheme == .dark ? .white : .black)
                            .frame(width: 24, height: 24)
                        
                        CastButton()
                    }
            )
            .background(
                NavigationLink(destination: SettingsView(), isActive: $isSettingsActive) {
                    EmptyView()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(castingViewModel)
    }
}

private func printAirPlayState() {
    print("=== AirPlay State Check (HomeView) ===")
    print("No active player in HomeView")
    
    // Check audio route
    let audioSession = AVAudioSession.sharedInstance()
    let currentRoute = audioSession.currentRoute
    print("Audio outputs: \(currentRoute.outputs.map { "\($0.portName) (\($0.portType.rawValue))" })")
    print("======================================")
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let mockCastingViewModel = CastingViewModel() // You may need to adjust this based on your CastingViewModel implementation
        
        Group {
            HomeView(castingViewModel: mockCastingViewModel)
                .previewDisplayName(Constants.Preview_Title.lightMode)
            
            HomeView(castingViewModel: mockCastingViewModel)
                .preferredColorScheme(.dark)
                .previewDisplayName(Constants.Preview_Title.darkMode)
        }
    }
}

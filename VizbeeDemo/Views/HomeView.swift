import SwiftUI
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
                trailing: CastButton()
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

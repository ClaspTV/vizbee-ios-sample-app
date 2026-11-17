import SwiftUI

struct HomeView: View {
    private let bottomInset: CGFloat = 80
    
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
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView()
                .previewDisplayName(Constants.Preview_Title.lightMode)
            
            HomeView()
                .preferredColorScheme(.dark)
                .previewDisplayName(Constants.Preview_Title.darkMode)
        }
    }
}

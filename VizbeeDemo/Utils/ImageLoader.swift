import SwiftUI
import Combine
import UIKit

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellable: AnyCancellable?
    private static let imageCache = NSCache<NSString, UIImage>()
    
    func load(from urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        if let cachedImage = Self.imageCache.object(forKey: urlString as NSString) {
            self.image = cachedImage
            return
        }
        
        cancellable?.cancel()
        
        isLoading = true
        errorMessage = nil
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] downloadedImage in
                    guard let self = self, let downloadedImage = downloadedImage else {
                        self?.errorMessage = "Failed to create image"
                        return
                    }
                    self.image = downloadedImage
                    Self.imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                }
            )
    }
    
    func cancelLoading() {
        cancellable?.cancel()
    }
}

struct CustomAsyncImage: View {
    @ObservedObject private var loader = ImageLoader()
    let url: URL?
    let defaultImage: Image
    
    init(urlString: String?, defaultImage: Image = Image(Constants.Images.defaultPoster)) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            self.url = nil
            self.defaultImage = defaultImage
            return
        }
        self.url = url
        self.defaultImage = defaultImage
        loader.load(from: url.absoluteString)
    }
    
    var body: some View {
        content
    }
    
    private var content: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if loader.isLoading {
                ActivityIndicator()
            } else if loader.errorMessage != nil {
                defaultImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                defaultImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}

struct ActivityIndicator: UIViewRepresentable {
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        return indicator
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {}
}

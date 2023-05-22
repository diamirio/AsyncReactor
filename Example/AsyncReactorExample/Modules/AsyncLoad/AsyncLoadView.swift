#if canImport(SwiftUI)
import SwiftUI

@available(iOS 15.0, *)
public struct AsyncLoadView<Item, Content: View>: View {
    let state: AsyncLoad<Item>
    let content: (Item?) -> Content
    
    public init(_ state: AsyncLoad<Item>, content: @escaping (Item?) -> Content) {
        self.state = state
        self.content = content
    }
    
    public var body: some View {
        content(state.item)
            .opacity(state.item != nil ? 1 : 0)
            .overlay {
                switch state {
                case .loading, .none:
                    ProgressView()
                        .frame(maxHeight: .infinity)
                case .loaded:
                    EmptyView()
                case .error(let error):
                    Text(error.localizedDescription)
                }
            }
    }
}
#endif

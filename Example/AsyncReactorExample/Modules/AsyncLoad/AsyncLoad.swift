import Foundation

public enum AsyncAction<T>: Equatable {
    
    public static func == (lhs: AsyncAction<T>, rhs: AsyncAction<T>) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.loading, .loading):
            return true
        case (.error, .error):
            return true
        case (.success, .success):
            return true
        default:
            return false
        }
    }
    
    case none
    case loading
    case error(Error)
    case success(T)
    
    public var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    public var item: T? {
        switch self {
        case let .success(item):
            return item
        default:
            return nil
        }
    }
}

public enum AsyncLoad<T>: Equatable {
    
    public static func == (lhs: AsyncLoad<T>, rhs: AsyncLoad<T>) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.loading, .loading):
            return true
        case (.error, .error):
            return true
        case (.loaded, .loaded):
            return true
        default:
            return false
        }
    }
    
    case none
    case loading
    case error(Error)
    case loaded(T)
    
    public var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    public var item: T? {
        switch self {
        case let .loaded(item):
            return item
        default:
            return nil
        }
    }
}

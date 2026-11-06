import Foundation

// MARK: - Tab Manager

@MainActor
class TabManager {
    
    // MARK: - Properties
    
    private(set) var tabs: [Tab] = []
    private(set) var activeTabIndex: Int = 0
    
    // MARK: - Singleton
    
    static let shared = TabManager()
    
    // MARK: - Initialization
    
    private init() {
        // Restore last visited directory or use home directory
        let initialURL = SettingsManager.shared.lastVisitedDirectory ?? FileManager.default.homeDirectoryForCurrentUser
        let initialTab = Tab(initialURL: initialURL)
        tabs = [initialTab]
    }
    
    // MARK: - Tab Management
    
    var activeTab: Tab? {
        guard activeTabIndex >= 0 && activeTabIndex < tabs.count else { return nil }
        return tabs[activeTabIndex]
    }
    
    func createNewTab(url: URL = FileManager.default.homeDirectoryForCurrentUser) {
        let newTab = Tab(initialURL: url)
        tabs.append(newTab)
        activeTabIndex = tabs.count - 1
    }
    
    func closeTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        
        // Don't close if only one tab
        if tabs.count <= 1 {
            return
        }
        
        tabs.remove(at: index)
        
        // Adjust active tab index
        if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        } else if activeTabIndex == index {
            // Keep at same index if it was the closed tab
            // This will show the next tab
        }
    }
    
    func switchToTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        activeTabIndex = index
    }
    
    func nextTab() {
        let nextIndex = (activeTabIndex + 1) % tabs.count
        switchToTab(at: nextIndex)
    }
    
    func previousTab() {
        let prevIndex = (activeTabIndex - 1 + tabs.count) % tabs.count
        switchToTab(at: prevIndex)
    }
}
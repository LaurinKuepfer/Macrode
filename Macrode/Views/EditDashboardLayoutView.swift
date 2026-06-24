import SwiftUI

struct EditDashboardLayoutView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("activeDashboardBlocks") private var activeBlocksRaw: String = DashboardBlock.allCases.map { $0.rawValue }.joined(separator: ",")
    @AppStorage("inactiveDashboardBlocks") private var inactiveBlocksRaw: String = ""
    
    @State private var activeBlocks: [DashboardBlock] = []
    @State private var inactiveBlocks: [DashboardBlock] = []
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Active Blocks"), footer: Text("Drag to reorder how they appear on your dashboard.")) {
                    ForEach(activeBlocks) { block in
                        HStack {
                            Image(systemName: block.systemImage).foregroundColor(.blue)
                                .frame(width: 24)
                            Text(block.title)
                            Spacer()
                            Button(action: {
                                HapticManager.shared.impact(.light)
                                withAnimation {
                                    activeBlocks.removeAll(where: { $0 == block })
                                    inactiveBlocks.append(block)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onMove { indices, newOffset in
                        activeBlocks.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                
                Section(header: Text("Hidden Blocks"), footer: Text("These blocks will not appear on your dashboard.")) {
                    if inactiveBlocks.isEmpty {
                        Text("No hidden blocks.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(inactiveBlocks) { block in
                            HStack {
                                Image(systemName: block.systemImage).foregroundColor(.secondary)
                                    .frame(width: 24)
                                Text(block.title).foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    HapticManager.shared.impact(.light)
                                    withAnimation {
                                        inactiveBlocks.removeAll(where: { $0 == block })
                                        activeBlocks.append(block)
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Customize Layout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveLayout()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                loadLayout()
            }
        }
    }
    
    private func loadLayout() {
        let activeRaw = activeBlocksRaw.split(separator: ",").map(String.init)
        let inactiveRaw = inactiveBlocksRaw.split(separator: ",").map(String.init)
        
        var active = activeRaw.compactMap { DashboardBlock(rawValue: $0) }
        var inactive = inactiveRaw.compactMap { DashboardBlock(rawValue: $0) }
        
        // Safety net: ensure all cases are represented in case of app updates adding new blocks
        let allKnown = Set(DashboardBlock.allCases)
        let currentlyKnown = Set(active).union(Set(inactive))
        let missing = allKnown.subtracting(currentlyKnown)
        
        active.append(contentsOf: missing)
        
        self.activeBlocks = active
        self.inactiveBlocks = inactive
    }
    
    private func saveLayout() {
        activeBlocksRaw = activeBlocks.map { $0.rawValue }.joined(separator: ",")
        inactiveBlocksRaw = inactiveBlocks.map { $0.rawValue }.joined(separator: ",")
    }
}

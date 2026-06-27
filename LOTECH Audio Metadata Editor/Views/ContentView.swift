import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } detail: {
            VStack(spacing: 0) {
                MetadataEditorView(
                    item: viewModel.selectedItem,
                    metadata: $viewModel.metadata,
                    failedField: viewModel.failedMetadataField,
                    didFailArtworkSave: viewModel.didFailArtworkSave,
                    isEditingEnabled: viewModel.selectedItem?.audioFile?.supportsMetadataWriting ?? false,
                    onCommitField: viewModel.commitMetadataField,
                    onChooseArtwork: viewModel.chooseArtworkImage,
                    onPasteArtwork: viewModel.pasteArtworkImage,
                    onDropArtwork: viewModel.dropArtworkImage,
                    onRemoveArtwork: viewModel.removeArtwork
                )
                .ignoresSafeArea(.container, edges: .top)
                Divider()
                StatusBarView(message: viewModel.statusMessage)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

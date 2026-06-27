import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } detail: {
            VStack(spacing: 0) {
                switch viewModel.detailMode {
                case .singleFile:
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
                case .batchEdit:
                    BatchEditView(
                        rows: $viewModel.batchRows,
                        selection: $viewModel.selectedBatchRowIDs,
                        isLoading: viewModel.isBatchLoading,
                        isSaving: viewModel.isBatchSaving,
                        hasDraftChanges: viewModel.hasUnsavedBatchChanges,
                        onSave: viewModel.saveBatchChanges,
                        onDiscard: viewModel.discardBatchChanges,
                        onReload: viewModel.reloadBatchMetadata
                    )
                }
                Divider()
                StatusBarView(message: viewModel.statusMessage)
            }
        }
        .alert("Save unsaved batch edits?", isPresented: $viewModel.isShowingBatchExitAlert) {
            Button("Save Changes") {
                viewModel.saveBatchChangesAndLeave()
            }
            Button("Discard", role: .destructive) {
                viewModel.discardBatchChangesAndLeave()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelBatchExit()
            }
        } message: {
            Text("You have unsaved batch edits. Save before leaving?")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

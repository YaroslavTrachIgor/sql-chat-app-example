import Observation
import SwiftUI

struct ChatDetailView: View {
    let chatId: Int64
    let currentUserId: Int64
    var onSend: () -> Void = {}

    @State private var viewModel: ChatDetailViewModel

    init(chatId: Int64, currentUserId: Int64, onSend: @escaping () -> Void = {}) {
        self.chatId = chatId
        self.currentUserId = currentUserId
        self.onSend = onSend
        _viewModel = State(wrappedValue: ChatDetailViewModel(chatId: chatId, currentUserId: currentUserId, onSend: onSend))
    }

    var body: some View {
        @Bindable var vm = viewModel
        VStack(spacing: 0) {
            messageList
            HStack(spacing: 10) {
                TextField("Message", text: $vm.draft)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(Capsule())
                    .onSubmit { viewModel.sendDraft() }

                Button(action: { viewModel.sendDraft() }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                }
                .disabled(vm.draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle(vm.chatName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(vm.chatName)
                        .font(.headline)
                    Text(vm.memberCount > 2 ? "\(vm.memberCount) members" : "Direct message")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            viewModel.apply(chatId: chatId)
        }
        .onChange(of: chatId) { _, newId in
            viewModel.apply(chatId: newId)
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.messages) { msg in
                        messageView(msg)
                            .id(msg.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages.count) {
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    @ViewBuilder
    private func messageView(_ msg: Message) -> some View {
        if msg.mtype == "system" {
            systemBubble(msg)
        } else {
            messageBubble(msg)
        }
    }

    private func systemBubble(_ msg: Message) -> some View {
        let text: String = {
            if let p = msg.payload,
               let data = p.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let name = dict["display_name"] as? String {
                return "\(name) joined"
            }
            return msg.eventType ?? "system event"
        }()
        return Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }

    private func messageBubble(_ msg: Message) -> some View {
        let mine = msg.isMine
        return VStack(alignment: mine ? .trailing : .leading, spacing: 2) {
            if !mine {
                Text(msg.senderName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                    .padding(.leading, 4)
            }

            HStack {
                if mine { Spacer(minLength: 60) }
                VStack(alignment: .trailing, spacing: 4) {
                    if msg.mtype == "media" {
                        HStack(spacing: 4) {
                            Image(systemName: "paperclip")
                            Text(msg.mediaKind ?? "file")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    } else {
                        Text(msg.body ?? "")
                            .font(.body)
                            .foregroundStyle(mine ? .white : .primary)
                    }
                    Text(msg.displayTime)
                        .font(.system(size: 10))
                        .foregroundStyle(mine ? .white.opacity(0.6) : .secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(mine
                    ? Color.blue
                    : Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                if !mine { Spacer(minLength: 60) }
            }

            if !msg.reactions.isEmpty {
                HStack(spacing: 4) {
                    ForEach(msg.reactions) { r in
                        Text("\(r.emoji) \(r.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }
}

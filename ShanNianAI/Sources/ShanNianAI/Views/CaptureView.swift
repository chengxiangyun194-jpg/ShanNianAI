import SwiftUI

struct CaptureView: View {
    @EnvironmentObject var noteStore: NoteStore
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var inputText = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @FocusState private var isFocused: Bool
    @State private var placeholderIndex = 0
    @State private var submitScale: CGFloat = 1
    @State private var showVoiceTip = true

    private let placeholders = [
        "刚想到什么？",
        "一闪而过的念头...",
        "记下此刻的灵感 ✨",
        "有什么要记住的？",
        "今天学到了什么？",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                quickStatsBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("一闪")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        if noteStore.currentStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("连续 \(noteStore.currentStreak) 天")
                                    .font(.caption.bold())
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.orange.opacity(0.1)))
                        }

                        Text("抓住每一个闪念")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        ZStack(alignment: .topLeading) {
                            if inputText.isEmpty {
                                Text(placeholders[placeholderIndex])
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $inputText)
                                .focused($isFocused)
                                .font(.body)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(minHeight: 140)
                                .onAppear { isFocused = true }
                                .onChange(of: inputText) { _, newValue in
                                    if newValue.count > 500 {
                                        inputText = String(newValue.prefix(500))
                                    }
                                }
                                .onChange(of: speechRecognizer.transcribedText) { _, text in
                                    if !text.isEmpty && speechRecognizer.isRecording {
                                        inputText = text
                                    }
                                }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(alignment: .bottomTrailing) {
                            // Voice button
                            voiceButton
                                .padding(10)
                        }
                        .accessibilityLabel("笔记输入框")
                        .accessibilityHint("在这里输入你的闪念，最多500字")

                        HStack {
                            if speechRecognizer.isRecording {
                                recordingIndicator
                            }
                            Spacer()
                            Text("\(inputText.count)/500")
                                .font(.caption2)
                                .foregroundColor(inputText.count > 450 ? .orange : .secondary)
                        }
                    }
                    .padding(.horizontal)

                    Button {
                        HapticManager.medium()
                        submitNote()
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title3)
                                Text("保存闪念")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? AnyShapeStyle(Color.gray.opacity(0.3))
                                : AnyShapeStyle(
                                    LinearGradient(
                                        colors: [.orange, .pink.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .scaleEffect(submitScale)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                    .padding(.horizontal)
                    .accessibilityLabel("保存闪念")
                }

                Spacer()

                if !noteStore.notes.isEmpty {
                    recentNotesPreview
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .top) {
                if showSuccess {
                    successToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .task {
                await speechRecognizer.requestAuthorization()
            }
        }
    }

    // MARK: - Voice

    private var voiceButton: some View {
        Button {
            if speechRecognizer.isRecording {
                speechRecognizer.stopRecording()
                HapticManager.light()
            } else {
                Task {
                    if !speechRecognizer.isAuthorized {
                        await speechRecognizer.requestAuthorization()
                    }
                    if speechRecognizer.isAuthorized {
                        speechRecognizer.startRecording()
                        HapticManager.medium()
                        showVoiceTip = false
                    }
                }
            }
        } label: {
            Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                .font(.title3)
                .foregroundColor(speechRecognizer.isRecording ? .red : .gray)
                .padding(10)
                .background(
                    Circle()
                        .fill(speechRecognizer.isRecording
                            ? Color.red.opacity(0.15)
                            : Color(.systemGray5))
                )
                .scaleEffect(speechRecognizer.isRecording ? 1.2 : 1)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: speechRecognizer.isRecording)
        }
        .accessibilityLabel(speechRecognizer.isRecording ? "停止录音" : "开始语音输入")
    }

    private var recordingIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .opacity(speechRecognizer.isRecording ? 1 : 0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: speechRecognizer.isRecording)

            Text("正在聆听...")
                .font(.caption)
                .foregroundColor(.red)

            if showVoiceTip {
                Text("说完点击麦克风停止")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Subviews

    private var quickStatsBar: some View {
        HStack(spacing: 20) {
            statItem(value: "\(noteStore.notes.count)", label: "总笔记")
            statItem(
                value: "\(noteStore.notes.filter { Calendar.current.isDateInToday($0.createdAt) }.count)",
                label: "今日"
            )
            statItem(
                value: "\(noteStore.notes.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: Date().addingTimeInterval(-86400 * 7) ... Date()) }.count)",
                label: "本周"
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("统计：总笔记\(noteStore.notes.count)条，今日\(noteStore.notes.filter { Calendar.current.isDateInToday($0.createdAt) }.count)条")
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.orange)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var recentNotesPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近记录")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(noteStore.notes.prefix(5)) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.content)
                                .font(.caption)
                                .lineLimit(2)
                                .frame(width: 140, alignment: .leading)
                            HStack {
                                Image(systemName: note.category.icon)
                                    .font(.caption2)
                                Text(note.category.rawValue)
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
    }

    private var successToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("已保存")
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
        .padding(.top, 60)
    }

    // MARK: - Actions

    private func submitNote() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isSubmitting = true

        withAnimation(.easeInOut(duration: 0.1)) { submitScale = 0.95 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { submitScale = 1 }
        }

        noteStore.createNote(content: trimmed)
        HapticManager.success()

        inputText = ""
        isSubmitting = false

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showSuccess = false }
        }

        placeholderIndex = (placeholderIndex + 1) % placeholders.count
        isFocused = true
    }
}

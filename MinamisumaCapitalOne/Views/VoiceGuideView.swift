//
//  VoiceGuideView.swift
//  MinamisumaCapitalOne
//
//  AI-powered voice guide — explains banking features and answers questions
//  Uses Gemini API for conversational AI
//

import SwiftUI
import AVFoundation

// MARK: - Gemini Service

actor GeminiService {
    private let apiKey: String = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let key = dict["GEMINI_API_KEY"] as? String else {
            fatalError("Missing Secrets.plist or GEMINI_API_KEY")
        }
        return key
    }()
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    private var conversationHistory: [[String: Any]] = []

    private let systemInstruction = """
        Responde SIEMPRE en español de Mexico. \
        Eres un asistente bancario amigable y paciente para una app bancaria llamada Capital One, disenada para adultos mayores. \
        Ayudas a los usuarios a entender como usar la app. \
        Explica las cosas de forma simple, paso a paso, con oraciones cortas. \
        La app tiene estas funciones: \
        - Transferencias (enviar dinero a contactos) \
        - Retiros (retirar efectivo) \
        - Movimientos (ver historial de transacciones) \
        - Familia (administrar contactos de confianza que pueden ayudar a manejar la cuenta) \
        - Modo de Apoyo (modo de seguridad que un cuidador puede activar para poner limites de gasto y monitorear la cuenta) \
        - Guia por Voz (este asistente de voz) \
        - Perfil (configuracion y ajustes) \
        Se calido, alentador y tranquilizador. Usa lenguaje simple. \
        Si alguien parece confundido, ofrece explicar de otra manera. \
        Manten las respuestas concisas — maximo 3 a 4 oraciones.
        """

    func sendMessage(_ userMessage: String) async throws -> String {
        conversationHistory.append([
            "role": "user",
            "parts": [["text": userMessage]]
        ])

        var body: [String: Any] = [
            "contents": conversationHistory,
            "systemInstruction": [
                "parts": [["text": systemInstruction]]
            ]
        ]
        body["generationConfig"] = [
            "maxOutputTokens": 300,
            "temperature": 0.7
        ]

        let urlString = "\(endpoint)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 0

        if statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "no body"
            print("[Gemini] HTTP \(statusCode): \(errorBody)")
            throw GeminiError.requestFailed(status: statusCode, body: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            let raw = String(data: data, encoding: .utf8) ?? "no body"
            print("[Gemini] Parse error. Raw: \(raw)")
            throw GeminiError.invalidResponse
        }

        conversationHistory.append([
            "role": "model",
            "parts": [["text": text]]
        ])

        return text
    }

    func resetConversation() {
        conversationHistory = []
    }

    enum GeminiError: LocalizedError {
        case invalidURL
        case requestFailed(status: Int, body: String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "URL invalida"
            case .requestFailed(let status, let body): return "HTTP \(status): \(body)"
            case .invalidResponse: return "Respuesta invalida"
            }
        }
    }
}

// MARK: - Voice Guide View

struct VoiceGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var isSpeaking: Bool = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    private let gemini = GeminiService()

    private let suggestedQuestions = [
        "¿Como puedo hacer una transferencia?",
        "¿Que es el Modo de Apoyo?",
        "¿Como agrego un contacto de confianza?",
        "¿Como retiro dinero?"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chatContent
                inputBar
            }
            .background(Color.bgPrimary)
            .navigationTitle("Asistente de Voz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        toggleSpeech()
                    } label: {
                        Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(isSpeaking ? .brandTeal : .textSecondary)
                    }
                }
            }
            .onDisappear {
                speechSynthesizer.stopSpeaking(at: .immediate)
            }
        }
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    if messages.isEmpty {
                        welcomeSection
                    }

                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }

                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Pensando...")
                                .font(.seniorCaption)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .id("loading")
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isLoading) { _, loading in
                if loading {
                    withAnimation {
                        proxy.scrollTo("loading", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Welcome

    private var welcomeSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 56))
                .foregroundColor(.brandTeal)
                .padding(.top, 20)

            Text("Soy tu asistente bancario")
                .font(.seniorHeadline)
                .foregroundColor(.textPrimary)

            Text("Preguntame lo que necesites sobre tu cuenta, transferencias, retiros o cualquier funcion de la app.")
                .font(.seniorBody)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                Text("Preguntas sugeridas:")
                    .font(.seniorSmall)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(suggestedQuestions, id: \.self) { question in
                    Button {
                        sendMessage(question)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.brandTeal)
                            Text(question)
                                .font(.seniorCaption)
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(14)
                        .background(Color.bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                TextField("Escribe tu pregunta...", text: $inputText, axis: .vertical)
                    .font(.seniorBody)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(Color.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )

                Button {
                    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    sendMessage(text)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(
                            inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? .gray : .brandTeal
                        )
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.bgPrimary)
        }
    }

    // MARK: - Logic

    private func sendMessage(_ text: String) {
        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        Task {
            await generateResponse(to: text)
        }
    }

    @MainActor
    private func generateResponse(to prompt: String) async {
        do {
            let responseText = try await gemini.sendMessage(prompt)
            isLoading = false
            let assistantMessage = ChatMessage(role: .assistant, text: responseText)
            messages.append(assistantMessage)

            if isSpeaking {
                speak(responseText)
            }
        } catch {
            isLoading = false
            print("[Gemini] Error: \(error)")
            let errorMessage = ChatMessage(
                role: .assistant,
                text: "Lo siento, hubo un problema al procesar tu pregunta. Intenta de nuevo.\n\nDetalle: \(error.localizedDescription)"
            )
            messages.append(errorMessage)
        }
    }

    private func speak(_ text: String) {
        speechSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        utterance.pitchMultiplier = 1.05
        speechSynthesizer.speak(utterance)
    }

    private func toggleSpeech() {
        isSpeaking.toggle()
        if !isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id: UUID
    let role: ChatRole
    var text: String

    init(id: UUID = UUID(), role: ChatRole, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }

    enum ChatRole {
        case user
        case assistant
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .assistant {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.brandTeal)
                        Text("Asistente")
                            .font(.seniorSmall)
                            .foregroundColor(.textSecondary)
                    }
                }

                Text(message.text)
                    .font(.seniorBody)
                    .foregroundColor(message.role == .user ? .white : .textPrimary)
                    .padding(14)
                    .background(
                        message.role == .user
                        ? Color.brandTeal
                        : Color.bgCard
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            }

            if message.role == .assistant { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
    }
}

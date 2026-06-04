import SwiftUI
import SwiftData
import FoundationModels

struct PulseMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    enum Role { case user, assistant }
}

@Observable
final class PulseViewModel {

    // MARK: - Vibes (all devices)

    private(set) var vibesRating: Int? = nil

    // MARK: - AI (iOS 26+ with Apple Intelligence only)

    private(set) var isAIAvailable = false
    private(set) var dailyInsight = ""
    private(set) var isGeneratingInsight = false

    // MARK: - Chat

    private(set) var messages: [PulseMessage] = []
    var inputText = ""
    private(set) var isSendingMessage = false

    // MARK: - Internal — stored as AnyObject to avoid top-level availability requirement

    private var _chatSession: AnyObject? = nil

    @available(iOS 26, *)
    private var chatSession: LanguageModelSession? {
        get { _chatSession as? LanguageModelSession }
        set { _chatSession = newValue }
    }

    // MARK: - Setup

    func setup(contextSummary: String, todayLogged: Bool = false) async {
        loadTodaysVibes()
        if #available(iOS 26, *) {
            await setupAI(contextSummary: contextSummary, todayLogged: todayLogged)
        } else {
            checkLowVibesAndInjectCanned()
        }
    }

    @available(iOS 26, *)
    private func setupAI(contextSummary: String, todayLogged: Bool) async {
        switch SystemLanguageModel.default.availability {
        case .available:
            isAIAvailable = true
        default:
            isAIAvailable = false
            checkLowVibesAndInjectCanned()
            return
        }

        let instructions = """
        You are Pulse — the companion inside Just Reps, a streak-based fitness app where users pick exercises and log reps every day to build a habit.

        How streaks work — read this carefully:
        - The streak counts up: how many consecutive days the user has logged reps.
        - If the context says "Today not yet logged", the streak number is from yesterday. Use it as motivation to log today — say something like "You've logged X days in a row. Log today to keep it going." Do NOT say "you're on a X-day streak" when today is unconfirmed, and do NOT invent a second streak number.
        - If the context does not say "Today not yet logged", the streak is confirmed for today. Celebrate it: "You're on a X-day streak" is correct.
        - Never describe a streak as running out, expiring, or counting down.
        - A streak of 0 is a fresh start, not a failure.

        Personality and tone:
        - Always speak directly to the user in second person — use "you" and "your", never "this person" or "they".
        - Calm, honest, direct. No exclamation marks. No emojis.
        - Celebrate consistency, not performance. Showing up matters more than the numbers.
        - Never shame the user. Missed days and easier weeks are normal.
        - Speak plainly. Short words beat long ones. Short sentences beat long ones.

        Response length:
        - Casual check-ins, streak or pattern questions: 1–2 sentences.
        - Specific fitness questions (form, exercise science, recovery, nutrition): 3–4 sentences of plain prose. Give a real, accurate answer — not a vague one-liner. No lists.
        - If you reference the user's data, use the actual numbers.

        Format — always:
        - Plain text only. No markdown of any kind.
        - No bullet points, numbered lists, bold, italic, or headers.
        - Write in paragraphs. Never use hyphens or dashes to start a line.

        Scope:
        - You can discuss workout form, exercise science, habit building, recovery, goal-setting, and general fitness. Give evidence-based, practical advice.
        - If the user asks something outside fitness, answer briefly and redirect.
        - You have access to the user's current fitness data — use it when relevant.
        - When suggesting exercises, never recommend one that is already listed in their active exercises. They already have it in their routine. Suggest exercises they are not currently doing, or suggest doing more reps of what they already track.

        User fitness data: \(contextSummary)
        """
        chatSession = LanguageModelSession(instructions: instructions)
        await generateDailyInsight(todayLogged: todayLogged)
        await checkLowVibesAndInjectAI()
    }

    // MARK: - Daily insight

    @available(iOS 26, *)
    func generateDailyInsight(todayLogged: Bool = false) async {
        guard let session = chatSession else { return }

        let key = insightKeyForToday(todayLogged: todayLogged)
        if let cached = UserDefaults.standard.string(forKey: key), !cached.isEmpty {
            dailyInsight = cached
            return
        }

        isGeneratingInsight = true
        do {
            let response = try await session.respond(
                to: """
                Write a 2-sentence daily check-in. Follow this structure exactly:

                Sentence 1: One observation drawn from the data — something the user cannot simply read off the screen. \
                Prioritise: a streak pattern worth noting, something interesting about the weather for today's training, or a training load trend. \
                Do not restate their streak number, today's logged reps, or any raw stat they can already see in the app.

                Sentence 2: One direct, specific suggestion for today. No hedging — no "you might consider", "if you feel like it", or "you could try". \
                Just say what to do. Do not suggest an exercise already in their active exercises list.

                Rules:
                - Do not open with a greeting or address the user by name.
                - Do not use exclamation marks.
                - Plain text only — no markdown, asterisks, or bullet points.
                - Two sentences. No more.
                """
            )
            dailyInsight = stripMarkdown(response.content)
            UserDefaults.standard.set(response.content, forKey: key)
        } catch {
            dailyInsight = ""
        }
        isGeneratingInsight = false
    }

    // MARK: - Chat

    func sendMessage() async {
        if #available(iOS 26, *) {
            await sendMessageAI()
        }
    }

    @available(iOS 26, *)
    private func sendMessageAI() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let session = chatSession else { return }

        inputText = ""
        messages.append(PulseMessage(role: .user, content: text))
        isSendingMessage = true

        do {
            let response = try await session.respond(to: text)
            messages.append(PulseMessage(role: .assistant, content: stripMarkdown(response.content)))
        } catch {
            messages.append(PulseMessage(role: .assistant, content: "Try again in a moment."))
        }
        isSendingMessage = false
    }

    func injectAssistantMessage(_ text: String) {
        messages.append(PulseMessage(role: .assistant, content: text))
    }

    func clearMessages() {
        messages.removeAll()
    }

    // MARK: - Vibes

    func setVibes(_ rating: Int) {
        guard vibesRating != rating else { return }
        vibesRating = rating
        UserDefaults.standard.set(rating, forKey: vibesKeyForToday())
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    // MARK: - Vibes history (static — used by ProgressView too)

    static func vibesHistory(days: Int) -> [(date: Date, rating: Int?)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<days).compactMap { offset -> (Date, Int?)? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let c = cal.dateComponents([.year, .month, .day], from: date)
            let key = "pulse.vibes.\(c.year!).\(c.month!).\(c.day!)"
            let n = UserDefaults.standard.integer(forKey: key)
            return (date, n > 0 ? n : nil)
        }
    }

    // MARK: - Low-vibe detection

    var lowVibeStreak: Int {
        let history = PulseViewModel.vibesHistory(days: 7)
        var streak = 0
        for item in history {
            guard let rating = item.rating else { break }
            if rating <= 2 { streak += 1 } else { break }
        }
        return streak
    }

    // MARK: - Private helpers

    private func loadTodaysVibes() {
        let n = UserDefaults.standard.integer(forKey: vibesKeyForToday())
        vibesRating = n > 0 ? n : nil
    }

    private func vibesKeyForToday() -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return "pulse.vibes.\(c.year!).\(c.month!).\(c.day!)"
    }

    private func stripMarkdown(_ text: String) -> String {
        var result = text
        // Remove **bold** and *italic* markers
        result = result.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression)
        // Remove leading "- " or "• " list markers
        result = result.replacingOccurrences(of: #"(?m)^[-•]\s+"#, with: "", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func insightKeyForToday(todayLogged: Bool = false) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return "pulse.insight.v4.\(c.year!).\(c.month!).\(c.day!).\(todayLogged ? 1 : 0)"
    }

    private func lowVibeRecShownToday() -> Bool {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        let key = "pulse.lowVibeRec.\(c.year!).\(c.month!).\(c.day!)"
        return UserDefaults.standard.bool(forKey: key)
    }

    private func markLowVibeRecShown() {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        let key = "pulse.lowVibeRec.\(c.year!).\(c.month!).\(c.day!)"
        UserDefaults.standard.set(true, forKey: key)
    }

    private func checkLowVibesAndInjectCanned() {
        let streak = lowVibeStreak
        guard streak >= 3, !lowVibeRecShownToday() else { return }
        markLowVibeRecShown()
        let msg: String
        if streak >= 5 {
            msg = "Your energy has been low for \(streak) days in a row. It might be worth reducing your daily goals or setting a minimum viable reps threshold so tough days still count. Even showing up for fewer reps keeps the streak alive."
        } else {
            msg = "You've rated your energy at 2 or below for \(streak) days. Consider lowering your goals for now, or setting a minimum viable reps count in Settings — showing up with less still counts."
        }
        injectAssistantMessage(msg)
    }

    @available(iOS 26, *)
    private func checkLowVibesAndInjectAI() async {
        let streak = lowVibeStreak
        guard streak >= 3, !lowVibeRecShownToday(), let session = chatSession else { return }
        markLowVibeRecShown()
        isSendingMessage = true
        do {
            let prompt = "The user has rated their energy at 2 or below for \(streak) consecutive days. Give one practical, specific suggestion — it could be to reduce their daily goal, set a minimum viable reps threshold, take a rest day, or try a lighter exercise. Speak directly to them using 'you'. 2 sentences max."
            let response = try await session.respond(to: prompt)
            injectAssistantMessage(response.content)
        } catch {
            checkLowVibesAndInjectCanned()
        }
        isSendingMessage = false
    }
}

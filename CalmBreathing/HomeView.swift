import SwiftUI

// MARK: - Home Screen
/// Landing screen with app branding and navigation to all four features
struct HomeView: View {
    @EnvironmentObject var userPrefs: UserPreferencesStore
    @EnvironmentObject var premium:   PremiumStore
    @EnvironmentObject var journal:   JournalStore
    @State private var showReminderBanner   = false
    @State private var showPaywall          = false
    @State private var showSOS              = false
    @State private var gratitudeText        = ""
    @State private var gratitudeSaved       = false
    @State private var selectedMood: Int?   = nil
    @State private var expandMeditation     = false
    @State private var expandBreathing      = false
    @State private var expandSounds         = false

    var body: some View {
        ZStack {
            CalmBackground()

            ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer(minLength: 8)

                // App branding
                VStack(spacing: 4) {
                    Text("Serene Breathing")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundColor(.calmDeep)
                    Text("Meditation & Relax")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(.calmMid)
                }

                // Daily reminder banner (inline — won't overlap branding)
                if showReminderBanner {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.calmAccent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Set a daily reminder")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.calmDeep)
                            Text("Meditate every day to build a lasting habit")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.calmMid)
                        }

                        Spacer()

                        NavigationLink(destination: SettingsView()) {
                            Text("Set Up")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.calmDeep)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.calmAccent))
                        }

                        Button { withAnimation { showReminderBanner = false } } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.90))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.calmAccent.opacity(0.25), lineWidth: 1))
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Daily Practice card
                DailyPracticeCard()
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                // Daily quote card
                DailyQuoteCard()
                    .padding(.horizontal, 24)
                    .padding(.top, 10)

                Spacer(minLength: 16)

                // Mood check-in
                if !(journal.moodEntries.first.map { Calendar.current.isDateInToday($0.date) } ?? false) {
                    VStack(spacing: 10) {
                        Text("How are you feeling today?")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { val in
                                let moodVal = [1, 3, 4, 6, 7][val - 1]
                                Button {
                                    selectedMood = moodVal
                                    journal.addMoodEntry(MoodEntry(mood: moodVal))
                                } label: {
                                    Text(moodVal.moodEmoji)
                                        .font(.system(size: 28))
                                        .padding(6)
                                        .background(Circle().fill(selectedMood == moodVal ? Color.white.opacity(0.25) : Color.clear))
                                }
                            }
                        }
                        if selectedMood != nil {
                            Text("Logged! ✓")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.calmAccent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1))
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)
                }

                // SOS Button
                Button { showSOS = true } label: {
                    HStack(spacing: 10) {
                        Text("✨")
                            .font(.system(size: 26))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Need Calm Now?")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                            Text("2-min breathing to ease anxiety instantly")
                                .font(.system(size: 12, weight: .regular))
                                .opacity(0.95)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .opacity(0.60)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.30, green: 0.88, blue: 0.98).opacity(0.18))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.30, green: 0.88, blue: 0.98).opacity(0.35), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

                // Navigation buttons — grouped expandable sections
                VStack(spacing: 10) {

                    // Meditation group
                    FeatureGroup(title: "Meditation", subtitle: "Guided & timed sessions", icon: "brain.head.profile", isExpanded: $expandMeditation) {
                        VStack(spacing: 10) {
                            if premium.isPremium {
                                NavigationLink(destination: MorningMeditationView()) {
                                    HomeButton(icon: "sunrise.fill", title: "Morning Meditation", subtitle: "Start your day with clarity")
                                }
                            } else {
                                Button { showPaywall = true } label: {
                                    HomeButton(icon: "sunrise.fill", title: "Morning Meditation", subtitle: "Start your day with clarity", locked: true)
                                }.buttonStyle(.plain)
                            }
                            if premium.isPremium {
                                NavigationLink(destination: SleepMeditationView()) {
                                    HomeButton(icon: "moon.stars.fill", title: "Sleep Meditation", subtitle: "Drift into deep restful sleep")
                                }
                            } else {
                                Button { showPaywall = true } label: {
                                    HomeButton(icon: "moon.stars.fill", title: "Sleep Meditation", subtitle: "Drift into deep restful sleep", locked: true)
                                }.buttonStyle(.plain)
                            }
                            NavigationLink(destination: MeditationTimerView()) {
                                HomeButton(icon: "timer", title: "Start Meditation", subtitle: "Countdown session")
                            }
                            if premium.isPremium {
                                NavigationLink(destination: MeditationTimerView(startSilent: true)) {
                                    HomeButton(icon: "bell.fill", title: "Silent Meditation", subtitle: "Sit in stillness, guided by a bell")
                                }
                            } else {
                                Button { showPaywall = true } label: {
                                    HomeButton(icon: "bell.fill", title: "Silent Meditation", subtitle: "Bell every 5 min to guide your breath", locked: true)
                                }.buttonStyle(.plain)
                            }
                            if premium.isPremium {
                                NavigationLink(destination: PersonalizedMeditationView()) {
                                    HomeButton(icon: "sparkles", title: "Personalized Meditation", subtitle: "Personalized session just for you")
                                }
                            } else {
                                Button { showPaywall = true } label: {
                                    HomeButton(icon: "sparkles", title: "Personalized Meditation", subtitle: "Personalized session just for you", locked: true)
                                }.buttonStyle(.plain)
                            }
                            NavigationLink(destination: BodyScanView()) {
                                HomeButton(icon: "figure.mind.and.body", title: "Body Scan", subtitle: "Guided head-to-toe relaxation")
                            }
                            if premium.isPremium {
                                NavigationLink(destination: SleepStoriesView()) {
                                    HomeButton(icon: "book.fill", title: "Sleep Stories", subtitle: "Calming narrated stories for sleep")
                                }
                            } else {
                                Button { showPaywall = true } label: {
                                    HomeButton(icon: "book.fill", title: "Sleep Stories", subtitle: "Calming narrated stories for sleep", locked: true)
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    // Breathing group
                    FeatureGroup(title: "Breathing", subtitle: "Box · 4-7-8 · Custom patterns", icon: "lungs.fill", isExpanded: $expandBreathing) {
                        NavigationLink(destination: BreathingView()) {
                            HomeButton(icon: "lungs.fill", title: "Breathing Exercise", subtitle: "Box · 4-7-8 · Custom")
                        }
                    }

                    // Sounds group
                    FeatureGroup(title: "Sounds & Music", subtitle: "Nature sounds & ambient music", icon: "waveform", isExpanded: $expandSounds) {
                        VStack(spacing: 10) {
                            NavigationLink(destination: RelaxingSoundsView()) {
                                HomeButton(icon: "waveform", title: "Relaxing Sounds", subtitle: "Nature & ambient sounds")
                            }
                            if premium.isPremium {
                                NavigationLink(destination: AmbientMusicView()) {
                                    HomeButton(icon: "music.note", title: "Ambient Music", subtitle: "Focus · Sleep · Creativity")
                                }
                            } else {
                                Button { showPaywall = true } label: {
                                    HomeButton(icon: "music.note", title: "Ambient Music", subtitle: "Focus · Sleep · Creativity", locked: true)
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    NavigationLink(destination: ProgressTabView()) {
                        HomeButton(icon: "chart.bar.fill", title: "Progress", subtitle: "Stats & streaks")
                    }
                    NavigationLink(destination: AICoachHubView()) {
                        HomeButton(icon: "sparkles", title: "AI Coach", subtitle: "Mood & sleep insights")
                    }
                    NavigationLink(destination: SettingsView()) {
                        HomeButton(icon: "gearshape", title: "Settings", subtitle: "Reminders & preferences")
                    }
                }
                .padding(.horizontal, 24)

                // Streak badge
                if journal.currentStreak > 0 {
                    HStack(spacing: 10) {
                        Text("🔥")
                            .font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(journal.currentStreak)-day streak")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Keep it going — meditate today!")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.white.opacity(0.75))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(red: 1.0, green: 0.55, blue: 0.20).opacity(0.18))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(red: 1.0, green: 0.55, blue: 0.20).opacity(0.35), lineWidth: 1))
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }

                // Gratitude prompt
                if !journal.gratitudeEntryToday && !gratitudeSaved {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Text("🙏")
                                .font(.system(size: 16))
                            Text("What are you grateful for today?")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        TextField("Write something...", text: $gratitudeText)
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.10)))
                            .submitLabel(.done)
                            .onSubmit {
                                if !gratitudeText.trimmingCharacters(in: .whitespaces).isEmpty {
                                    journal.addGratitudeEntry(gratitudeText)
                                    gratitudeSaved = true
                                }
                            }
                        if !gratitudeText.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button {
                                journal.addGratitudeEntry(gratitudeText)
                                gratitudeSaved = true
                            } label: {
                                Text("Save")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.calmDeep)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(Color.calmAccent))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1))
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                } else if gratitudeSaved {
                    HStack(spacing: 8) {
                        Text("🙏")
                        Text("Gratitude saved for today")
                            .font(.system(size: 13, weight: .light))
                            .foregroundColor(.white.opacity(0.70))
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }

                Spacer(minLength: 16)

                Text("Take a moment for yourself")
                    .font(.caption)
                    .foregroundColor(.calmMid.opacity(0.70))

                HStack(spacing: 10) {
                    Label("No login required", systemImage: "person.slash.fill")
                    Label("Data stays on device", systemImage: "lock.shield.fill")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.70))
                .padding(.top, 4)

                DisclaimerFooter()
                    .padding(.bottom, 12)
            }
            } // ScrollView
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
                .environmentObject(premium)
        }
        .fullScreenCover(isPresented: $showSOS) {
            SOSBreathingView()
        }
        .onAppear {
            if !userPrefs.dailyReminderEnabled {
                withAnimation(.easeInOut(duration: 0.4).delay(1.0)) {
                    showReminderBanner = true
                }
            }
        }
    }
}

// MARK: - Daily Quote Card
struct DailyQuoteCard: View {
    private static let quotes: [(text: String, author: String)] = [
        ("Breathe. Let go. And remind yourself that this very moment is the only one you know you have for sure.", "Oprah Winfrey"),
        ("Almost everything will work again if you unplug it for a few minutes, including you.", "Anne Lamott"),
        ("Nothing can bring you peace but yourself.", "Ralph Waldo Emerson"),
        ("He who is not every day conquering some fear has not learned the secret of life.", "Ralph Waldo Emerson"),
        ("In the middle of difficulty lies opportunity.", "Albert Einstein"),
        ("Imagination is more important than knowledge.", "Albert Einstein"),
        ("In the depth of winter, I finally learned that within me there lay an invincible summer.", "Albert Camus"),
        ("You are the sky. Everything else is just the weather.", "Pema Chödrön"),
        ("The soul always knows what to do to heal itself. The challenge is to silence the mind.", "Caroline Myss"),
        ("A moment of self-compassion can change your entire day.", "Christopher Germer"),
        ("Rest when you're weary. Refresh and renew yourself, your body, your mind, your spirit.", "Ralph Marston"),
        ("With the new day comes new strength and new thoughts.", "Eleanor Roosevelt"),
        ("You gain strength, courage and confidence by every experience in which you really stop to look fear in the face.", "Eleanor Roosevelt"),
        ("Slow down and everything you are chasing will come around and catch you.", "John De Paola"),
        ("The thing about meditation is: you become more and more you.", "David Lynch"),
        ("There is something wonderfully bold and liberating about saying yes to our entire imperfect and messy life.", "Tara Brach"),
        ("Go within every day and find the inner strength so that the world will not blow your candle out.", "Katherine Dunham"),
        ("The best way to capture moments is to pay attention. This is how we cultivate mindfulness.", "Jon Kabat-Zinn"),
        ("Mindfulness isn't difficult, we just need to remember to do it.", "Sharon Salzberg"),
        ("Wherever you go, there you are.", "Jon Kabat-Zinn"),
        ("You cannot always control what goes on outside. But you can always control what goes on inside.", "Wayne Dyer"),
        ("Surrender to what is. Let go of what was. Have faith in what will be.", "Sonia Ricotti"),
        ("Your mind is a garden. Your thoughts are the seeds. You can grow flowers or you can grow weeds.", "William Wordsworth"),
        ("Meditation is the tongue of the soul and the language of our spirit.", "Jeremy Taylor"),
        ("You don't have to control your thoughts. You just have to stop letting them control you.", "Dan Millman"),
        ("Within you, there is a stillness and sanctuary to which you can retreat at any time.", "Hermann Hesse"),
        ("Breathe deeply, until sweet air extinguishes the burn of fear in your lungs.", "Arthur Golden"),
        ("One conscious breath in and out is a meditation.", "Eckhart Tolle"),
        ("In today's rush, we all think too much, seek too much, want too much and forget about the joy of just being.", "Eckhart Tolle"),
        ("The present moment always will have been.", "Eckhart Tolle"),
        ("Realise deeply that the present moment is all you ever have.", "Eckhart Tolle"),
        ("Whatever the present moment contains, accept it as if you had chosen it.", "Eckhart Tolle"),
        ("Meditation is not a way of making your mind quiet. It is a way of entering into the quiet that is already there.", "Deepak Chopra"),
        ("What we think, we become.", "Marcus Aurelius"),
        ("You have power over your mind, not outside events. Realize this and you will find strength.", "Marcus Aurelius"),
        ("Nowhere can man find a quieter or more untroubled retreat than in his own soul.", "Marcus Aurelius"),
        ("Very little is needed to make a happy life; it is all within yourself, in your way of thinking.", "Marcus Aurelius"),
        ("We suffer more in imagination than in reality.", "Seneca"),
        ("Begin at once to live, and count each separate day as a separate life.", "Seneca"),
        ("It is not that we have a short time to live, but that we waste much of it.", "Seneca"),
        ("Luck is what happens when preparation meets opportunity.", "Seneca"),
        ("No man is free who is not master of himself.", "Epictetus"),
        ("Make the best use of what is in your power, and take the rest as it happens.", "Epictetus"),
        ("He who laughs at himself never runs out of things to laugh at.", "Epictetus"),
        ("First say to yourself what you would be; and then do what you have to do.", "Epictetus"),
        ("Knowing yourself is the beginning of all wisdom.", "Aristotle"),
        ("The unexamined life is not worth living.", "Socrates"),
        ("The secret of happiness is not found in seeking more, but in developing the capacity to enjoy less.", "Socrates"),
        ("Be kind, for everyone you meet is fighting a harder battle.", "Plato"),
        ("An investment in knowledge pays the best interest.", "Benjamin Franklin"),
        ("The heart is like a garden. It can grow compassion or fear, resentment or love.", "Jack Kornfield"),
        ("The spiritual journey is the unlearning of fear and the acceptance of love.", "Marianne Williamson"),
        ("We are not human beings having a spiritual experience. We are spiritual beings having a human experience.", "Pierre Teilhard de Chardin"),
        ("The greatest weapon against stress is our ability to choose one thought over another.", "William James"),
        ("Your calm mind is the ultimate weapon against your challenges.", "Bryant McGill"),
        ("The only way out is through.", "Robert Frost"),
        ("I took a deep breath and listened to the old brag of my heart: I am, I am, I am.", "Sylvia Plath"),
        ("There is no path to happiness: happiness is the path.", "Wayne Dyer"),
        ("You yourself, as much as anybody in the entire universe, deserve your love.", "Jack Kornfield"),
        ("In three words I can sum up everything I've learned about life: it goes on.", "Robert Frost"),
        ("The mind is everything. What you think you become.", "William James"),
        ("Not everything that is faced can be changed, but nothing can be changed until it is faced.", "James Baldwin"),
        ("The privilege of a lifetime is to become who you truly are.", "Carl Jung"),
        ("Until you make the unconscious conscious, it will direct your life and you will call it fate.", "Carl Jung"),
        ("Everything can be taken from a man but one thing: the freedom to choose one's attitude.", "Viktor Frankl"),
        ("Between stimulus and response there is a space. In that space is our power to choose.", "Viktor Frankl"),
        ("Life is not measured by the number of breaths we take, but by the moments that take our breath away.", "Maya Angelou"),
        ("You can't go back and change the beginning, but you can start where you are and change the ending.", "C.S. Lewis"),
        ("We are what we repeatedly do. Excellence, then, is not an act, but a habit.", "Aristotle"),
        ("The only limits of our realization of tomorrow will be our doubts of today.", "Franklin D. Roosevelt"),
        ("Success is not final, failure is not fatal: it is the courage to continue that counts.", "Winston Churchill"),
        ("A calm and modest life brings more happiness than the pursuit of success combined with constant restlessness.", "Albert Einstein"),
        ("Peace is not the absence of conflict, but the ability to handle conflict by peaceful means.", "Ronald Reagan"),
        ("Serenity is not freedom from the storm, but peace amid the storm.", "Ralph Waldo Emerson"),
        ("Life is 10% what happens to you and 90% how you respond to it.", "Charles R. Swindoll"),
        ("It always seems impossible until it's done.", "Nelson Mandela"),
        ("Do not wait for leaders; do it alone, person to person.", "Mother Teresa"),
        ("The quieter you become, the more you can hear.", "Ram Dass"),
        ("Be here now.", "Ram Dass"),
        ("You have brains in your head. You have feet in your shoes. You can steer yourself any direction you choose.", "Dr. Seuss"),
        ("A quiet mind is able to hear intuition over fear.", "Yvan Byeajee"),
        ("Worrying does not take away tomorrow's troubles. It takes away today's peace.", "Randy Armstrong"),
        ("The greatest healing therapy is friendship and love.", "Hubert H. Humphrey"),
        ("Almost everything will work again if you give it space and time.", "Anne Lamott"),
        ("Inhale confidence, exhale doubt.", "Lori Deschene"),
        ("Silence is the sleep that nourishes wisdom.", "Francis Bacon"),
        ("Take rest; a field that has rested gives a bountiful crop.", "Ovid"),
        ("Within calm, a warrior finds focus. Within focus, a warrior finds clarity.", "Ryan Holiday"),
        ("You are allowed to be both a masterpiece and a work in progress simultaneously.", "Sophia Bush"),
        ("Breathe. You are exactly where you need to be.", "Lori Deschene"),
        ("Rest is not idleness, and to lie sometimes on the grass on a summer day is by no means a waste of time.", "John Lubbock"),
        ("Nothing is worth more than this day.", "Johann Wolfgang von Goethe"),
        ("One day at a time — this is enough. Do not look back and grieve over the past, for it is gone.", "Ida Scott Taylor"),
        ("If you are distressed by anything external, the pain is not due to the thing itself but to your estimate of it.", "Marcus Aurelius"),
        ("To be yourself in a world that is constantly trying to make you something else is the greatest accomplishment.", "Ralph Waldo Emerson"),
        ("The best time to repair the roof is when the sun is shining.", "John F. Kennedy"),
        ("Take care of your body. It's the only place you have to live.", "Jim Rohn"),
        ("Each morning is a new beginning, a fresh start.", "Joel Osteen"),
        ("Peace comes from within. Do not seek it without.", "Buddha"),
        ("Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment.", "Buddha"),
        ("You yourself, as much as anybody in the entire universe, deserve your love and affection.", "Buddha"),
        ("Three things cannot be long hidden: the sun, the moon, and the truth.", "Buddha"),
        ("Each morning we are born again. What we do today matters most.", "Buddha"),
        ("The mind is everything. What you think, you become.", "Buddha"),
        ("Health is the greatest gift, contentment the greatest wealth, faithfulness the best relationship.", "Buddha"),
        ("In the end, only three things matter: how much you loved, how gently you lived, and how gracefully you let go.", "Buddha"),
        ("If you light a lamp for somebody, it will also brighten your path.", "Buddha"),
        ("No one saves us but ourselves. No one can and no one may. We ourselves must walk the path.", "Buddha"),
        ("Happiness never decreases by being shared.", "Buddha"),
        ("The way is not in the sky. The way is in the heart.", "Buddha"),
        ("Better than a thousand hollow words is one word that brings peace.", "Buddha"),
        ("Holding onto anger is like drinking poison and expecting the other person to die.", "Buddha"),
        ("A disciplined mind brings happiness.", "Buddha"),
        ("Be where you are, otherwise you will miss your life.", "Buddha"),
        ("If you find no one to support you on the spiritual path, walk alone.", "Buddha"),
        ("You will not be punished for your anger, you will be punished by your anger.", "Buddha"),
        ("To understand everything is to forgive everything.", "Buddha"),
        ("Every morning we are born again. What we do today matters most.", "Buddha"),
    ]

    private var todayQuote: (text: String, author: String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return Self.quotes[(dayOfYear - 1) % Self.quotes.count]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.70))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(todayQuote.text)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineSpacing(3)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("— \(todayQuote.author)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Feature Group (expandable)
struct FeatureGroup<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.10, green: 0.22, blue: 0.42))
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color(red: 0.10, green: 0.22, blue: 0.42).opacity(0.08)))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                            .foregroundColor(Color(red: 0.10, green: 0.22, blue: 0.42))
                        Text(subtitle)
                            .font(.system(.caption))
                            .foregroundColor(Color(red: 0.10, green: 0.22, blue: 0.42).opacity(0.55))
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.10, green: 0.22, blue: 0.42).opacity(0.50))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 15)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    content()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: - Home Navigation Button
struct HomeButton: View {
    let icon: String
    let title: String
    let subtitle: String
    var locked: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon badge
            ZStack {
                Circle()
                    .fill(Color.calmDeep.opacity(locked ? 0.05 : 0.10))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(locked ? .calmDeep.opacity(0.40) : .calmDeep)
            }

            // Labels
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(locked ? .calmDeep.opacity(0.45) : .calmDeep)
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.calmMid.opacity(0.50))
                    }
                }
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.calmMid.opacity(locked ? 0.45 : 0.75))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.calmMid.opacity(0.45))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)
        )
    }
}

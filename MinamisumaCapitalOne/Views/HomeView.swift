//
//  HomeView.swift
//  MinamisumaCapitalOne
//
//  Senior-friendly banking home screen — fits on one screen, no scroll
//

import SwiftUI


// MARK: - Home View

struct HomeView: View {
    @State private var notificationCount: Int = 3
    @State private var showVoiceGuide: Bool = false

    let card = BankCard(
        holderName: "Lorenzo",
        cardType: "Amazon Platinium",
        lastFour: "9018",
        firstFour: "4756",
        balance: 3469.52,
        network: "visa"
    )

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let h = geo.size.height

                VStack(spacing: 0) {

                    // Header
                    headerSection
                        .padding(.bottom, h * 0.02)

                    // Card
                    cardSection
                        .frame(height: h * 0.25)
                        .padding(.bottom, h * 0.025)

                    // Menu Buttons Grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: h * 0.015
                    ) {

                        MenuButton(
                            title: "Retirar",
                            icon: "banknote.fill",
                            destination: AnyView(
                                RetirarView()
                            )
                        )

                        MenuButton(
                            title: "Enviar dinero",
                            icon: "arrow.right.circle.fill",
                            destination: AnyView(
                                TransferenciaView()
                            )
                        )

                        MenuButton(
                            title: "Movimientos",
                            icon: "list.bullet.rectangle.fill",
                            destination: AnyView(
                                MovimientosView()
                            )
                        )

                        MenuButton(
                            title: "Familia",
                            icon: "person.2.fill",
                            destination: AnyView(
                                TrustedContactsListView()
                            )
                        )

                        MenuButton(
                            title: "Ayuda",
                            icon: "questionmark.circle.fill",
                            destination: AnyView(
                                AyudaView()
                            )
                        )
                    }
                    .frame(height: h * 0.33)

                    Spacer()

                    // Bottom Buttons
                    bottomButtons
                        .padding(.bottom, h * 0.01)
                }
                .padding(.horizontal, 20)
                .frame(height: h)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {

            HStack(spacing: 10) {
                Image(systemName: "person.fill")
                    .font(.system(size: 22))

                Text("Hola, \(card.holderName)")
                    .font(.system(size: 26, weight: .bold))
            }

            Spacer()

            ZStack(alignment: .topTrailing) {

                Button(action: {}) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22))
                }

                if notificationCount > 0 {
                    Text("\(notificationCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
    }

    // MARK: - Card

    private var cardSection: some View {

        ZStack {

            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [.black, Color(red: 0.1, green: 0.1, blue: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    ZStack {

                        Circle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 160, height: 160)
                            .offset(x: 100, y: -40)

                        Circle()
                            .fill(Color.blue.opacity(0.5))
                            .frame(width: 120, height: 120)
                            .offset(x: 40, y: 20)

                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 180, height: 180)
                            .offset(x: 60, y: 30)
                    }
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18)
                    )
                )

            VStack(alignment: .leading, spacing: 4) {

                Text(card.holderName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text(card.cardType)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))

                HStack(spacing: 6) {

                    Text(card.firstFour)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))

                    Text("••••  ••••")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))

                    Text(card.lastFour)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.8))


                HStack(alignment: .bottom) {

                    Text(balanceFormatted)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Text("VISA")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .italic()
                        .foregroundColor(.white)
                }
            }
            .padding(20)
        }
    }


    private var balanceFormatted: String {

        let formatter = NumberFormatter()

        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.locale = Locale(identifier: "en_US")

        return formatter.string(
            from: NSNumber(value: card.balance)
        ) ?? "$0.00"
    }


    // MARK: - Bottom Buttons

    private var bottomButtons: some View {

        HStack(spacing: 12) {

            Button(action: {
                showVoiceGuide.toggle()
            }) {

                HStack(spacing: 6) {

                    Image(systemName: "speaker.wave.2.fill")

                    Text("Activa la guía por voz")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.black)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
            }


            NavigationLink(
                destination: ProfileView()
            ) {

                HStack(spacing: 6) {

                    Image(systemName: "gearshape.fill")

                    Text("Configurar perfil")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Color(.systemGray3),
                            lineWidth: 1.5
                        )
                )
            }
        }
    }
}


// MARK: - Menu Button

struct MenuButton: View {

    let title: String
    let icon: String
    let destination: AnyView


    var body: some View {

        NavigationLink(destination: destination) {

            VStack(spacing: 10) {

                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 95)
            .background(Color(.systemBackground))
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .shadow(
                color: .black.opacity(0.04),
                radius: 4,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Placeholder View

struct PlaceholderView: View {

    let title: String


    var body: some View {

        VStack(spacing: 16) {

            Image(systemName: "hammer.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(title)
                .font(.system(size: 28, weight: .bold))

            Text("Próximamente")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}


// MARK: - Preview

#Preview {

    HomeView()
}

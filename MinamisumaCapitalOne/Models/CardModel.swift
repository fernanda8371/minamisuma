//
//  CardModel.swift
//  MinamisumaCapitalOne
//
//  Created by Daniela Caiceros on 10/04/26.
//

import Foundation

struct BankCard: Identifiable {
    let id = UUID()
    let holderName: String
    let cardType: String
    let lastFour: String
    let firstFour: String
    let balance: Double
    let network: String
}

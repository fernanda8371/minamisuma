//
//  SupabaseManager.swift
//  MinamisumaCapitalOne
//

import Foundation
import Supabase

struct SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://gsvjlyiszplcagwvphor.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdzdmpseWlzenBsY2Fnd3ZwaG9yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4MzQ2MTMsImV4cCI6MjA5MTQxMDYxM30.ILGKAmgvOjiYGoyk16UBb2VtgKpcnZJx4nfNekvjFxQ"
    )
}

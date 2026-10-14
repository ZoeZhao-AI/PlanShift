// Module: M1 – placeholder for M1-04 Delete Confirmation (alert).

import SwiftUI

extension View {
    /// M1-04 Delete Confirmation. Placeholder: the M1 owner finalises the wording.
    func deleteConfirmationAlert(isPresented: Binding<Bool>, onDelete: @escaping () -> Void) -> some View {
        alert("M1-04 Delete Confirmation", isPresented: isPresented) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    Text("Behind the alert")
        .deleteConfirmationAlert(isPresented: .constant(true)) {}
}

import SwiftUI

struct PublishedServiceDiscrepancyCard: View {
    let notice: PublishedServiceDiscrepancy

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(notice.title, systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            Text(notice.detail)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Link(destination: notice.sourceURL) {
                    Label(notice.sourceTitle, systemImage: "arrow.up.right.square")
                        .font(.caption)
                }

                Link(destination: notice.timetableURL) {
                    Label(notice.timetableTitle, systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                }

                Link(destination: notice.gtfsSourceURL) {
                    Label(notice.gtfsSourceTitle, systemImage: "tablecells")
                        .font(.caption)
                }
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

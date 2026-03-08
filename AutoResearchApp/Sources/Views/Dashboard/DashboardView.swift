import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StatusHeaderView()
                MetricsGridView()
                BPBChartView()
                SummarySectionView()
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}

//
//  RankingWeights.swift
//  PlanShift
//
//  Created by Van Dao Le on 15/10/2026.
//

// Module: M2 – the documented, tested score weights, kept as a vector so the code reads like the formula.

import Foundation

/// The six things a place is scored on. The order is the order of the vectors below.
nonisolated enum ScoreComponent: Int, CaseIterable, Sendable {
    case disruptionFit  // does the place suit the chosen disruption?
    case settingFit     // indoor / outdoor fit
    case distance       // how near
    case duration       // visit length vs. the time slot
    case budget         // price
    case hours          // opening hours vs. the time slot
}

/// A place's score on each `ScoreComponent`, every one in 0...1 (the vector **c**).
nonisolated struct ComponentScores: Sendable {
    private let values: [Double]

    /// Every component is required, so none can be forgotten.
    init(disruptionFit: Double, settingFit: Double, distance: Double, duration: Double, budget: Double, hours: Double) {
        values = [disruptionFit, settingFit, distance, duration, budget, hours]
    }

    subscript(_ component: ScoreComponent) -> Double { values[component.rawValue] }
}

/// The weight of each component for one disruption (the vector **w**), summing to 1, so a final score is
/// also 0...1:
///
///     S(p) = w · c(p) = Σₖ wₖ · cₖ(p)        with  Σₖ wₖ = 1
///
/// | Disruption          | fit | setting | distance | duration | budget | hours |
/// |---------------------|-----|---------|----------|----------|--------|-------|
/// | Rainy weather       | .30 | .30     | .15      | .10      | .05    | .10   |
/// | Attraction closed   | .25 | .25     | .20      | .15      | .10    | .05   |
/// | Transport delay     | .10 | .10     | .50      | .10      | .10    | .10   |
/// | Running out of time | .10 | .05     | .20      | .45      | .10    | .10   |
///
/// The numbers live on `Disruption.rankingWeights` below. Tests assert the sum and the intended ordering effects.
nonisolated struct RankingWeights: Equatable, Sendable {
    private let values: [Double]
    /// λ: subtracted from a candidate that shares a suburb with an already chosen result,
    /// so the top 3 are not all the same neighbourhood.
    let diversityPenalty: Double

    /// Every `ScoreComponent` must be given a weight; a missing one is a programming error.
    init(_ weights: [ScoreComponent: Double], diversityPenalty: Double = 0.08) {
        values = ScoreComponent.allCases.map { component in
            guard let weight = weights[component] else { preconditionFailure("missing ranking weight for \(component)") }
            return weight
        }
        self.diversityPenalty = diversityPenalty
        assert(abs(values.reduce(0, +) - 1) < 1e-9, "ranking weights must sum to 1")
    }

    subscript(_ component: ScoreComponent) -> Double { values[component.rawValue] }

    /// Σ wₖ — must be 1.
    var total: Double { values.reduce(0, +) }

    /// The weighted score S = Σₖ wₖ · cₖ, in 0...1.
    func score(_ scores: ComponentScores) -> Double {
        ScoreComponent.allCases.reduce(0) { $0 + self[$1] * scores[$1] }
    }
}

extension Disruption {
    /// How much each component matters for this disruption. Kept here (an extension in M2) rather than in
    /// the shared `Disruption` file, because ranking policy is M2's business, not the shared domain's.
    nonisolated var rankingWeights: RankingWeights {
        switch self {
        case .rainyWeather:
            RankingWeights([.disruptionFit: 0.30, .settingFit: 0.30, .distance: 0.15, .duration: 0.10, .budget: 0.05, .hours: 0.10])
        case .attractionClosed:
            RankingWeights([.disruptionFit: 0.25, .settingFit: 0.25, .distance: 0.20, .duration: 0.15, .budget: 0.10, .hours: 0.05])
        case .transportDelay:
            RankingWeights([.disruptionFit: 0.10, .settingFit: 0.10, .distance: 0.50, .duration: 0.10, .budget: 0.10, .hours: 0.10])
        case .runningOutOfTime:
            RankingWeights([.disruptionFit: 0.10, .settingFit: 0.05, .distance: 0.20, .duration: 0.45, .budget: 0.10, .hours: 0.10])
        }
    }
}

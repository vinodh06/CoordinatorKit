//
//  ActionDispatcher.swift
//  CoordinatorKit
//
//  Created by Vinodhkumar Govindaraj on 02/07/25.
//


import Combine

public final class ActionDispatcher<Action>: ObservableObject {
    private let subject = PassthroughSubject<Action, Never>()

    public var publisher: AnyPublisher<Action, Never> {
        subject.eraseToAnyPublisher()
    }

    public init() {}

    public func send(_ action: Action) {
        subject.send(action)
    }
}

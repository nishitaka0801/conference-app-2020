//
//  SessionViewModel.swift
//  DroidKaigi 2020
//
//  Created by 伊藤凌也 on 2020/01/18.
//

import RxSwift
import RxCocoa

final class SessionViewModel {

    private let disposeBag = DisposeBag()

    // input
    let viewDidLoad = PublishRelay<Void>()
    let toggleEmbddedView = PublishRelay<Void>()

    // output
    let isFocusedOnEmbeddedView: Driver<Bool>
    let sessions: Driver<[Session]>

    init() {
        let isFocusedOnEmbeddedViewRelay = BehaviorRelay<Bool>(value: true)
        let sessionsRelay = BehaviorRelay<[Session]>(value: [])

        self.isFocusedOnEmbeddedView = isFocusedOnEmbeddedViewRelay.asDriver()
        self.sessions = sessionsRelay.asDriver()

        let dataProvider = SessionDataProvider()
        let service = SessionService()

        let sessionsRequested = viewDidLoad.asObservable()
            .flatMap { dataProvider.fetchSessions().materialize() }
            .share()

        // success
        sessionsRequested
            .flatMap { $0.element.map(Observable.just) ?? .empty() }
            .map(service.convertSessionResponse(response:))
            .bind(to: sessionsRelay)
            .disposed(by: disposeBag)

        // failure
        /// TODO: Error handling
        sessionsRequested
            .flatMap { $0.error.map(Observable.just) ?? .empty() }

        toggleEmbddedView
            .withLatestFrom(isFocusedOnEmbeddedViewRelay)
            .map { !$0 }
            .bind(to: isFocusedOnEmbeddedViewRelay)
            .disposed(by: disposeBag)
    }
}
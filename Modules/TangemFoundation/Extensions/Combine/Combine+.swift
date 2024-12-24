//
//  Combine+.swift
//  TangemModules
//
//  Created by Sergey Balashov on 24.12.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

/// Same as `AnyPublisher` but `Failure == Never`
public typealias AnyValuePublisher<Value> = AnyPublisher<Value, Never>

/// Same as `CurrentValueSubject` but `Failure == Never`
public typealias ValueSubject<Value> = CurrentValueSubject<Value, Never>

/// Same as `PassthroughSubject` but `Failure == Never`
public typealias PassthroughValueSubject<Value> = PassthroughSubject<Value, Never>

//
//  HttpDecodableService.swift
//  DataFramework
//
//  Created by Alex on 3/29/18.
//  Copyright © 2018 Alex. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

public protocol DecodableDataFilterProtocol {

    associatedtype DecodableType: Decodable

}

public final class HttpDecodableService<FilterType: HttpDataFilterProtocol & DecodableDataFilterProtocol>: ServiceProtocol {

    public typealias ResultType = HttpResponse<FilterType.DecodableType>

    private let httpService: HttpService<FilterType>

    convenience init?(baseUrl: String) {
        guard let url = URL(string: baseUrl) else {
            return nil
        }
        self.init(baseUrl: url)
    }

    public init(baseUrl: URL) {
        self.httpService = HttpService(baseUrl: baseUrl)
    }

    public func request(filter: FilterType) -> SignalProducer<ResultType, ServiceError> {
        var jsonFilter = filter
        jsonFilter.headerParams[HTTP.HeaderKey.accept] = HTTP.Accept.json
        return httpService.request(filter: jsonFilter).flatMap(.latest) { (result) -> SignalProducer<ResultType, ServiceError> in
            do {
                let jsonDecoder = JSONDecoder()
                let parsedData = try jsonDecoder.decode(FilterType.DecodableType.self, from: result.data)
                return SignalProducer(value: HttpResponse(data: parsedData, response: result.response))
            } catch let error {
                return SignalProducer(error: .invalidJson(error))
            }
        }
    }

}

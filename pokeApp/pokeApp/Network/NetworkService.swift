//
//  NetworkService.swift
//  pokeApp
//
//  Created by Faiq Adi on 06/11/25.
//
import Foundation
import Alamofire
import RxSwift
import RxCocoa


// MARK: - Network Layer Protocol
protocol NetworkRequest {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
    var headers: HTTPHeaders? { get }
    var encoding: ParameterEncoding { get }
}

extension NetworkRequest {
    var headers: HTTPHeaders? { nil }
    var encoding: ParameterEncoding {
        method == .get ? URLEncoding.default : JSONEncoding.default
    }
}

// MARK: - Network Error
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(Int)
    case unknown(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}


class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    /// Generic request with RxSwift Observable
    func request<T: Decodable>(
        _ endpoint: NetworkRequest,
        responseType: T.Type
    ) -> Observable<T> {
        return Observable.create { observer in
            let urlString = endpoint.baseURL + endpoint.path
            print("urlString = \(urlString)")
            let request = AF.request(
                urlString,
                method: endpoint.method,
                parameters: endpoint.parameters,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let data):
                    observer.onNext(data)
                    observer.onCompleted()
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        observer.onError(NetworkError.serverError(statusCode))
                    } else if error.isResponseSerializationError {
                        observer.onError(NetworkError.decodingError(error))
                    } else {
                        observer.onError(NetworkError.unknown(error))
                    }
                }
            }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    /// Generic request with RxSwift Single
    func requestSingle<T: Decodable>(
        _ endpoint: NetworkRequest,
        responseType: T.Type
    ) -> Single<T> {
        return request(endpoint, responseType: responseType).asSingle()
    }
}

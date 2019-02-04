//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation
import Alamofire
//TODO: add default (for any request) headers (overrideable)
//TODO: add logger object through protocol
//TODO: PATCH
//TODO: use alamofire directly
public enum HTTPClientConstant {
    public static let defaultTimeoutInterval: TimeInterval = 60.0
}

final public class HTTPClient {

    public enum RequestMethod: String {

        case GET
        case POST
        case PUT
        case DELETE

        internal func alamofireMethod() -> Alamofire.HTTPMethod {
            switch self {
            case .GET: return Alamofire.HTTPMethod.get
            case .POST: return Alamofire.HTTPMethod.post
            case .PUT: return Alamofire.HTTPMethod.put
            case .DELETE: return Alamofire.HTTPMethod.delete
            }
        }

    }

    public enum ParameterEncoding {

        case URLQuery
        case JSON

        internal func alamofireEncoding() -> Alamofire.ParameterEncoding {
            switch self {
            case .URLQuery: return Alamofire.URLEncoding(destination: URLEncoding.Destination.queryString)
            case .JSON: return Alamofire.JSONEncoding()
            }
        }

    }

    public enum Response<ResultType> {
        case success(networkResult: ResultType)
        case cancelled
        case failure(networkError: Error)
    }

    /**
     Essentially this condensed `SendRequestOptions` (after authorizer and stuff)
     */
    private struct RequestData: URLRequestConvertible {

        internal let urlString: String
        internal let method: HTTPMethod
        internal let headers: HTTPHeaders
        internal let timeoutInterval: TimeInterval
        internal let parameterEncoding: Alamofire.ParameterEncoding
        internal let parameters: Alamofire.Parameters?

        internal func asURLRequest() throws -> URLRequest {
            var request = try URLRequest(url: urlString, method: method, headers: headers)
            request.timeoutInterval = timeoutInterval
            let encodedURLRequest = try parameterEncoding.encode(request, with: parameters)
            return encodedURLRequest
        }

    }

    public struct RequestOptions<ParserType: HTTPClientParserProtocol> {

        public let method: HTTPClient.RequestMethod
        public let endpoint: HTTPClientAPIEndPoint
        public let parser: ParserType.Type
        public var userSession: HTTPClientUserSession?
        public var parameters: [String: Any]?
        public var parametersEncoding: HTTPClient.ParameterEncoding?
        public var headers: [String: String] = [:] // applied after auth headers from session
        public var authCredential: URLCredential?
        public var timeoutInterval: TimeInterval = HTTPClientConstant.defaultTimeoutInterval
        public var completionHandler: (_ response: HTTPClient.Response<ParserType.ResultType>, _ session: HTTPClientUserSession?) -> Void = { (_, _) in }

        public init(method aMethod: HTTPClient.RequestMethod,
                    endpoint aEndpoint: HTTPClientAPIEndPoint,
                    parser aParser: ParserType.Type) {
            method = aMethod
            endpoint = aEndpoint
            parser = aParser
        }

    }

    // submodules
    private let manager: Alamofire.SessionManager
    private let callbackQueue: DispatchQueue

    // options
    private let acceptableStatusCodes: [Int]
    private let acceptableContentTypes: [String]
    private let defaultGETHeaders: [String: String]
    private let defaultPOSTHeaders: [String: String]
    public var isDebugLogEnabled: Bool = false

    // MARK: - Initialization

    init(name: String,
         configuration: URLSessionConfiguration? = nil,
         acceptableStatusCodes aAcceptableStatusCodes: [Int] = Array(200..<300),
         acceptableContentTypes aAcceptableContentTypes: [String] = ["application/json", "application/vnd.api+json"],
         requestContentTypes: [String] = ["application/json"]) {

        let config: URLSessionConfiguration
        if let realConfig = configuration {
            config = realConfig
        } else {
            config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
        }
        manager = Alamofire.SessionManager(configuration: config)
        callbackQueue = DispatchQueue(label: "\(name).callbackQueue", attributes: DispatchQueue.Attributes.concurrent)

        acceptableStatusCodes = aAcceptableStatusCodes
        acceptableContentTypes = aAcceptableContentTypes
        defaultGETHeaders = [
            "Accept": acceptableContentTypes.joined(separator: ",")
        ]
        defaultPOSTHeaders = [
            "Accept": acceptableContentTypes.joined(separator: ","),
            "Content-Type": requestContentTypes.joined(separator: ",")
        ]
    }

    // MARK: - Public

    public func cancelAllTasks(_ completion: (() -> Void)? = nil) {
        manager.session.getTasksWithCompletionHandler { (dataTasks: [URLSessionDataTask], uploadTasks: [URLSessionUploadTask], downloadTasks: [URLSessionDownloadTask]) in
            for task in dataTasks {
                task.cancel()
            }
            for task in uploadTasks {
                task.cancel()
            }
            for task in downloadTasks {
                task.cancel()
            }
            if let callback: (() -> Void) = completion {
                callback()
            }
        }
    }

    public func sendRequest<ParserType: HTTPClientParserProtocol>(options: RequestOptions<ParserType>) -> HTTPClientRequest {
        let requestPrefab = formRequest(options: options)
        var request = manager.request(requestPrefab)
        if let credential = options.authCredential {
            request = request.authenticate(usingCredential: credential)
        }
        request = request.validate(statusCode: acceptableStatusCodes)
            .validate(contentType: acceptableContentTypes)
            .response(queue: callbackQueue, completionHandler: { [weak self] (response: DefaultDataResponse) in
                self?.printDebugLogIfNeeded(response: response)
                let parsedResult = HTTPClient.applyParser(response: response, parser: options.parser)
                options.completionHandler(parsedResult, options.userSession)
            })
        return request
    }

    public func uploadData<ParserType: HTTPClientParserProtocol>(_ data: Data, options: RequestOptions<ParserType>) -> HTTPClientRequest {
        let requestPrefab = formRequest(options: options)
        var request = manager.upload(data, with: requestPrefab)
        if let credential = options.authCredential {
            request = request.authenticate(usingCredential: credential)
        }
        request.validate(statusCode: acceptableStatusCodes)
            .validate(contentType: acceptableContentTypes)
            .response(queue: callbackQueue, completionHandler: { [weak self] (response: DefaultDataResponse) in
                self?.printDebugLogIfNeeded(response: response)
                let parsedResult = HTTPClient.applyParser(response: response, parser: options.parser)
                options.completionHandler(parsedResult, options.userSession)
            })
        return request
    }

    // MARK: - Private

    private func formHeaders(method: HTTPClient.RequestMethod,
                             endpoint: HTTPClientAPIEndPoint,
                             userSession: HTTPClientUserSession?,
                             additionalHeaders: [String: String]) -> [String: String] {
        var headers: [String: String]
        switch method {
        case .GET,
             .DELETE:
            headers = defaultGETHeaders
        case .POST,
             .PUT:
            headers = defaultPOSTHeaders
        }
        if let authHeaders = userSession?.httpHeaders() {
            for (key, value) in authHeaders {
                headers[key] = value
            }
        }
        for (key, value) in additionalHeaders {
            headers[key] = value
        }
        return headers
    }

    private func formRequest<ParserType: HTTPClientParserProtocol>(options: RequestOptions<ParserType>) -> RequestData {
        let requestHeaders = formHeaders(
            method: options.method,
            endpoint: options.endpoint,
            userSession: options.userSession,
            additionalHeaders: options.headers)
        let parameterEncoding: HTTPClient.ParameterEncoding
        switch options.method {
        case .GET,
             .DELETE:
            parameterEncoding = options.parametersEncoding ?? HTTPClient.ParameterEncoding.URLQuery
        case .POST,
             .PUT:
            parameterEncoding = options.parametersEncoding ?? HTTPClient.ParameterEncoding.JSON
        }
        return RequestData(urlString: options.endpoint.urlString(),
                           method: options.method.alamofireMethod(),
                           headers: requestHeaders,
                           timeoutInterval: options.timeoutInterval,
                           parameterEncoding: parameterEncoding.alamofireEncoding(),
                           parameters: options.parameters)
    }

    private static func applyParser<ParserType: HTTPClientParserProtocol>(response: DefaultDataResponse, parser: ParserType.Type) -> HTTPClient.Response<ParserType.ResultType> {
        if let nsError = response.error as NSError?, nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled { // this is really a !guard
            return .cancelled
        }

        let serializedResponseValue: ParserType.ResponseValueType?
        if let responseRawData = response.data {
            serializedResponseValue = parser.serializeResponseData(responseRawData)
        } else {
            serializedResponseValue = nil
        }

        let parserError = parser.parseError(serializedResponseValue, response: response.response, responseData: response.data)
        if let realParserError = parserError {
            return .failure(networkError: realParserError)
        }

        if let networkError = response.error {
            return .failure(networkError: networkError)
        }

        guard let responseValue = serializedResponseValue else {
            return .failure(networkError: HTTPClientError.serializationError)
        }

        guard let parsedObject = parser.parseObject(responseValue, response: response.response) else {
            return .failure(networkError: HTTPClientError.parseError)
        }

        return.success(networkResult: parsedObject)
    }

    private func printDebugLogIfNeeded(response: DefaultDataResponse) {
        #if DEBUG
            if isDebugLogEnabled {
                let responseBody: String
                if let data = response.data {
                    responseBody = String(data: data, encoding: String.Encoding.utf8) ?? "EMPTY"
                } else {
                    responseBody = "EMPTY"
                }
                debugPrint("request: \(String(describing: response.request)), response: \(String(describing: response.response)), responseBody: \(responseBody)")
            }
        #endif
    }

}

extension Alamofire.Request: HTTPClientRequest {}

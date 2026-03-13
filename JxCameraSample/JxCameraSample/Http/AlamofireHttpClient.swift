//
//  AlamofireHttpClient.swift
//  Polaroid
//
//  Created by jxcs on 2025/12/26.
//

import JxCameraSDK
import Alamofire

final class AlamofireHttpClient: JxHttpClient {

    private let session: Session

    init(
        connectTimeout: TimeInterval = 30,
        readTimeout: TimeInterval = 30,
        sslConfig: JxSSLConfiguration?,
        host: String
    ) {
        let configuration = URLSessionConfiguration.default
        configuration.allowsExpensiveNetworkAccess = false
        configuration.allowsConstrainedNetworkAccess = true
        configuration.timeoutIntervalForRequest = readTimeout
        configuration.timeoutIntervalForResource = connectTimeout

        if let sslConfig = sslConfig, sslConfig.isEnabled {
            var evaluators: [String: ServerTrustEvaluating] = [:]

            let certificates = sslConfig.pinnedCertificates.compactMap {
                SecCertificateCreateWithData(nil, $0 as CFData)
            }
            
            evaluators[host] = PinnedCertificatesTrustEvaluator(
                certificates: certificates,
                acceptSelfSignedCertificates: sslConfig.allowSelfSigned,
                performDefaultValidation: false,
                validateHost: sslConfig.validateHost
            )

            let trustManager = ServerTrustManager(
                allHostsMustBeEvaluated: false,
                evaluators: evaluators
            )
            
            print("App 使用 Alamofire + SSL Session")
            self.session = Session(
                configuration: configuration,
                serverTrustManager: trustManager
            )
        } else {
            print("App 使用 Alamofire Default Session")
            self.session = Session(configuration: configuration)
        }
    }

    func request(
        url: URL,
        method: JxHttpMethod,
        headers: [String: String]?,
        body: Data?,
        timeout: TimeInterval?,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {

        let httpMethod = HTTPMethod(rawValue: method.rawValue)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.httpBody = body
        if let timeout = timeout {
            urlRequest.timeoutInterval = timeout
        }

        headers?.forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }

        session.request(urlRequest)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}

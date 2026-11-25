import Foundation

/// The only URLSession in the Mac target. Callers must pass a request that
/// RegistrationGate already allowed. Nothing calls this during launch.
enum LiveBarkRegisterTransport {
    static func send(_ request: RegistrationRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        guard var components = URLComponents(url: request.url, resolvingAgainstBaseURL: false) else {
            completion(.failure(TransportError.badURL))
            return
        }
        components.queryItems = request.query.keys.sorted().map { name in
            URLQueryItem(name: name, value: request.query[name])
        }
        guard let url = components.url else {
            completion(.failure(TransportError.badURL))
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: urlRequest) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            completion(.success(data ?? Data()))
        }
        task.resume()
    }

    enum TransportError: Error {
        case badURL
    }
}

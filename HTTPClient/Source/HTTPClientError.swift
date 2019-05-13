//
// Copyright (c) 2018-2019 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import Foundation

public enum HTTPClientError: Swift.Error {
    case cantSerializeResponseData
    case cantParseSerializedResponse
    case httpClientDeallocated
}

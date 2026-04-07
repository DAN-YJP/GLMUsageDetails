import Foundation

// MARK: - Billing API Response Envelope

public struct BillingAPIEnvelope: Decodable, Sendable {
    let code: Int?
    let msg: String?
    let total: Int?
    let rows: [BillRow]?

    enum CodingKeys: String, CodingKey {
        case code, msg, total, rows
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decodeIfPresent(Int.self, forKey: .code)
        msg = try container.decodeIfPresent(String.self, forKey: .msg)
        total = FlexibleDecoding.envelopeInt(from: container, forKey: .total)
        rows = try container.decodeIfPresent([BillRow].self, forKey: .rows)
    }
}

// MARK: - Single Bill Row (matches Zhipu billing API response)
//
// Uses flexible decoding: numeric fields accept Int, Double, or String representations.

public struct BillRow: Decodable, Sendable, Equatable {
    let billingNo: String?
    let billingDate: String?
    let billingTime: String?
    let orderNo: String?
    let customerId: String?
    let apiKey: String?
    let modelCode: String?
    let modelProductType: String?
    let modelProductSubtype: String?
    let modelProductCode: String?
    let modelProductName: String?
    let paymentType: String?
    let startTime: String?
    let endTime: String?
    let businessId: Int?
    let costPrice: Double?
    let costUnit: String?
    let usageCount: Int?
    let usageExempt: Double?
    let usageUnit: String?
    let currency: String?
    let settlementAmount: Double?
    let giftDeductAmount: Double?
    let dueAmount: Double?
    let paidAmount: Double?
    let unpaidAmount: Double?
    let billingStatus: String?
    let invoicingAmount: Double?
    let invoicedAmount: Double?
    let tokenAccountId: Int?
    let tokenResourceNo: String?
    let tokenResourceName: String?
    let deductUsage: Int?
    let deductAfter: String?
    let timeWindow: String?
    let originalAmount: Double?
    let originalCostPrice: Double?
    let apiUsage: Int?
    let discountRate: Double?
    let discountType: String?
    let creditPayAmount: Double?
    let tokenType: String?
    let cashAmount: Double?
    let thirdParty: Double?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        billingNo = FlexibleDecoding.string(from: c, forKey: .billingNo)
        billingDate = try c.decodeIfPresent(String.self, forKey: .billingDate)
        billingTime = FlexibleDecoding.string(from: c, forKey: .billingTime)
        orderNo = FlexibleDecoding.string(from: c, forKey: .orderNo)
        customerId = FlexibleDecoding.string(from: c, forKey: .customerId)
        apiKey = try c.decodeIfPresent(String.self, forKey: .apiKey)
        modelCode = try c.decodeIfPresent(String.self, forKey: .modelCode)
        modelProductType = try c.decodeIfPresent(String.self, forKey: .modelProductType)
        modelProductSubtype = try c.decodeIfPresent(String.self, forKey: .modelProductSubtype)
        modelProductCode = try c.decodeIfPresent(String.self, forKey: .modelProductCode)
        modelProductName = try c.decodeIfPresent(String.self, forKey: .modelProductName)
        paymentType = try c.decodeIfPresent(String.self, forKey: .paymentType)
        startTime = FlexibleDecoding.string(from: c, forKey: .startTime)
        endTime = FlexibleDecoding.string(from: c, forKey: .endTime)
        businessId = FlexibleDecoding.int(from: c, forKey: .businessId)
        costPrice = FlexibleDecoding.double(from: c, forKey: .costPrice)
        costUnit = try c.decodeIfPresent(String.self, forKey: .costUnit)
        usageCount = FlexibleDecoding.int(from: c, forKey: .usageCount)
        usageExempt = FlexibleDecoding.double(from: c, forKey: .usageExempt)
        usageUnit = try c.decodeIfPresent(String.self, forKey: .usageUnit)
        currency = try c.decodeIfPresent(String.self, forKey: .currency)
        settlementAmount = FlexibleDecoding.double(from: c, forKey: .settlementAmount)
        giftDeductAmount = FlexibleDecoding.double(from: c, forKey: .giftDeductAmount)
        dueAmount = FlexibleDecoding.double(from: c, forKey: .dueAmount)
        paidAmount = FlexibleDecoding.double(from: c, forKey: .paidAmount)
        unpaidAmount = FlexibleDecoding.double(from: c, forKey: .unpaidAmount)
        billingStatus = try c.decodeIfPresent(String.self, forKey: .billingStatus)
        invoicingAmount = FlexibleDecoding.double(from: c, forKey: .invoicingAmount)
        invoicedAmount = FlexibleDecoding.double(from: c, forKey: .invoicedAmount)
        tokenAccountId = FlexibleDecoding.int(from: c, forKey: .tokenAccountId)
        tokenResourceNo = FlexibleDecoding.string(from: c, forKey: .tokenResourceNo)
        tokenResourceName = try c.decodeIfPresent(String.self, forKey: .tokenResourceName)
        deductUsage = FlexibleDecoding.int(from: c, forKey: .deductUsage)
        deductAfter = FlexibleDecoding.string(from: c, forKey: .deductAfter)
        timeWindow = try c.decodeIfPresent(String.self, forKey: .timeWindow)
        originalAmount = FlexibleDecoding.double(from: c, forKey: .originalAmount)
        originalCostPrice = FlexibleDecoding.double(from: c, forKey: .originalCostPrice)
        apiUsage = FlexibleDecoding.int(from: c, forKey: .apiUsage)
        discountRate = FlexibleDecoding.double(from: c, forKey: .discountRate)
        discountType = try c.decodeIfPresent(String.self, forKey: .discountType)
        creditPayAmount = FlexibleDecoding.double(from: c, forKey: .creditPayAmount)
        tokenType = try c.decodeIfPresent(String.self, forKey: .tokenType)
        cashAmount = FlexibleDecoding.double(from: c, forKey: .cashAmount)
        thirdParty = FlexibleDecoding.double(from: c, forKey: .thirdParty)
    }

    enum CodingKeys: String, CodingKey {
        case billingNo
        case billingDate
        case billingTime
        case orderNo
        case customerId
        case apiKey
        case modelCode
        case modelProductType
        case modelProductSubtype
        case modelProductCode
        case modelProductName
        case paymentType
        case startTime
        case endTime
        case businessId
        case costPrice
        case costUnit
        case usageCount
        case usageExempt
        case usageUnit
        case currency
        case settlementAmount
        case giftDeductAmount
        case dueAmount
        case paidAmount
        case unpaidAmount
        case billingStatus
        case invoicingAmount
        case invoicedAmount
        case tokenAccountId
        case tokenResourceNo
        case tokenResourceName
        case deductUsage
        case deductAfter
        case timeWindow
        case originalAmount
        case originalCostPrice
        case apiUsage
        case discountRate
        case discountType
        case creditPayAmount
        case tokenType
        case cashAmount
        case thirdParty
    }

    static func extractTransactionTime(billingNo: String?, customerId: String?) -> Date? {
        guard let billingNo, let customerId, !billingNo.isEmpty, !customerId.isEmpty else { return nil }
        guard let range = billingNo.range(of: customerId) else { return nil }
        let afterCustomer = billingNo[range.upperBound...]
        let timestampStr = String(afterCustomer.prefix(13))
        guard timestampStr.count == 13, let timestamp = Int64(timestampStr) else { return nil }
        return Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
    }

    static func splitTimeWindow(_ timeWindow: String?) -> (start: String?, end: String?) {
        guard let timeWindow, !timeWindow.isEmpty else { return (nil, nil) }
        let parts = timeWindow.split(separator: "~", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
        return (parts.count > 0 ? parts[0] : nil, parts.count > 1 ? parts[1] : nil)
    }
}

// MARK: - Flexible Decoding Helpers

enum FlexibleDecoding {
    /// Decode an `Int?` for `BillingAPIEnvelope`, tolerating type mismatches.
    static func envelopeInt(from container: KeyedDecodingContainer<BillingAPIEnvelope.CodingKeys>, forKey key: BillingAPIEnvelope.CodingKeys) -> Int? {
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return v }
        if let d = try? container.decodeIfPresent(Double.self, forKey: key) { return Int(d) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) { return Int(s) }
        return nil
    }

    /// Try to decode an `Int?` from JSON, tolerating `Int`, `Double`, or `String` representations.
    static func int(from container: KeyedDecodingContainer<BillRow.CodingKeys>, forKey key: BillRow.CodingKeys) -> Int? {
        // Try Int first
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return v }
        // Try Double → Int
        if let d = try? container.decodeIfPresent(Double.self, forKey: key) { return Int(d) }
        // Try String → Int
        if let s = try? container.decodeIfPresent(String.self, forKey: key) { return Int(s) }
        return nil
    }

    /// Try to decode a `Double?` from JSON, tolerating `Double`, `Int`, or `String` representations.
    static func double(from container: KeyedDecodingContainer<BillRow.CodingKeys>, forKey key: BillRow.CodingKeys) -> Double? {
        // Try Double first
        if let v = try? container.decodeIfPresent(Double.self, forKey: key) { return v }
        // Try Int → Double
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) { return Double(i) }
        // Try String → Double
        if let s = try? container.decodeIfPresent(String.self, forKey: key) { return Double(s) }
        return nil
    }

    /// Try to decode a `String?` from JSON, tolerating `String`, `Int`, or `Double` representations.
    static func string(from container: KeyedDecodingContainer<BillRow.CodingKeys>, forKey key: BillRow.CodingKeys) -> String? {
        if let v = try? container.decodeIfPresent(String.self, forKey: key) { return v }
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) { return String(i) }
        if let d = try? container.decodeIfPresent(Double.self, forKey: key) { return String(d) }
        return nil
    }
}

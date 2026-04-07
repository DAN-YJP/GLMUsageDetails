#!/usr/bin/env swift
//
// test_billing_api.swift — 账单 API 数据管道验证脚本
//
// 用法: swift Scripts/test_billing_api.swift <API_KEY>
//
// 验证流程: 请求 API → 解码 JSON → 打印字段类型 → 模拟 transform → 汇总统计
//

import Foundation

// MARK: - Paste the actual models inline (avoid module dependency)

private enum FlexibleDecoding {
    static func int(from container: KeyedDecodingContainer<BillRowTest.CodingKeys>, forKey key: BillRowTest.CodingKeys) -> Int? {
        if let v = try? container.decodeIfPresent(Int.self, forKey: key) { return v }
        if let d = try? container.decodeIfPresent(Double.self, forKey: key) { return Int(d) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) { return Int(s) }
        return nil
    }

    static func double(from container: KeyedDecodingContainer<BillRowTest.CodingKeys>, forKey key: BillRowTest.CodingKeys) -> Double? {
        if let v = try? container.decodeIfPresent(Double.self, forKey: key) { return v }
        if let i = try? container.decodeIfPresent(Int.self, forKey: key) { return Double(i) }
        if let s = try? container.decodeIfPresent(String.self, forKey: key) { return Double(s) }
        return nil
    }
}

private struct EnvelopeTest: Decodable {
    let code: Int?
    let msg: String?
    let total: Int?
    let rows: [BillRowTest]?
}

private struct BillRowTest: Decodable {
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

    enum CodingKeys: String, CodingKey {
        case billingNo, billingDate, billingTime, orderNo, customerId, apiKey
        case modelCode, modelProductType, modelProductSubtype, modelProductCode, modelProductName
        case paymentType, startTime, endTime, businessId, costPrice, costUnit
        case usageCount, usageExempt, usageUnit, currency, settlementAmount
        case giftDeductAmount, dueAmount, paidAmount, unpaidAmount, billingStatus
        case invoicingAmount, invoicedAmount, tokenAccountId, tokenResourceNo, tokenResourceName
        case deductUsage, deductAfter, timeWindow, originalAmount, originalCostPrice
        case apiUsage, discountRate, discountType, creditPayAmount, tokenType, cashAmount, thirdParty
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        billingNo = try c.decodeIfPresent(String.self, forKey: .billingNo)
        billingDate = try c.decodeIfPresent(String.self, forKey: .billingDate)
        billingTime = try c.decodeIfPresent(String.self, forKey: .billingTime)
        orderNo = try c.decodeIfPresent(String.self, forKey: .orderNo)
        customerId = try c.decodeIfPresent(String.self, forKey: .customerId)
        apiKey = try c.decodeIfPresent(String.self, forKey: .apiKey)
        modelCode = try c.decodeIfPresent(String.self, forKey: .modelCode)
        modelProductType = try c.decodeIfPresent(String.self, forKey: .modelProductType)
        modelProductSubtype = try c.decodeIfPresent(String.self, forKey: .modelProductSubtype)
        modelProductCode = try c.decodeIfPresent(String.self, forKey: .modelProductCode)
        modelProductName = try c.decodeIfPresent(String.self, forKey: .modelProductName)
        paymentType = try c.decodeIfPresent(String.self, forKey: .paymentType)
        startTime = try c.decodeIfPresent(String.self, forKey: .startTime)
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime)
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
        tokenResourceNo = try c.decodeIfPresent(String.self, forKey: .tokenResourceNo)
        tokenResourceName = try c.decodeIfPresent(String.self, forKey: .tokenResourceName)
        deductUsage = FlexibleDecoding.int(from: c, forKey: .deductUsage)
        deductAfter = try c.decodeIfPresent(String.self, forKey: .deductAfter)
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
}

// MARK: - Raw JSON analysis (decode as dictionary first to see actual types)

private func analyzeRawJSON(_ data: Data) {
    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
        print("  [RAW] Failed to parse as JSON")
        return
    }
    guard let dict = json as? [String: Any] else {
        print("  [RAW] Root is not a dictionary")
        return
    }

    print("  [RAW] Top-level keys: \(dict.keys.sorted().joined(separator: ", "))")
    if let code = dict["code"] { print("  [RAW] code = \(code) (\(typeDesc(code)))") }
    if let msg = dict["msg"] { print("  [RAW] msg = \(msg)") }
    if let total = dict["total"] { print("  [RAW] total = \(total) (\(typeDesc(total)))") }

    if let rows = dict["rows"] as? [[String: Any]], !rows.isEmpty {
        print("  [RAW] rows count: \(rows.count)")
        let sample = rows[0]
        print("  [RAW] First row keys: \(sample.keys.sorted().joined(separator: ", "))")
        for (key, value) in sample.sorted(by: { $0.key < $1.key }) {
            print("  [RAW]   \(key) = \(value) (\(typeDesc(value)))")
        }
    } else {
        print("  [RAW] rows: \(dict["rows"] == nil ? "nil" : "not an array")")
    }
}

private func typeDesc(_ value: Any) -> String {
    if value is Int { return "Int" }
    if value is Double { return "Double" }
    if value is String { return "String" }
    if value is Bool { return "Bool" }
    if value is NSNull { return "null" }
    if let arr = value as? [Any] { return "Array[\(arr.count)]" }
    return "\(type(of: value))"
}

// MARK: - Main

guard CommandLine.arguments.count > 1 else {
    print("Usage: swift Scripts/test_billing_api.swift <API_KEY>")
    print("       swift Scripts/test_billing_api.swift <API_KEY> <billingMonth>")
    exit(1)
}

let apiKey = CommandLine.arguments[1]
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM"
let billingMonth = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : formatter.string(from: Date())

let baseURL = "https://bigmodel.cn/api/finance/expenseBill/expenseBillList"
let session = URLSession.shared
let decoder = JSONDecoder()

print("=== 账单 API 数据管道验证 ===")
print("Billing Month: \(billingMonth)")
print("API Key: \(apiKey.prefix(8))...")
print()

// Step 1: Fetch first page
var components = URLComponents(string: baseURL)!
components.queryItems = [
    URLQueryItem(name: "billingMonth", value: billingMonth),
    URLQueryItem(name: "pageNum", value: "1"),
    URLQueryItem(name: "pageSize", value: "5")
]

var request = URLRequest(url: components.url!)
request.httpMethod = "GET"
request.setValue("application/json", forHTTPHeaderField: "Accept")
request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
request.timeoutInterval = 30

print("--- Step 1: Fetch first 5 rows ---")
let (data, response): (Data, URLResponse)
do {
    (data, response) = try await session.data(for: request)
} catch {
    print("Network error: \(error.localizedDescription)")
    exit(1)
}

guard let http = response as? HTTPURLResponse else {
    print("Not HTTP response")
    exit(1)
}
print("HTTP Status: \(http.statusCode)")

guard (200...299).contains(http.statusCode) else {
    let body = String(data: data, encoding: .utf8) ?? "(non-UTF-8)"
    print("HTTP Error \(http.statusCode)")
    print("Response: \(String(body.prefix(500)))")
    exit(1)
}

// Step 2: Analyze raw JSON
print()
print("--- Step 2: Raw JSON Analysis ---")
analyzeRawJSON(data)

// Step 3: Decode with BillRow
print()
print("--- Step 3: Decode with BillRow model ---")
do {
    let envelope = try decoder.decode(EnvelopeTest.self, from: data)
    print("  code: \(envelope.code.map(String.init) ?? "nil")")
    print("  msg: \(envelope.msg ?? "nil")")
    print("  total: \(envelope.total.map(String.init) ?? "nil")")
    print("  decoded rows: \(envelope.rows?.count ?? 0)")

    guard let rows = envelope.rows, !rows.isEmpty else {
        print("  No rows returned")
        exit(0)
    }

    // Step 4: Show first row detail
    print()
    print("--- Step 4: First row detail ---")
    let row = rows[0]
    print("  billingNo: \(row.billingNo ?? "nil")")
    print("  customerId: \(row.customerId ?? "nil")")
    print("  modelCode: \(row.modelCode ?? "nil")")
    print("  modelProductName: \(row.modelProductName ?? "nil")")
    print("  tokenResourceName: \(row.tokenResourceName ?? "nil")")
    print("  apiUsage: \(String(describing: row.apiUsage))")
    print("  deductUsage: \(String(describing: row.deductUsage))")
    print("  costPrice: \(String(describing: row.costPrice))")
    print("  tokenType: \(row.tokenType ?? "nil")")
    print("  timeWindow: \(row.timeWindow ?? "nil")")
    print("  businessId: \(String(describing: row.businessId))")
    print("  usageCount: \(String(describing: row.usageCount))")
    print("  settlementAmount: \(String(describing: row.settlementAmount))")
    print("  discountRate: \(String(describing: row.discountRate))")
    print("  originalCostPrice: \(String(describing: row.originalCostPrice))")

    // Step 5: Check data quality
    print()
    print("--- Step 5: Data quality check ---")
    var nullBillingNo = 0, nullCustomerId = 0, nullApiUsage = 0, nullDeductUsage = 0, nullCostPrice = 0
    var totalApiUsage = 0, totalDeductUsage = 0, totalCost = 0.0
    var products: Set<String> = []

    for row in rows {
        if row.billingNo == nil { nullBillingNo += 1 }
        if row.customerId == nil { nullCustomerId += 1 }
        if row.apiUsage == nil { nullApiUsage += 1 }
        if row.deductUsage == nil { nullDeductUsage += 1 }
        if row.costPrice == nil { nullCostPrice += 1 }
        totalApiUsage += row.apiUsage ?? 0
        totalDeductUsage += row.deductUsage ?? 0
        totalCost += row.costPrice ?? 0
        if let p = row.modelProductName, !p.isEmpty { products.insert(p) }
    }

    print("  Null billingNo: \(nullBillingNo)/\(rows.count)")
    print("  Null customerId: \(nullCustomerId)/\(rows.count)")
    print("  Null apiUsage: \(nullApiUsage)/\(rows.count)")
    print("  Null deductUsage: \(nullDeductUsage)/\(rows.count)")
    print("  Null costPrice: \(nullCostPrice)/\(rows.count)")
    print("  Total apiUsage: \(totalApiUsage)")
    print("  Total deductUsage: \(totalDeductUsage)")
    print("  Total costPrice: \(String(format: "%.4f", totalCost))")
    print("  Products: \(products.sorted().joined(separator: ", "))")

    print()
    print("=== ALL CHECKS PASSED ===")
} catch let error as DecodingError {
    print("  DECODING FAILED: \(error)")
    print()
    print("  This means the BillRow model doesn't match the API response.")
    print("  The raw JSON analysis above shows the actual field types.")
} catch {
    print("  Error: \(error)")
}

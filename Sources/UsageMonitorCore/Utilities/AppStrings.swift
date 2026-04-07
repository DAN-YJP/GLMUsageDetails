import Foundation

public enum AppStrings {
    public static func usageMonitorSettings(language: AppLanguage) -> String { language == .english ? "Usage Monitor Settings" : "使用量监控设置" }
    public static func settingsSubtitle(language: AppLanguage) -> String { language == .english ? "Only your API key is required. The app uses the built-in Z.ai host by default." : "默认只需要填写 API Key，应用会使用内置的 Z.ai 主机地址。" }
    public static func apiAccess(language: AppLanguage) -> String { language == .english ? "API Access" : "API 访问" }
    public static func apiKey(language: AppLanguage) -> String { "API Key" }
    public static func pasteAPIKey(language: AppLanguage) -> String { language == .english ? "Paste your API key" : "粘贴你的 API Key" }
    public static func clear(language: AppLanguage) -> String { language == .english ? "Clear" : "清除" }
    public static func cancel(language: AppLanguage) -> String { language == .english ? "Cancel" : "取消" }
    public static func clearLocalData(language: AppLanguage) -> String { language == .english ? "Clear Local Data" : "清空本地数据" }
    public static func clearAPIKeyTitle(language: AppLanguage) -> String { language == .english ? "Clear API Key" : "清除 API Key" }
    public static func clearAPIKeyMessage(language: AppLanguage) -> String { language == .english ? "Clearing the API key will also clear all local billing data. This action cannot be undone." : "清除 API Key 将同时清除所有本地账单数据，此操作不可撤销。" }
    public static func localStorageHint(host: String, language: AppLanguage) -> String { language == .english ? "Key stored encrypted. Host: \(host)" : "密钥已经加密储存。Host：\(host)" }
    public static func behavior(language: AppLanguage) -> String { language == .english ? "Behavior" : "行为" }
    public static func language(language selectedLanguage: AppLanguage) -> String { selectedLanguage == .english ? "Language" : "语言" }
    public static func autoRefresh(language: AppLanguage) -> String { language == .english ? "Auto Refresh" : "自动刷新" }
    public static func autoRefreshHint(language: AppLanguage) -> String { language == .english ? "Refresh quota data periodically (min 30 sec)." : "在后台定期刷新配额数据（最小30秒）。" }
    public static func secondsUnit(language: AppLanguage) -> String { language == .english ? "sec" : "秒" }
    public static func showMenuBarSummary(language: AppLanguage) -> String { language == .english ? "Show Menu Bar Summary" : "显示菜单栏摘要" }
    public static func menuBarSummaryHint(language: AppLanguage) -> String { language == .english ? "Display a compact usage summary next to the menu bar icon." : "在菜单栏图标旁显示紧凑的使用摘要。" }
    public static func menuBarContent(language: AppLanguage) -> String { language == .english ? "Menu Bar Content" : "菜单栏显示内容" }
    public static func menuBarContentHint(language: AppLanguage) -> String { language == .english ? "Choose which quota buckets appear in the compact summary." : "选择菜单栏紧凑摘要中显示哪些配额项目。" }
    public static func launchAtLogin(language: AppLanguage) -> String { language == .english ? "Launch at Login" : "登录时启动" }
    public static func launchAtLoginHint(language: AppLanguage) -> String { language == .english ? "Reserved for future native login-item integration." : "预留给后续原生开机启动集成。" }
    public static func testConnection(language: AppLanguage) -> String { language == .english ? "Test Connection" : "测试连接" }
    public static func save(language: AppLanguage) -> String { language == .english ? "Save" : "保存" }
    public static func settingsSaved(language: AppLanguage) -> String { language == .english ? "Settings saved." : "设置已保存。" }
    public static func connectionSuccessful(language: AppLanguage) -> String { language == .english ? "Connection successful." : "连接成功。" }
    public static func connectionFailed(language: AppLanguage) -> String { language == .english ? "Connection failed." : "连接失败。" }
    public static func validateKey(language: AppLanguage) -> String { language == .english ? "Validate" : "验证" }
    public static func keyValid(language: AppLanguage) -> String { language == .english ? "Key is valid." : "Key 有效。" }
    public static func keyInvalid(language: AppLanguage) -> String { language == .english ? "Key is invalid." : "Key 无效。" }
    public static func keyEmpty(language: AppLanguage) -> String { language == .english ? "Please enter an API key first." : "请先输入 API Key。" }
    public static func localDataCleared(language: AppLanguage) -> String { language == .english ? "Local app data cleared." : "本地应用数据已清空。" }
    public static func refresh(language: AppLanguage) -> String { language == .english ? "Refresh" : "刷新" }
    public static func settings(language: AppLanguage) -> String { language == .english ? "Settings" : "设置" }
    public static func quit(language: AppLanguage) -> String { language == .english ? "Quit" : "退出" }
    public static func copyDebugInfo(language: AppLanguage) -> String { language == .english ? "Copy Debug Info" : "复制调试信息" }
    public static func never(language: AppLanguage) -> String { language == .english ? "Never" : "从未" }
    public static func unavailable(language: AppLanguage) -> String { language == .english ? "Unavailable" : "不可用" }
    public static func noSubscription(language: AppLanguage) -> String { language == .english ? "No subscription detected" : "未检测到订阅信息" }
    public static func nextRenewal(language: AppLanguage) -> String { language == .english ? "Next Renewal" : "下次续费" }
    public static func lastRefresh(language: AppLanguage) -> String { language == .english ? "Last Refresh" : "上次刷新" }
    public static func refreshing(language: AppLanguage) -> String { language == .english ? "Refreshing" : "刷新中" }
    public static func fiveHourUsage(language: AppLanguage) -> String { language == .english ? "5-Hour Usage" : "5 小时用量" }
    public static func weeklyUsage(language: AppLanguage) -> String { language == .english ? "Weekly Usage" : "每周用量" }
    public static func mcpMonthlyUsage(language: AppLanguage) -> String { language == .english ? "MCP Monthly Usage" : "MCP 每月用量" }
    public static func used(language: AppLanguage) -> String { language == .english ? "Used" : "已用" }
    public static func remaining(language: AppLanguage) -> String { language == .english ? "Remaining" : "剩余" }
    public static func total(language: AppLanguage) -> String { language == .english ? "Total" : "总量" }
    public static func reset(language: AppLanguage) -> String { language == .english ? "Reset" : "重置" }
    public static func resetTime(language: AppLanguage) -> String { language == .english ? "Reset time" : "重置时间" }
    public static func mcpDetails(language: AppLanguage) -> String { language == .english ? "MCP Details" : "MCP 明细" }
    public static func connectAccount(language: AppLanguage) -> String { language == .english ? "Connect Your Account" : "连接你的账号" }
    public static func emptyStateHint(language: AppLanguage) -> String { language == .english ? "Add your API key in Settings to start monitoring quotas." : "在设置中填写 API Key 后即可开始监控配额。" }
    public static func openSettings(language: AppLanguage) -> String { language == .english ? "Open Settings" : "打开设置" }

    // MARK: - Theme

    public static func appearance(language: AppLanguage) -> String { language == .english ? "Appearance" : "外观" }
    public static func appearanceHint(language: AppLanguage) -> String { language == .english ? "Choose the app theme." : "选择应用的主题外观。" }

    // MARK: - Dashboard Sections

    public static func dashboardSections(language: AppLanguage) -> String { language == .english ? "Dashboard Sections" : "面板区块" }
    public static func dashboardSectionsHint(language: AppLanguage) -> String { language == .english ? "Choose which sections to display on the dashboard." : "选择在主面板上显示哪些区块。" }
    public static func fiveHourQuota(language: AppLanguage) -> String { language == .english ? "5-Hour Quota" : "5 小时配额" }
    public static func weeklyQuota(language: AppLanguage) -> String { language == .english ? "Weekly Quota" : "每周配额" }
    public static func mcpQuota(language: AppLanguage) -> String { language == .english ? "MCP Monthly Quota" : "MCP 每月配额" }
    public static func billingStatsSection(language: AppLanguage) -> String { language == .english ? "Billing Stats" : "账单统计" }

    // MARK: - Billing

    public static func billingStats(language: AppLanguage) -> String { language == .english ? "Billing Stats" : "账单统计" }
    public static func calls(language: AppLanguage) -> String { language == .english ? "calls" : "次调用" }
    public static func callCount(language: AppLanguage) -> String { language == .english ? "Calls" : "调用次数" }
    public static func tokens(language: AppLanguage) -> String { language == .english ? "tokens" : "tokens" }
    public static func cost(language: AppLanguage) -> String { language == .english ? "Cost" : "费用" }
    public static func growthRate(language: AppLanguage) -> String { language == .english ? "Growth" : "增长率" }
    public static func membershipTier(language: AppLanguage) -> String { language == .english ? "Membership" : "会员等级" }
    public static func callLimit(language: AppLanguage) -> String { language == .english ? "Call Limit" : "调用限制" }
    public static func syncStatus(language: AppLanguage) -> String { language == .english ? "Sync Status" : "同步状态" }
    public static func lastSync(language: AppLanguage) -> String { language == .english ? "Last Sync" : "上次同步" }
    public static func syncingMonth(language: AppLanguage, month: String) -> String {
        language == .english ? "Syncing \(month)..." : "正在同步 \(month)..."
    }
    public static func dailyUsage(language: AppLanguage) -> String { language == .english ? "Daily Usage" : "每日用量" }
    public static func dailyCallsAndTokens(language: AppLanguage) -> String { language == .english ? "Daily Calls & Tokens" : "每日调用次数与 Token 数量" }
    public static func hourlyCallsAndTokens(language: AppLanguage) -> String { language == .english ? "Hourly Calls & Tokens" : "每小时调用次数与 Token 数量" }
    public static func monthlyUsage(language: AppLanguage) -> String { language == .english ? "Monthly Usage" : "每月用量" }
    public static func callUsage(language: AppLanguage) -> String { language == .english ? "Call Usage" : "调用用量" }
    public static func tokenUsage(language: AppLanguage) -> String { language == .english ? "Token Usage" : "Token用量" }
    public static func inputTokens(language: AppLanguage) -> String { language == .english ? "Input" : "输入" }
    public static func outputTokens(language: AppLanguage) -> String { language == .english ? "Output" : "输出" }
    public static func cacheHitTokens(language: AppLanguage) -> String { language == .english ? "Cache Hit" : "缓存命中" }
    public static func productUsage(language: AppLanguage) -> String { language == .english ? "Product Usage" : "产品用量" }
    public static func weeklyDetail(language: AppLanguage) -> String { language == .english ? "Weekly Detail" : "每周详情" }
    public static func monthlyDetail(language: AppLanguage) -> String { language == .english ? "Monthly Detail" : "每月详情" }
    public static func detailTitle(for window: TimeWindow, language: AppLanguage) -> String {
        switch window {
        case .fiveHour: return language == .english ? "5-Hour Detail" : "5小时详情"
        case .oneDay: return language == .english ? "24-Hour Detail" : "24小时详情"
        case .oneWeek: return weeklyDetail(language: language)
        case .oneMonth: return monthlyDetail(language: language)
        }
    }
}

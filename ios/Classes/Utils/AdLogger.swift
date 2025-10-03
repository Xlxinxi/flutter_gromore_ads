import Foundation

/**
 * 广告日志工具类
 * 提供统一的日志记录功能
 */
class AdLogger {
    
    // 单例实例
    static let shared = AdLogger()
    
    private init() {}
    
    /**
     * 记录广告请求日志
     */
    func logAdRequest(_ adType: String, posId: String, params: [String: Any]) {
        let paramsStr = formatParams(params)
        NSLog("[\(AdConstants.TAG)] 广告请求 - 类型: \(adType), 广告位: \(posId), 参数: \(paramsStr)")
    }
    
    /**
     * 记录广告成功日志
     */
    func logAdSuccess(_ adType: String, action: String, posId: String, message: String) {
        NSLog("[\(AdConstants.TAG)] ✅ \(adType) \(action)成功 - 广告位: \(posId), 信息: \(message)")
    }
    
    /**
     * 记录广告错误日志
     */
    func logAdError(_ adType: String, action: String, posId: String, errorCode: Int, errorMessage: String) {
        NSLog("[\(AdConstants.TAG)] ❌ \(adType) \(action)失败 - 广告位: \(posId), 错误码: \(errorCode), 错误信息: \(errorMessage)")
    }
    
    /**
     * 记录广告事件日志
     */
    func logAdEvent(_ eventType: String, posId: String, extra: [String: Any]? = nil) {
        var logMessage = "[\(AdConstants.TAG)] 📱 广告事件 - \(eventType), 广告位: \(posId)"
        if let extra = extra, !extra.isEmpty {
            let extraStr = formatParams(extra)
            logMessage += ", 额外信息: \(extraStr)"
        }
        NSLog(logMessage)
    }
    
    /**
     * 记录一般信息日志
     */
    func logInfo(_ message: String) {
        NSLog("[\(AdConstants.TAG)] ℹ️ \(message)")
    }
    
    /**
     * 记录警告日志
     */
    func logWarning(_ message: String) {
        NSLog("[\(AdConstants.TAG)] ⚠️ \(message)")
    }
    
    /**
     * 记录调试日志
     */
    func logDebug(_ message: String) {
        #if DEBUG
        NSLog("[\(AdConstants.TAG)] 🔍 DEBUG: \(message)")
        #endif
    }
    
    /**
     * 格式化参数为字符串
     */
    private func formatParams(_ params: [String: Any]) -> String {
        var parts: [String] = []
        for (key, value) in params {
            parts.append("\(key)=\(value)")
        }
        return parts.joined(separator: ", ")
    }
    
    /**
     * 记录广告管理器状态
     */
    func logManagerState(_ adType: String, posId: String, state: String) {
        NSLog("[\(AdConstants.TAG)] 🔄 \(adType)管理器状态变更 - 广告位: \(posId), 状态: \(state)")
    }
}
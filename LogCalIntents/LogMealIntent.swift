//
//  LogMealIntent.swift
//  LogCalIntents
//
//  Manual Intent class definitions (fallback when Intent Definition doesn't generate classes)
//  This file should ONLY be in the LogCalIntents extension target
//

import Intents

// MARK: - Intent
@available(iOS 13.0, *)
public class LogMealIntent: INIntent {
    
    @NSManaged public var foodDescription: String?
    @NSManaged public var mealType: String?
    
    public override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// MARK: - Response
@available(iOS 13.0, *)
@objc(LogMealIntentResponse)
public class LogMealIntentResponse: INIntentResponse {
    
    @NSManaged public var calories: NSNumber?
    @NSManaged public var mealType: String?
    @NSManaged public var message: String?
    @NSManaged public var errorMessage: String?
    
    @objc public enum Code: Int {
        case unspecified = 0
        case ready = 1
        case continueInApp = 2
        case inProgress = 3
        case success = 4
        case failure = 5
        case requiresAppLaunch = 6
    }
    
    private var _code: Code = .unspecified
    
    @objc public var code: Code {
        return _code
    }
    
    public override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public convenience init(code: Code, userActivity: NSUserActivity?) {
        self.init()
        self._code = code
        self.userActivity = userActivity
    }
}

// MARK: - Handling Protocol
@available(iOS 13.0, *)
public protocol LogMealIntentHandling {
    func handle(intent: LogMealIntent, completion: @escaping (LogMealIntentResponse) -> Void)
    func confirm(intent: LogMealIntent, completion: @escaping (LogMealIntentResponse) -> Void)
    func resolveFoodDescription(for intent: LogMealIntent, with completion: @escaping (INStringResolutionResult) -> Void)
    func resolveMealType(for intent: LogMealIntent, with completion: @escaping (INStringResolutionResult) -> Void)
}

// Default implementations
@available(iOS 13.0, *)
public extension LogMealIntentHandling {
    func confirm(intent: LogMealIntent, completion: @escaping (LogMealIntentResponse) -> Void) {
        completion(LogMealIntentResponse(code: .ready, userActivity: nil))
    }
    
    func resolveFoodDescription(for intent: LogMealIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let description = intent.foodDescription, !description.isEmpty {
            completion(.success(with: description))
        } else {
            completion(.needsValue())
        }
    }
    
    func resolveMealType(for intent: LogMealIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let type = intent.mealType, !type.isEmpty {
            completion(.success(with: type))
        } else {
            completion(.success(with: "meal"))
        }
    }
}


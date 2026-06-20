import Foundation
import XcodeProj
import PathKit

func main() {
    let projectPath = Path("/Users/ajohri/Documents/Antriksh Personal/LogCal/logcal/logcal.xcodeproj")
    do {
        let xcodeproj = try XcodeProj(path: projectPath)
        let pbxproj = xcodeproj.pbxproj
        guard let rootProject = try pbxproj.rootProject() else {
            print("ERROR: Could not find root project")
            return
        }
        
        print("Found targets:")
        for target in pbxproj.nativeTargets {
            print("  - \(target.name) (\(target.productType?.rawValue ?? "unknown"))")
        }
        
        // 1. Create or get product reference for LogCalWidget.appex
        let productsGroup = pbxproj.groups.first(where: { $0.name == "Products" || $0.path == "Products" })
        var productRef = productsGroup?.children.first(where: { $0.path == "LogCalWidget.appex" || $0.name == "LogCalWidget.appex" }) as? PBXFileReference
        if productRef == nil {
            productRef = PBXFileReference(
                sourceTree: .builtProductsDir,
                name: "LogCalWidget.appex",
                explicitFileType: "wrapper.app-extension",
                path: "LogCalWidget.appex"
            )
            pbxproj.add(object: productRef!)
            productsGroup?.children.append(productRef!)
            print("Created product reference for LogCalWidget.appex")
        } else {
            print("Product reference for LogCalWidget.appex already exists")
        }
        
        // 2. Create or get target
        var widgetTarget = pbxproj.nativeTargets.first(where: { $0.name == "LogCalWidget" })
        if widgetTarget == nil {
            print("Creating LogCalWidget target...")
            let debugConfig = XCBuildConfiguration(name: "Debug", buildSettings: [
                "PRODUCT_NAME": "LogCalWidget",
                "PRODUCT_BUNDLE_IDENTIFIER": "com.serene.logcal.LogCalWidget",
                "INFOPLIST_FILE": "LogCalWidget/Info.plist",
                "CODE_SIGN_ENTITLEMENTS": "LogCalWidget/LogCalWidget.entitlements",
                "CURRENT_PROJECT_VERSION": "11",
                "MARKETING_VERSION": "2.0",
                "SWIFT_VERSION": "5.0",
                "SDKROOT": "iphoneos",
                "SUPPORTED_PLATFORMS": "iphonesimulator iphoneos",
                "TARGETED_DEVICE_FAMILY": "1",
                "GENERATE_INFOPLIST_FILE": "YES",
                "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks",
            ])
            let releaseConfig = XCBuildConfiguration(name: "Release", buildSettings: [
                "PRODUCT_NAME": "LogCalWidget",
                "PRODUCT_BUNDLE_IDENTIFIER": "com.serene.logcal.LogCalWidget",
                "INFOPLIST_FILE": "LogCalWidget/Info.plist",
                "CODE_SIGN_ENTITLEMENTS": "LogCalWidget/LogCalWidget.entitlements",
                "CURRENT_PROJECT_VERSION": "11",
                "MARKETING_VERSION": "2.0",
                "SWIFT_VERSION": "5.0",
                "SDKROOT": "iphoneos",
                "SUPPORTED_PLATFORMS": "iphonesimulator iphoneos",
                "TARGETED_DEVICE_FAMILY": "1",
                "GENERATE_INFOPLIST_FILE": "YES",
                "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks",
            ])
            pbxproj.add(object: debugConfig)
            pbxproj.add(object: releaseConfig)

            let configList = XCConfigurationList(buildConfigurations: [debugConfig, releaseConfig], defaultConfigurationName: "Release")
            pbxproj.add(object: configList)

            widgetTarget = PBXNativeTarget(
                name: "LogCalWidget",
                buildConfigurationList: configList,
                buildPhases: [],
                buildRules: [],
                dependencies: [],
                productName: "LogCalWidget",
                product: productRef,
                productType: .appExtension
            )
            pbxproj.add(object: widgetTarget!)
            rootProject.targets.append(widgetTarget!)
            print("Successfully created target LogCalWidget")
        } else {
            print("Target LogCalWidget already exists")
        }
        
        // 3. Setup build phases
        var sourcesPhase = widgetTarget!.buildPhases.compactMap({ $0 as? PBXSourcesBuildPhase }).first
        if sourcesPhase == nil {
            sourcesPhase = PBXSourcesBuildPhase()
            pbxproj.add(object: sourcesPhase!)
            widgetTarget!.buildPhases.append(sourcesPhase!)
        }

        var frameworksPhase = widgetTarget!.buildPhases.compactMap({ $0 as? PBXFrameworksBuildPhase }).first
        if frameworksPhase == nil {
            frameworksPhase = PBXFrameworksBuildPhase()
            pbxproj.add(object: frameworksPhase!)
            widgetTarget!.buildPhases.append(frameworksPhase!)
        }

        var resourcesPhase = widgetTarget!.buildPhases.compactMap({ $0 as? PBXResourcesBuildPhase }).first
        if resourcesPhase == nil {
            resourcesPhase = PBXResourcesBuildPhase()
            pbxproj.add(object: resourcesPhase!)
            widgetTarget!.buildPhases.append(resourcesPhase!)
        }
        
        // 4. Create or get group for widget files
        let mainGroup = rootProject.mainGroup
        var widgetGroup = mainGroup?.children.first(where: { $0.path == "LogCalWidget" || $0.name == "LogCalWidget" }) as? PBXGroup
        if widgetGroup == nil {
            widgetGroup = PBXGroup(path: "LogCalWidget", sourceTree: .group)
            pbxproj.add(object: widgetGroup!)
            mainGroup?.children.append(widgetGroup!)
            print("Created LogCalWidget project group")
        } else {
            print("LogCalWidget project group already exists")
        }
        
        // Helper to add files to group and sources phase
        func addFileToGroupAndTarget(fileName: String, isSource: Bool) throws {
            let fileRef: PBXFileReference
            if let existing = widgetGroup!.children.first(where: { $0.path == fileName || $0.name == fileName }) as? PBXFileReference {
                fileRef = existing
            } else {
                fileRef = PBXFileReference(
                    sourceTree: .group,
                    name: fileName,
                    lastKnownFileType: isSource ? "sourcecode.swift" : (fileName.hasSuffix(".entitlements") ? "text.plist.entitlements" : "text.plist.xml"),
                    path: fileName
                )
                pbxproj.add(object: fileRef)
                widgetGroup!.children.append(fileRef)
                print("Added reference for \(fileName) to project group")
            }
            
            if isSource {
                let buildFileExists = sourcesPhase!.files?.contains(where: { $0.file == fileRef }) ?? false
                if !buildFileExists {
                    let buildFile = PBXBuildFile(file: fileRef)
                    pbxproj.add(object: buildFile)
                    if sourcesPhase!.files == nil { sourcesPhase!.files = [] }
                    sourcesPhase!.files?.append(buildFile)
                    print("Added \(fileName) to sources build phase")
                }
            } else if fileName == "Info.plist" {
                // Info.plist is not compiles, but sometimes resources phase
            }
        }
        
        try addFileToGroupAndTarget(fileName: "LogCalWidget.swift", isSource: true)
        try addFileToGroupAndTarget(fileName: "LogCalWidgetViews.swift", isSource: true)
        try addFileToGroupAndTarget(fileName: "LogCalWidget.entitlements", isSource: false)
        try addFileToGroupAndTarget(fileName: "Info.plist", isSource: false)
        
        // 5. Link shared files to widget target sources
        func findFileReference(name: String) -> PBXFileReference? {
            return pbxproj.fileReferences.first(where: { $0.path?.hasSuffix("/" + name) == true || $0.path == name || $0.name == name })
        }
        
        let sharedFileNames = [
            "MealEntry.swift",
            "SavedMeal.swift",
            "MealLogResponse.swift",
            "DietStyle.swift",
            "AppTheme.swift"
        ]

        for sharedName in sharedFileNames {
            guard let fileRef = findFileReference(name: sharedName) else {
                print("Warning: Could not find file reference for shared file \(sharedName)")
                continue
            }
            let alreadyLinked = sourcesPhase!.files?.contains(where: { $0.file == fileRef }) ?? false
            if !alreadyLinked {
                let buildFile = PBXBuildFile(file: fileRef)
                pbxproj.add(object: buildFile)
                if sourcesPhase!.files == nil { sourcesPhase!.files = [] }
                sourcesPhase!.files?.append(buildFile)
                print("Linked shared file \(sharedName) to LogCalWidget sources build phase.")
            } else {
                print("Shared file \(sharedName) already linked")
            }
        }
        
        // 6. Connect widget target to main target
        guard let mainTarget = pbxproj.nativeTargets.first(where: { $0.name == "logcal" }) else {
            print("ERROR: Could not find main target 'logcal'")
            return
        }

        // 6.1 Add Target Dependency
        let alreadyDepends = mainTarget.dependencies.contains(where: { $0.target?.name == "LogCalWidget" })
        if !alreadyDepends {
            let targetProxy = PBXContainerItemProxy(
                containerPortal: .project(rootProject),
                remoteGlobalIDString: widgetTarget!.uuid,
                proxyType: .nativeTarget,
                remoteInfo: "LogCalWidget"
            )
            pbxproj.add(object: targetProxy)
            
            let dependency = PBXTargetDependency(target: widgetTarget!, targetProxy: targetProxy)
            pbxproj.add(object: dependency)
            mainTarget.dependencies.append(dependency)
            print("Added target dependency on LogCalWidget to main target 'logcal'")
        } else {
            print("Dependency on LogCalWidget already exists in main target")
        }

        // 6.2 Embed in PlugIns copy files phase
        var copyPhase = mainTarget.buildPhases.compactMap({ $0 as? PBXCopyFilesBuildPhase }).first(where: { $0.dstSubfolderSpec == .plugins })
        if copyPhase == nil {
            copyPhase = PBXCopyFilesBuildPhase(dstPath: "", dstSubfolderSpec: .plugins)
            pbxproj.add(object: copyPhase!)
            mainTarget.buildPhases.append(copyPhase!)
            print("Created PlugIns copy files phase in main target")
        }

        let alreadyEmbedded = copyPhase!.files?.contains(where: { $0.file == productRef }) ?? false
        if !alreadyEmbedded {
            let embedBuildFile = PBXBuildFile(file: productRef!)
            pbxproj.add(object: embedBuildFile)
            if copyPhase!.files == nil { copyPhase!.files = [] }
            copyPhase!.files?.append(embedBuildFile)
            print("Embedded LogCalWidget.appex in main target PlugIns phase")
        } else {
            print("LogCalWidget.appex already embedded in main target")
        }
        
        // Save the project changes
        try xcodeproj.write(path: projectPath)
        print("SUCCESS: Configured and saved project.pbxproj successfully!")
        
    } catch {
        print("ERROR: \(error)")
    }
}

main()

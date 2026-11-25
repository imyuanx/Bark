#!/usr/bin/env python3
"""Regenerate BarkMac.xcodeproj. The checked-in project is the output of this script."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJ = ROOT / "BarkMac.xcodeproj"


def ident(number: int) -> str:
    return f"AC{number:022X}"


class Ids:
    def __init__(self) -> None:
        self._n = 1

    def next(self) -> str:
        value = ident(self._n)
        self._n += 1
        return value


def main() -> None:
    ids = Ids()
    project_id = ids.next()
    target_id = ids.next()
    product_ref = ids.next()
    sources_phase = ids.next()
    frameworks_phase = ids.next()
    resources_phase = ids.next()
    target_config_list = ids.next()
    project_config_list = ids.next()
    debug_target = ids.next()
    release_target = ids.next()
    debug_project = ids.next()
    release_project = ids.next()
    main_group = ids.next()
    app_group = ids.next()
    core_group = ids.next()
    sources_group = ids.next()
    signing_group = ids.next()
    products_group = ids.next()

    compiled = {
        "App": [
            "APNsTokenClient.swift",
            "AppDelegate.swift",
            "AppModel.swift",
            "LiveBarkRegisterTransport.swift",
            "MacNotificationSDKProbe.swift",
            "MainWindowView.swift",
            "SettingsWindowView.swift",
            "StatusMenuController.swift",
            "WindowPresenter.swift",
        ],
        "Core": [
            "APNsTokenPolicy.swift",
            "AddressDraft.swift",
            "AppStorageKeys.swift",
            "DeliveryStages.swift",
            "DockPolicy.swift",
            "KeyIsolation.swift",
            "NotificationPermissionCopy.swift",
            "PrivacySummary.swift",
            "PushLink.swift",
            "RegistrationGate.swift",
            "RegistrationPolicy.swift",
            "WindowPolicy.swift",
        ],
    }
    uncompiled = {
        "App": ["Info.plist"],
        "Core": ["BarkHTTPShape.swift"],
        "Signing": ["Local.xcconfig.example", "Push.entitlements.example", "Unsigned.xcconfig"],
        "Root": ["Package.swift", "README.md"],
    }

    file_refs = {}
    build_files = []
    listed = {
        "App": compiled["App"] + uncompiled["App"],
        "Core": compiled["Core"] + uncompiled["Core"],
        "Signing": uncompiled["Signing"],
        "Root": uncompiled["Root"],
    }
    for folder, names in listed.items():
        for name in names:
            file_refs[(folder, name)] = ids.next()

    for folder in ("App", "Core"):
        for name in compiled[folder]:
            build_files.append((ids.next(), file_refs[(folder, name)], name))

    def file_ref(folder: str, name: str, kind: str) -> str:
        return (
            f"\t\t{file_refs[(folder, name)]} /* {name} */ = {{\n"
            f"\t\t\tisa = PBXFileReference;\n"
            f"\t\t\tlastKnownFileType = {kind};\n"
            f"\t\t\tpath = {name};\n"
            f"\t\t\tsourceTree = \"<group>\";\n"
            f"\t\t}};\n"
        )

    kinds = {
        ".swift": "sourcecode.swift",
        ".plist": "text.plist.xml",
        ".example": "text",
        ".md": "net.daringfireball.markdown",
    }

    def kind_for(name: str) -> str:
        if name.endswith(".xcconfig"):
            return "text.xcconfig"
        if name.endswith(".xcconfig.example") or name.endswith(".entitlements.example"):
            return "text"
        return kinds[Path(name).suffix]

    file_ref_text = []
    file_ref_text.append(
        f"\t\t{product_ref} /* BarkMac.app */ = {{\n"
        "\t\t\tisa = PBXFileReference;\n"
        "\t\t\texplicitFileType = wrapper.application;\n"
        "\t\t\tincludeInIndex = 0;\n"
        "\t\t\tpath = BarkMac.app;\n"
        "\t\t\tsourceTree = BUILT_PRODUCTS_DIR;\n"
        "\t\t};\n"
    )
    for folder, names in compiled.items():
        for name in names:
            file_ref_text.append(file_ref(folder, name, kind_for(name)))
    for folder, names in uncompiled.items():
        for name in names:
            file_ref_text.append(file_ref(folder, name, kind_for(name)))

    build_text = []
    for build_id, ref, name in build_files:
        build_text.append(
            f"\t\t{build_id} /* {name} in Sources */ = {{\n"
            "\t\t\tisa = PBXBuildFile;\n"
            f"\t\t\tfileRef = {ref} /* {name} */;\n"
            "\t\t};\n"
        )

    def children(folder: str, names: list[str]) -> str:
        return "".join(f"\t\t\t\t{file_refs[(folder, name)]} /* {name} */,\n" for name in names)

    app_names = compiled["App"] + uncompiled["App"]
    core_names = compiled["Core"] + uncompiled["Core"]

    source_lines = "".join(
        f"\t\t\t\t{build_id} /* {name} in Sources */,\n" for build_id, _, name in build_files
    )

    target_settings = """
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_HARDENED_RUNTIME = NO;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = App/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 0.1.0;
				PRODUCT_NAME = BarkMac;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
"""

    pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{''.join(build_text)}/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{''.join(file_ref_text)}/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{main_group} = {{
			isa = PBXGroup;
			children = (
				{app_group} /* App */,
				{sources_group} /* Sources */,
				{signing_group} /* Signing */,
				{file_refs[("Root", "Package.swift")]} /* Package.swift */,
				{file_refs[("Root", "README.md")]} /* README.md */,
				{products_group} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{app_group} /* App */ = {{
			isa = PBXGroup;
			children = (
{children("App", app_names)}			);
			path = App;
			sourceTree = "<group>";
		}};
		{sources_group} /* Sources */ = {{
			isa = PBXGroup;
			children = (
				{core_group} /* BarkMacCore */,
			);
			path = Sources;
			sourceTree = "<group>";
		}};
		{core_group} /* BarkMacCore */ = {{
			isa = PBXGroup;
			children = (
{children("Core", core_names)}			);
			path = BarkMacCore;
			sourceTree = "<group>";
		}};
		{signing_group} /* Signing */ = {{
			isa = PBXGroup;
			children = (
{children("Signing", uncompiled["Signing"])}			);
			path = Signing;
			sourceTree = "<group>";
		}};
		{products_group} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{product_ref} /* BarkMac.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_id} /* BarkMac */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {target_config_list} /* Build configuration list for PBXNativeTarget "BarkMac" */;
			buildPhases = (
				{sources_phase} /* Sources */,
				{frameworks_phase} /* Frameworks */,
				{resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = BarkMac;
			productName = BarkMac;
			productReference = {product_ref} /* BarkMac.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{target_id} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {project_config_list} /* Build configuration list for PBXProject "BarkMac" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = "zh-Hans";
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
				"zh-Hans",
			);
			mainGroup = {main_group};
			productRefGroup = {products_group} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_id} /* BarkMac */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{source_lines}			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{debug_project} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_NS_ASSERTIONS = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				MACOSX_DEPLOYMENT_TARGET = 12.0;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{release_project} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				MACOSX_DEPLOYMENT_TARGET = 12.0;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			}};
			name = Release;
		}};
		{debug_target} /* Debug */ = {{
			isa = XCBuildConfiguration;
			baseConfigurationReference = {file_refs[("Signing", "Unsigned.xcconfig")]} /* Unsigned.xcconfig */;
			buildSettings = {{
{target_settings}			}};
			name = Debug;
		}};
		{release_target} /* Release */ = {{
			isa = XCBuildConfiguration;
			baseConfigurationReference = {file_refs[("Signing", "Unsigned.xcconfig")]} /* Unsigned.xcconfig */;
			buildSettings = {{
{target_settings}			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{project_config_list} /* Build configuration list for PBXProject "BarkMac" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_project} /* Debug */,
				{release_project} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{target_config_list} /* Build configuration list for PBXNativeTarget "BarkMac" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_target} /* Debug */,
				{release_target} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {project_id} /* Project object */;
}}
"""

    project_dir = PROJ
    project_dir.mkdir(parents=True, exist_ok=True)
    (project_dir / "project.pbxproj").write_text(pbx, encoding="utf-8")

    scheme_dir = project_dir / "xcshareddata" / "xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "BarkMac.app"
               BlueprintName = "BarkMac"
               ReferencedContainer = "container:BarkMac.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "BarkMac.app"
            BlueprintName = "BarkMac"
            ReferencedContainer = "container:BarkMac.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "BarkMac.app"
            BlueprintName = "BarkMac"
            ReferencedContainer = "container:BarkMac.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    (scheme_dir / "BarkMac.xcscheme").write_text(scheme, encoding="utf-8")
    print(f"wrote {project_dir / 'project.pbxproj'}")
    print(f"target {target_id}")


if __name__ == "__main__":
    main()

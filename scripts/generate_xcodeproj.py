#!/usr/bin/env python3
"""
Generates a clean, deterministic Xcode 15/16+ project (JapaneseBurmeseDictionary.xcodeproj)
with iOS App target + Unit Test target + shared scheme.
"""

from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def uid(key: str) -> str:
    return hashlib.sha1(f"JapaneseBurmeseDictionary::{key}".encode("utf-8")).hexdigest()[:24].upper()


APP_GROUPS = {
    "App": ["JapaneseBurmeseDictionaryApp.swift"],
    "Models": ["DictionaryEntry.swift", "SearchQueryInfo.swift"],
    "Services": [
        "BurmeseNormalizer.swift",
        "RomajiKanaConverter.swift",
        "JapaneseDeinflector.swift",
        "DictionarySearchEngine.swift",
        "DictionaryRepository.swift",
        "SpeechService.swift",
        "UserWordsStore.swift",
    ],
    "ViewModels": ["DictionaryViewModel.swift"],
    "Views": [
        "MainTabView.swift",
        "EntryRowView.swift",
        "SearchHomeView.swift",
        "EntryDetailView.swift",
        "BrowseCategoriesView.swift",
        "BookmarksView.swift",
        "AddCustomWordSheet.swift",
        "FlashcardStudyView.swift",
    ],
}

TEST_FILES = ["DictionarySearchEngineTests.swift"]


def verify_files_exist() -> None:
    app_dir = ROOT / "JapaneseBurmeseDictionary"
    for group_name, filenames in APP_GROUPS.items():
        for fn in filenames:
            p = app_dir / group_name / fn
            if not p.is_file():
                raise FileNotFoundError(f"Missing Swift file: {p}")
    if not (app_dir / "Assets.xcassets" / "Contents.json").is_file():
        raise FileNotFoundError("Missing Assets.xcassets/Contents.json")
    if not (app_dir / "Resources" / "dictionary_entries.json").is_file():
        raise FileNotFoundError("Missing Resources/dictionary_entries.json")
    for fn in TEST_FILES:
        p = ROOT / "JapaneseBurmeseDictionaryTests" / fn
        if not p.is_file():
            raise FileNotFoundError(f"Missing test file: {p}")


def build_pbxproj() -> str:
    project_id = uid("PBXProject")
    main_group_id = uid("MainGroup")
    products_group_id = uid("ProductsGroup")
    app_root_group_id = uid("AppRootGroup")
    resources_group_id = uid("ResourcesGroup")
    tests_group_id = uid("TestsGroup")

    app_product_id = uid("Product::App")
    test_product_id = uid("Product::Tests")

    app_target_id = uid("Target::App")
    test_target_id = uid("Target::Tests")

    app_sources_phase_id = uid("Phase::AppSources")
    app_frameworks_phase_id = uid("Phase::AppFrameworks")
    app_resources_phase_id = uid("Phase::AppResources")

    test_sources_phase_id = uid("Phase::TestSources")
    test_frameworks_phase_id = uid("Phase::TestFrameworks")
    test_resources_phase_id = uid("Phase::TestResources")

    target_dep_id = uid("TargetDependency::Tests->App")
    proxy_id = uid("ContainerItemProxy::Tests->App")

    proj_cfg_list_id = uid("ConfigList::Project")
    app_cfg_list_id = uid("ConfigList::App")
    test_cfg_list_id = uid("ConfigList::Tests")

    proj_debug_id = uid("Config::Project::Debug")
    proj_release_id = uid("Config::Project::Release")
    app_debug_id = uid("Config::App::Debug")
    app_release_id = uid("Config::App::Release")
    test_debug_id = uid("Config::Tests::Debug")
    test_release_id = uid("Config::Tests::Release")

    build_files: list[str] = []
    file_refs: list[str] = []
    subgroups: list[str] = []
    app_source_build_ids: list[str] = []
    app_resource_build_ids: list[str] = []
    test_source_build_ids: list[str] = []

    # Products file references
    file_refs.append(
        f'\t\t{app_product_id} /* JapaneseBurmeseDictionary.app */ = '
        f'{{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; '
        f'path = JapaneseBurmeseDictionary.app; sourceTree = BUILT_PRODUCTS_DIR; }};'
    )
    file_refs.append(
        f'\t\t{test_product_id} /* JapaneseBurmeseDictionaryTests.xctest */ = '
        f'{{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; '
        f'path = JapaneseBurmeseDictionaryTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};'
    )

    app_group_child_ids: list[str] = []

    for group_name, filenames in APP_GROUPS.items():
        grp_id = uid(f"Group::{group_name}")
        app_group_child_ids.append(grp_id)
        child_ref_ids: list[str] = []
        for fn in filenames:
            fref_id = uid(f"FileRef::{group_name}/{fn}")
            bfile_id = uid(f"BuildFile::{group_name}/{fn}")
            child_ref_ids.append(fref_id)
            app_source_build_ids.append(bfile_id)
            file_refs.append(
                f'\t\t{fref_id} /* {fn} */ = '
                f'{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fn}; sourceTree = "<group>"; }};'
            )
            build_files.append(
                f'\t\t{bfile_id} /* {fn} in Sources */ = {{isa = PBXBuildFile; fileRef = {fref_id} /* {fn} */; }};'
            )
        children_str = "\n".join(f"\t\t\t\t{cid} /* {fn} */," for cid, fn in zip(child_ref_ids, filenames))
        subgroups.append(
            f"\t\t{grp_id} /* {group_name} */ = {{\n"
            f"\t\t\tisa = PBXGroup;\n"
            f"\t\t\tchildren = (\n{children_str}\n\t\t\t);\n"
            f"\t\t\tpath = {group_name};\n"
            f'\t\t\tsourceTree = "<group>";\n'
            f"\t\t}};"
        )

    # Resources group + Assets.xcassets
    dict_json_ref = uid("FileRef::Resources/dictionary_entries.json")
    dict_json_bf = uid("BuildFile::Resources/dictionary_entries.json")
    assets_ref = uid("FileRef::Assets.xcassets")
    assets_bf = uid("BuildFile::Assets.xcassets")

    file_refs.append(
        f'\t\t{dict_json_ref} /* dictionary_entries.json */ = '
        f'{{isa = PBXFileReference; lastKnownFileType = text.json; path = dictionary_entries.json; sourceTree = "<group>"; }};'
    )
    build_files.append(
        f'\t\t{dict_json_bf} /* dictionary_entries.json in Resources */ = '
        f'{{isa = PBXBuildFile; fileRef = {dict_json_ref} /* dictionary_entries.json */; }};'
    )
    file_refs.append(
        f'\t\t{assets_ref} /* Assets.xcassets */ = '
        f'{{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};'
    )
    build_files.append(
        f'\t\t{assets_bf} /* Assets.xcassets in Resources */ = '
        f'{{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};'
    )

    app_resource_build_ids.extend([assets_bf, dict_json_bf])
    app_group_child_ids.extend([resources_group_id, assets_ref])

    subgroups.append(
        f"\t\t{resources_group_id} /* Resources */ = {{\n"
        f"\t\t\tisa = PBXGroup;\n"
        f"\t\t\tchildren = (\n\t\t\t\t{dict_json_ref} /* dictionary_entries.json */,\n\t\t\t);\n"
        f"\t\t\tpath = Resources;\n"
        f'\t\t\tsourceTree = "<group>";\n'
        f"\t\t}};"
    )

    # Tests group & files
    test_child_refs: list[str] = []
    for fn in TEST_FILES:
        fref_id = uid(f"FileRef::Tests/{fn}")
        bfile_id = uid(f"BuildFile::Tests/{fn}")
        test_child_refs.append(fref_id)
        test_source_build_ids.append(bfile_id)
        file_refs.append(
            f'\t\t{fref_id} /* {fn} */ = '
            f'{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fn}; sourceTree = "<group>"; }};'
        )
        build_files.append(
            f'\t\t{bfile_id} /* {fn} in Sources */ = {{isa = PBXBuildFile; fileRef = {fref_id} /* {fn} */; }};'
        )

    app_root_children_str = "\n".join(f"\t\t\t\t{cid}," for cid in app_group_child_ids)
    test_children_str = "\n".join(f"\t\t\t\t{cid}," for cid in test_child_refs)
    app_sources_str = "\n".join(f"\t\t\t\t{bid}," for bid in app_source_build_ids)
    app_resources_str = "\n".join(f"\t\t\t\t{bid}," for bid in app_resource_build_ids)
    test_sources_str = "\n".join(f"\t\t\t\t{bid}," for bid in test_source_build_ids)

    return f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_files)}
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
\t\t{proxy_id} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {project_id} /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {app_target_id};
\t\t\tremoteInfo = JapaneseBurmeseDictionary;
\t\t}};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
{chr(10).join(file_refs)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{app_frameworks_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{test_frameworks_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group_id} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_root_group_id} /* JapaneseBurmeseDictionary */,
\t\t\t\t{tests_group_id} /* JapaneseBurmeseDictionaryTests */,
\t\t\t\t{products_group_id} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_product_id} /* JapaneseBurmeseDictionary.app */,
\t\t\t\t{test_product_id} /* JapaneseBurmeseDictionaryTests.xctest */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{app_root_group_id} /* JapaneseBurmeseDictionary */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{app_root_children_str}
\t\t\t);
\t\t\tpath = JapaneseBurmeseDictionary;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{tests_group_id} /* JapaneseBurmeseDictionaryTests */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{test_children_str}
\t\t\t);
\t\t\tpath = JapaneseBurmeseDictionaryTests;
\t\t\tsourceTree = "<group>";
\t\t}};
{chr(10).join(subgroups)}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{app_target_id} /* JapaneseBurmeseDictionary */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {app_cfg_list_id} /* Build configuration list for PBXNativeTarget "JapaneseBurmeseDictionary" */;
\t\t\tbuildPhases = (
\t\t\t\t{app_sources_phase_id} /* Sources */,
\t\t\t\t{app_frameworks_phase_id} /* Frameworks */,
\t\t\t\t{app_resources_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = JapaneseBurmeseDictionary;
\t\t\tproductName = JapaneseBurmeseDictionary;
\t\t\tproductReference = {app_product_id} /* JapaneseBurmeseDictionary.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
\t\t{test_target_id} /* JapaneseBurmeseDictionaryTests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {test_cfg_list_id} /* Build configuration list for PBXNativeTarget "JapaneseBurmeseDictionaryTests" */;
\t\t\tbuildPhases = (
\t\t\t\t{test_sources_phase_id} /* Sources */,
\t\t\t\t{test_frameworks_phase_id} /* Frameworks */,
\t\t\t\t{test_resources_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t{target_dep_id} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = JapaneseBurmeseDictionaryTests;
\t\t\tproductName = JapaneseBurmeseDictionaryTests;
\t\t\tproductReference = {test_product_id} /* JapaneseBurmeseDictionaryTests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{app_target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t\t{test_target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t\tTestTargetID = {app_target_id};
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {proj_cfg_list_id} /* Build configuration list for PBXProject "JapaneseBurmeseDictionary" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group_id};
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{app_target_id} /* JapaneseBurmeseDictionary */,
\t\t\t\t{test_target_id} /* JapaneseBurmeseDictionaryTests */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{app_resources_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{app_resources_str}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{test_resources_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{app_sources_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{app_sources_str}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{test_sources_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{test_sources_str}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
\t\t{target_dep_id} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {app_target_id} /* JapaneseBurmeseDictionary */;
\t\t\ttargetProxy = {proxy_id} /* PBXContainerItemProxy */;
\t\t}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
\t\t{proj_debug_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{proj_release_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{app_debug_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "JP-MM Dict";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.hlaingbwaraung.JapaneseBurmeseDictionary;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{app_release_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "JP-MM Dict";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.hlaingbwaraung.JapaneseBurmeseDictionary;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{test_debug_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.hlaingbwaraung.JapaneseBurmeseDictionaryTests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/JapaneseBurmeseDictionary.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/JapaneseBurmeseDictionary";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{test_release_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.hlaingbwaraung.JapaneseBurmeseDictionaryTests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/JapaneseBurmeseDictionary.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/JapaneseBurmeseDictionary";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{proj_cfg_list_id} /* Build configuration list for PBXProject "JapaneseBurmeseDictionary" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{proj_debug_id} /* Debug */,
\t\t\t\t{proj_release_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{app_cfg_list_id} /* Build configuration list for PBXNativeTarget "JapaneseBurmeseDictionary" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{app_debug_id} /* Debug */,
\t\t\t\t{app_release_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{test_cfg_list_id} /* Build configuration list for PBXNativeTarget "JapaneseBurmeseDictionaryTests" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{test_debug_id} /* Debug */,
\t\t\t\t{test_release_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {project_id} /* Project object */;
}}
"""


def build_scheme() -> str:
    app_target_id = uid("Target::App")
    test_target_id = uid("Target::Tests")
    return f"""<?xml version="1.0" encoding="UTF-8"?>
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
               BlueprintIdentifier = "{app_target_id}"
               BuildableName = "JapaneseBurmeseDictionary.app"
               BlueprintName = "JapaneseBurmeseDictionary"
               ReferencedContainer = "container:JapaneseBurmeseDictionary.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{test_target_id}"
               BuildableName = "JapaneseBurmeseDictionaryTests.xctest"
               BlueprintName = "JapaneseBurmeseDictionaryTests"
               ReferencedContainer = "container:JapaneseBurmeseDictionary.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
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
            BlueprintIdentifier = "{app_target_id}"
            BuildableName = "JapaneseBurmeseDictionary.app"
            BlueprintName = "JapaneseBurmeseDictionary"
            ReferencedContainer = "container:JapaneseBurmeseDictionary.xcodeproj">
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
            BlueprintIdentifier = "{app_target_id}"
            BuildableName = "JapaneseBurmeseDictionary.app"
            BlueprintName = "JapaneseBurmeseDictionary"
            ReferencedContainer = "container:JapaneseBurmeseDictionary.xcodeproj">
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


def main() -> None:
    verify_files_exist()
    xcodeproj = ROOT / "JapaneseBurmeseDictionary.xcodeproj"
    pbx_path = xcodeproj / "project.pbxproj"
    ws_path = xcodeproj / "project.xcworkspace" / "contents.xcworkspacedata"
    scheme_path = xcodeproj / "xcshareddata" / "xcschemes" / "JapaneseBurmeseDictionary.xcscheme"

    pbx_path.parent.mkdir(parents=True, exist_ok=True)
    ws_path.parent.mkdir(parents=True, exist_ok=True)
    scheme_path.parent.mkdir(parents=True, exist_ok=True)

    pbx_path.write_text(build_pbxproj(), encoding="utf-8")
    ws_path.write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<Workspace\n   version = "1.0">\n'
        '   <FileRef\n      location = "self:">\n   </FileRef>\n'
        '</Workspace>\n',
        encoding="utf-8",
    )
    scheme_path.write_text(build_scheme(), encoding="utf-8")
    print(f"Generated valid Xcode project -> {xcodeproj}")


if __name__ == "__main__":
    main()

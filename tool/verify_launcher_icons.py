"""
Universal Android Launcher Icon Blueprint Verification Script
Validates all requirements of the blueprint:
- AndroidManifest.xml configuration
- Adaptive icon XMLs and monochrome tags
- Icon pack drawable
- Safe-zone geometry math
- Pre-cropped legacy round mipmap transparency
- Launch splash configuration
- Master transparent and monochrome assets
"""

import os
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES_DIR = os.path.join(ROOT_DIR, "android", "app", "src", "main", "res")
MANIFEST_PATH = os.path.join(ROOT_DIR, "android", "app", "src", "main", "AndroidManifest.xml")

DENSITIES = ["mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"]

def check(condition: bool, description: str):
    if condition:
        print(f"  [PASS] {description}")
    else:
        print(f"  [FAIL] {description}")
        raise AssertionError(f"Check failed: {description}")


def test_manifest():
    print("\n--- 1. Testing AndroidManifest.xml ---")
    tree = ET.parse(MANIFEST_PATH)
    root = tree.getroot()
    # Find application element
    app = root.find("application")
    android_ns = "{http://schemas.android.com/apk/res/android}"
    icon = app.attrib.get(f"{android_ns}icon")
    round_icon = app.attrib.get(f"{android_ns}roundIcon")
    
    check(icon == "@mipmap/ic_launcher", f"android:icon is '@mipmap/ic_launcher' (found '{icon}')")
    check(round_icon == "@mipmap/ic_launcher_round", f"android:roundIcon is '@mipmap/ic_launcher_round' (found '{round_icon}')")


def test_colors_xml():
    print("\n--- 2. Testing res/values/colors.xml ---")
    colors_path = os.path.join(RES_DIR, "values", "colors.xml")
    check(os.path.exists(colors_path), "res/values/colors.xml exists")
    tree = ET.parse(colors_path)
    root = tree.getroot()
    color_el = None
    for c in root.findall("color"):
        if c.attrib.get("name") == "ic_launcher_background":
            color_el = c
            break
    check(color_el is not None, "ic_launcher_background color is defined in colors.xml")
    check(color_el.text.upper() == "#FCF7EC", f"ic_launcher_background is #FCF7EC (found '{color_el.text}')")


def test_adaptive_xmls():
    print("\n--- 3. Testing res/mipmap-anydpi-v26/ XMLs ---")
    for name in ["ic_launcher.xml", "ic_launcher_round.xml"]:
        xml_path = os.path.join(RES_DIR, "mipmap-anydpi-v26", name)
        check(os.path.exists(xml_path), f"{name} exists in res/mipmap-anydpi-v26/")
        tree = ET.parse(xml_path)
        root = tree.getroot()
        check(root.tag == "adaptive-icon", f"{name} root is <adaptive-icon>")
        
        android_ns = "{http://schemas.android.com/apk/res/android}"
        bg = root.find("background")
        fg = root.find("foreground")
        mono = root.find("monochrome")
        
        check(bg is not None and bg.attrib.get(f"{android_ns}drawable") == "@color/ic_launcher_background",
              f"{name} has <background android:drawable='@color/ic_launcher_background'>")
        check(fg is not None and fg.attrib.get(f"{android_ns}drawable") == "@drawable/ic_launcher_foreground",
              f"{name} has <foreground android:drawable='@drawable/ic_launcher_foreground'>")
        check(mono is not None and mono.attrib.get(f"{android_ns}drawable") == "@drawable/ic_launcher_monochrome",
              f"{name} has <monochrome android:drawable='@drawable/ic_launcher_monochrome'>")


def test_icon_pack_drawable():
    print("\n--- 4. Testing res/drawable/ic_launcher.xml ---")
    drawable_path = os.path.join(RES_DIR, "drawable", "ic_launcher.xml")
    check(os.path.exists(drawable_path), "res/drawable/ic_launcher.xml exists")
    tree = ET.parse(drawable_path)
    root = tree.getroot()
    android_ns = "{http://schemas.android.com/apk/res/android}"
    check(root.tag == "bitmap", "Root element is <bitmap>")
    check(root.attrib.get(f"{android_ns}src") == "@drawable/ic_launcher_foreground",
          "android:src is '@drawable/ic_launcher_foreground'")


def test_master_icons():
    print("\n--- 5. Testing Master Icons ---")
    trans_path = os.path.join(ROOT_DIR, "assets", "icons", "icon_transparent.png")
    mono_path = os.path.join(ROOT_DIR, "assets", "icons", "icon_monochrome.png")
    
    check(os.path.exists(trans_path), "assets/icons/icon_transparent.png exists")
    img_t = Image.open(trans_path)
    check(img_t.size == (2048, 2048), f"icon_transparent.png size is 2048x2048 (found {img_t.size})")
    arr_t = np.array(img_t)
    check(arr_t[0, 0, 3] == 0 and arr_t[0, -1, 3] == 0 and arr_t[-1, 0, 3] == 0 and arr_t[-1, -1, 3] == 0,
          "icon_transparent.png outer corners have alpha = 0")
    
    check(os.path.exists(mono_path), "assets/icons/icon_monochrome.png exists")
    img_m = Image.open(mono_path)
    check(img_m.size == (2048, 2048), f"icon_monochrome.png size is 2048x2048 (found {img_m.size})")


def test_adaptive_safe_zone():
    print("\n--- 6. Testing Adaptive Foreground & Safe-Zone Compliance ---")
    expected_sizes = {
        "mdpi": 108,
        "hdpi": 162,
        "xhdpi": 216,
        "xxhdpi": 324,
        "xxxhdpi": 432
    }
    for d, sz in expected_sizes.items():
        dir_name = f"drawable-{d}"
        fg_path = os.path.join(RES_DIR, dir_name, "ic_launcher_foreground.png")
        mono_path = os.path.join(RES_DIR, dir_name, "ic_launcher_monochrome.png")
        check(os.path.exists(fg_path), f"{dir_name}/ic_launcher_foreground.png exists")
        check(os.path.exists(mono_path), f"{dir_name}/ic_launcher_monochrome.png exists")
        
        img = Image.open(fg_path)
        check(img.size == (sz, sz), f"{fg_path} dimensions are {sz}x{sz}")
        
        # Check safe-zone: on 108dp canvas, safe zone is circle of diameter 66dp centered at (54, 54)
        # Radius in pixels: (66.0 / 108.0) * (sz / 2.0)
        safe_radius = (66.0 / 108.0) * (sz / 2.0)
        center = (sz - 1.0) / 2.0
        
        arr = np.array(img)
        # Any pixel with alpha > 10 should be within safe_radius
        y, x = np.ogrid[:sz, :sz]
        dist = np.sqrt((x - center)**2 + (y - center)**2)
        
        non_transparent = arr[:, :, 3] > 10
        if np.any(non_transparent):
            max_dist_emblem = dist[non_transparent].max()
            check(max_dist_emblem <= safe_radius + 0.5,
                  f"{dir_name} emblem max distance {max_dist_emblem:.2f}px <= safe-zone radius {safe_radius:.2f}px")


def test_legacy_round_mipmaps():
    print("\n--- 7. Testing Pre-Cropped Circular Legacy Mipmaps ---")
    expected_sizes = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192
    }
    for d, sz in expected_sizes.items():
        dir_name = f"mipmap-{d}"
        round_path = os.path.join(RES_DIR, dir_name, "ic_launcher_round.png")
        sq_path = os.path.join(RES_DIR, dir_name, "ic_launcher.png")
        check(os.path.exists(round_path), f"{dir_name}/ic_launcher_round.png exists")
        check(os.path.exists(sq_path), f"{dir_name}/ic_launcher.png exists")
        
        img = Image.open(round_path)
        check(img.size == (sz, sz), f"{round_path} dimensions are {sz}x{sz}")
        
        arr = np.array(img)
        center = (sz - 1.0) / 2.0
        radius = sz / 2.0
        y, x = np.ogrid[:sz, :sz]
        dist = np.sqrt((x - center)**2 + (y - center)**2)
        
        # Pixels with dist >= radius + 0.5 must have alpha == 0
        outside = dist >= (radius + 0.5)
        outside_alphas = arr[outside, 3]
        max_outside_alpha = outside_alphas.max() if len(outside_alphas) > 0 else 0
        check(max_outside_alpha == 0,
              f"{dir_name}/ic_launcher_round.png outside circle alpha is strictly 0 (max={max_outside_alpha})")


def test_splash_screen():
    print("\n--- 8. Testing Launch Splash Configuration ---")
    expected_sizes = {
        "mdpi": 96,
        "hdpi": 144,
        "xhdpi": 192,
        "xxhdpi": 288,
        "xxxhdpi": 384
    }
    for d, sz in expected_sizes.items():
        splash_path = os.path.join(RES_DIR, f"drawable-{d}", "launch_image.png")
        check(os.path.exists(splash_path), f"drawable-{d}/launch_image.png exists")
        img = Image.open(splash_path)
        check(img.size == (sz, sz), f"launch_image.png in drawable-{d} is {sz}x{sz}")
    
    for f in ["launch_background.xml", "../drawable-v21/launch_background.xml"]:
        lb_path = os.path.join(RES_DIR, "drawable", f)
        check(os.path.exists(lb_path), f"{f} exists")
        with open(lb_path, "r", encoding="utf-8") as fh:
            content = fh.read()
            check("@drawable/launch_image" in content, f"{f} references @drawable/launch_image")


def main():
    print("==================================================")
    print(" Running Universal Android Icon Blueprint Checks ")
    print("==================================================")
    test_manifest()
    test_colors_xml()
    test_adaptive_xmls()
    test_icon_pack_drawable()
    test_master_icons()
    test_adaptive_safe_zone()
    test_legacy_round_mipmaps()
    test_splash_screen()
    print("\n==================================================")
    print(" ALL 8 BLUEPRINT VALIDATION SUITES PASSED!       ")
    print("==================================================")


if __name__ == "__main__":
    main()

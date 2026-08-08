
import json
import os
import re

CONFIG_PATH = os.path.expanduser("~/.config/waybar/config.jsonc")
MODULES_DIR = os.path.expanduser("~/.config/waybar/modules")

def get_module_name(filename):
    filepath = os.path.join(MODULES_DIR, filename)
    try:
        with open(filepath, "r") as f:
            # Basic strip comments
            pattern = r"//.*?$|/\*.*?\*/"
            clean = re.sub(pattern, "", f.read(), flags=re.MULTILINE | re.DOTALL)
            data = json.loads(clean)
            if data:
                return list(data.keys())[0]
    except Exception as e:
        print(f"Error reading {filename}: {e}")
    return filename.replace(".jsonc", "")

def main():
    with open(CONFIG_PATH, "r") as f:
        # crude comment strip for this test
        content = re.sub(r"//.*?$|/\*.*?\*/", "", f.read(), flags=re.MULTILINE | re.DOTALL)
        data = json.loads(content)
        
    dp1 = data[0] # DP-1
    
    filename = "calendar-script.jsonc"
    mod_name = get_module_name(filename)
    
    print(f"File: {filename}")
    print(f"Detected Module Name: '{mod_name}'")
    
    print("\n--- DP-1 Config ---")
    print(f"Include list: {dp1.get('include', [])}")
    print(f"Left: {dp1.get('modules-left', [])}")
    print(f"Center: {dp1.get('modules-center', [])}")
    print(f"Right: {dp1.get('modules-right', [])}")
    
    is_included = f"modules/{filename}" in dp1.get('include', [])
    print(f"\nIs Included? {is_included}")
    
    pos = "NONE"
    if mod_name in dp1.get('modules-left', []): pos = "LEFT"
    elif mod_name in dp1.get('modules-center', []): pos = "CENTER"
    elif mod_name in dp1.get('modules-right', []): pos = "RIGHT"
    
    print(f"Detected Position: {pos}")

if __name__ == "__main__":
    main()

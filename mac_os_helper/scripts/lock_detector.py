#!/usr/bin/env python3
"""
Screen lock detector that runs Wi-Fi disable script when screen locks.
Uses Quartz Display Services to detect screen lock events.
"""

import subprocess
import time
import os
import sys
from Quartz import CGSessionCopyCurrentDictionary

def is_screen_locked():
    """Check if screen is currently locked"""
    try:
        session_dict = CGSessionCopyCurrentDictionary()
        if session_dict is None:
            return False
        
        # Check for screen lock indicators
        screen_locked = session_dict.get("CGSSessionScreenIsLocked", False)
        return bool(screen_locked)
    except:
        return False

def run_wifi_disable():
    """Run the Wi-Fi disable script"""
    script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    script_path = os.path.join(script_dir, "scripts", "screenlock_monitor.sh")
    
    try:
        if os.path.exists(script_path):
            subprocess.run([script_path], check=False, capture_output=True)
            print(f"Screen locked - Wi-Fi disabled via {script_path}")
        else:
            print(f"Script not found: {script_path}")
    except Exception as e:
        print(f"Error running Wi-Fi disable script: {e}")

def main():
    """Main monitoring loop"""
    last_lock_state = False
    
    while True:
        try:
            current_lock_state = is_screen_locked()
            
            # Detect transition from unlocked to locked
            if current_lock_state and not last_lock_state:
                run_wifi_disable()
            
            last_lock_state = current_lock_state
            time.sleep(2)  # Check every 2 seconds
            
        except KeyboardInterrupt:
            print("Screen lock monitor stopped")
            break
        except Exception as e:
            print(f"Error in monitoring loop: {e}")
            time.sleep(5)  # Wait longer on error

if __name__ == "__main__":
    main()

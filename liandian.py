import time
import sys
import pyautogui
# 引入 keyboard 库，用于全局捕获键盘，解决游戏内快捷键失效问题
import keyboard  

# ================= 配置区域 =================
START_KEY = 'f4'      # 启动/暂停 的快捷键（可改为 'f8', 'ctrl+q' 等）
EXIT_KEY = 'esc'      # 彻底退出程序的快捷键
CLICK_INTERVAL = 0.05 # 点击间隔时间(秒)。0.05秒等于1秒点20次。如果游戏不反应，请调大到 0.1
# ============================================

# 取消 pyautogui 的自动保护延迟（加速点击）
pyautogui.PAUSE = 0
# 安全失败开关：当鼠标甩到屏幕四个角落时，连点器会自动停止，防止失控
pyautogui.FAILSAFE = True 

print("==========================================")
print("          Python 极速游戏连点器           ")
print("==========================================")
print(f"👉 使用说明：")
print(f"  1. 按下 [{START_KEY.upper()}] 键 -> 开启 或 暂停 连点")
print(f"  2. 按下 [{EXIT_KEY.upper()}] 键  -> 彻底退出连点器程序")
print(f"  3. 【应急手段】如果鼠标失控，直接把鼠标死劲甩到屏幕最左上角即可强制停止")
print("==========================================")
print("[状态] 程序已就绪，等待你按下快捷键...")

is_running = False

while True:
    # 1. 检测是否按下了退出键
    if keyboard.is_pressed(EXIT_KEY):
        print("\n[状态] 收到退出信号，程序已安全关闭。")
        sys.exit()

    # 2. 检测是否按下了启动/暂停键
    if keyboard.is_pressed(START_KEY):
        is_running = not is_running
        if is_running:
            print("[状态] ▶️ 连点器【已启动】... 正在疯狂点击中！")
        else:
            print("[状态] ⏸️ 连点器【已暂停】。")
        
        # 稍微等待一下，防止按键太快导致连续触发开关
        time.sleep(0.3)

    # 3. 如果处于运行状态，执行点击
    if is_running:
        pyautogui.click()
        time.sleep(CLICK_INTERVAL)
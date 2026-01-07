# FPGA Ping Pong Game (VHDL)


##  功能簡介 (Features)

* **LED 移位顯示**：球體 (LED) 會在左右兩端之間移動。
* **按鍵擊球判定**：
    * **成功回擊**：當球到達最邊緣時按下對應按鈕，球會反彈。
    * **提早揮拍 (Early)**：球未到達邊緣即按下按鈕，判為失誤，對方得分。
    * **錯過球 (Miss)**：球移出邊界仍未按下按鈕，判為失誤，對方得分。
* **計分系統**：左右各有一個 4-bit 計數器顯示分數，獲勝時分數自動加 1。
* **變速功能**：支援正常速度與隨機變速模式 (基於 LFSR 隨機數生成)。

---


---

## 模擬波形說明 (Waveform Analysis)

### 1. 成功回擊 (Successful Return)
**情境**：當球移動到最左邊 (`10000000`) 或最右邊 (`00000001`) 的瞬間，按下對應的按鈕。


<img width="772" height="476" alt="image" src="https://github.com/user-attachments/assets/e4782138-28d1-474f-88f3-88f185bd6815" />

> *圖說：球到達邊緣，按鈕訊號被觸發，狀態機成功切換方向。*

### 2. 隨機變速 (Random Speed Mode)
**情境**：將變速開關 `i_speed_switch` 拉高 (`1`)，啟用隨機速度模式。

* **機制**：系統根據內部的 LFSR 隨機數產生器，動態選擇不同的時鐘分頻訊號。

<img width="764" height="434" alt="image" src="https://github.com/user-attachments/assets/f8efc0ed-003d-4d39-8fc3-74ea1cda4939" />

> *圖說：啟用變速開關後，LED 移動的時間間隔發生變化（波形寬度不固定），展示了隨機速度功能。*
### 3. 過頭/失誤 (Miss / Overdue)
**情境**：球已經移動到邊界，但玩家沒有在該週期內按下按鈕，導致球移出 LED 顯示範圍 (`00000000`)。

* **結果**：`counter_move_state` 檢測到球消失，跳轉至 `win` 狀態 (對手得分)。

<img width="610" height="446" alt="image" src="https://github.com/user-attachments/assets/5b06cee2-5084-447e-9ae9-c22e25f2d3e3" />

> *圖說：LED 數值變為 0，狀態機判定失誤，進入獲勝結算狀態。*

---


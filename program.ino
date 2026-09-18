#include <Arduino.h>
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ST7789.h>

// Định nghĩa chân màn hình theo phần cứng của bạn
#define TFT_MOSI 41
#define TFT_SCLK 42
#define TFT_CS   38
#define TFT_DC   39
#define TFT_RST  40

#define STEP_PIN 19                   // Chân GPIO 19 điều khiển PUL+ của TB6600
const int stepsPerRevolution = 200;   // Số bước trên 1 vòng (chỉnh lại nếu bạn gạt microstep trên TB6600)

Adafruit_ST7789 tft = Adafruit_ST7789(TFT_CS, TFT_DC, TFT_MOSI, TFT_SCLK, TFT_RST);

float currentStepperAngle = 0.0;

// Hàm hiển thị góc quay Stepper ra màn hình TFT
void updateStepperDisplay(float angle) {
    tft.fillRect(20, 130, 200, 50, ST77XX_WHITE); // Xóa vùng chữ cũ
    tft.setCursor(20, 130);
    tft.setTextSize(2);
    tft.setTextColor(ST77XX_BLACK);
    tft.print("Step Angle:");
    tft.setCursor(20, 160);
    tft.setTextSize(3);
    tft.setTextColor(ST77XX_BLUE);
    tft.print(angle, 1);
    tft.print(" deg");
}

void setup() {
    Serial.begin(115200);
    
    // Cài đặt chân điều khiển bước
    pinMode(STEP_PIN, OUTPUT);

    // Khởi động màn hình ST7789
    tft.init(240, 320, SPI_MODE2);
    tft.setRotation(0);
    tft.fillScreen(ST77XX_WHITE);

    // Hiển thị giá trị ban đầu
    updateStepperDisplay(currentStepperAngle);
    
    Serial.println("=========================================");
    Serial.println(" He thong san sang! Nhap goc quay Stepper:");
    Serial.println(" (VD: 90, 180, 360, -90 va an Enter)");
    Serial.println("=========================================");
}

void loop() {
    // Kiểm tra dữ liệu nhập từ Serial Monitor (115200 baud)
    if (Serial.available() > 0) {
        float targetAngle = Serial.parseFloat(); 
        
        // Xóa ký tự xuống dòng dư thừa trong bộ đệm
        if (Serial.read() == '\n') { /* Bỏ qua */ }

        if (targetAngle != currentStepperAngle) {
            float angleDiff = targetAngle - currentStepperAngle;
            long totalSteps = (long)(abs(angleDiff) / 360.0 * stepsPerRevolution);

            Serial.print("Dang quay toi goc: ");
            Serial.print(targetAngle);
            Serial.println(" deg");

            // Phát xung điều khiển qua GPIO 19 tới chân PUL+ của TB6600
            for (long i = 0; i < totalSteps; i++) {
                digitalWrite(STEP_PIN, HIGH);
                delayMicroseconds(800); 
                digitalWrite(STEP_PIN, LOW);
                delayMicroseconds(800);

                // Cứ mỗi 100 bước lại nhường quyền cho hệ thống để tránh lỗi Watchdog Timeout (WDT)
                if (i % 100 == 0) {
                    yield(); 
                }
            }

            // Cập nhật góc mới và vẽ lại màn hình TFT
            currentStepperAngle = targetAngle;
            updateStepperDisplay(currentStepperAngle);
            
            Serial.println("Hoan thanh!");
        }
    }
}

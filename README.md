# FPGA-Based Obstacle Avoidance System Using Verilog
 ---
###23ECE383 – VLSI Design Laboratory Term Project

📘 **Project Overview**
This project presents the design, simulation, and FPGA implementation of an ultrasonic obstacle avoidance system using Verilog HDL. The system measures real-time distance between 0 cm and 49 cm with ±1 cm accuracy, displays it on a 7-segment display, and transmits data wirelessly through an ESP32 module. A web-based dashboard provides live updates and proximity alerts, offering a reliable safety solution for vehicle applications.

---

🎯 **Objectives**

* Design a Finite State Machine (FSM) in Verilog for ultrasonic distance measurement.
* Interface the HC-SR04 sensor with the Basys 3 FPGA board.
* Display measured distance on a multiplexed 7-segment display.
* Implement UART communication for data transmission to the ESP32 module.
* Host a local web dashboard using ESP32 for remote visualization and alerting.
* Validate design using RTL simulation, synthesis, and on-board testing.

---

🛠️ **Circuit Description**

**1️⃣ Ultrasonic Sensing & FSM Control**

* The FSM handles trigger generation, echo detection, and time measurement.
* A 10 µs trigger pulse initiates measurement; the echo pulse width determines distance.

**2️⃣ Display Interface**

* The measured distance is converted to BCD and displayed using a two-digit multiplexed 7-segment display.

**3️⃣ Wireless Transmission**

* A UART module sends updated distance readings to an ESP32 via serial communication (115200 bps).
* The ESP32 hosts a local webpage showing real-time distance and collision alerts.

---

⚙️ **Key Components**

| Component     | Specification                              |
| ------------- | ------------------------------------------ |
| FPGA Board    | Basys 3 (Xilinx Artix-7)                   |
| Sensor        | HC-SR04 Ultrasonic Sensor                  |
| Communication | ESP32 Wi-Fi Module                         |
| Power Supply  | 5 V (FPGA via USB)                         |
| Software      | Vivado 2025.1, ModelSim 10.5b, Arduino IDE |
| Display       | 7-Segment (2 digits, multiplexed)          |

---

🔢 **Technical Parameters**

| Parameter            | Value      |
| -------------------- | ---------- |
| Distance Range       | 0 – 49 cm  |
| Accuracy             | ±1 cm      |
| Update Rate          | 40 Hz      |
| UART Baud Rate       | 115200 bps |
| Measurement Interval | ~25 ms     |

---

🧩 **System Workflow**

1. **Reset** – Initializes registers and clears old data.
2. **Trigger Generation** – Sends a 10 µs pulse to the ultrasonic sensor.
3. **Echo Detection** – Measures the return pulse width.
4. **Distance Calculation** – Converts the pulse width to distance in cm.
5. **BCD Conversion** – Formats data for display.
6. **Display Update** – Refreshes 7-segment display.
7. **UART Transmission** – Sends updated data to ESP32 when distance changes.
8. **Cooldown** – Waits for sensor stability before the next cycle.

---

🧪 **Simulation & Implementation**

* **Vivado & ModelSim** used for RTL simulation, synthesis, and timing verification.
* **Basys 3 board** tested with HC-SR04 for live measurement.
* **ESP32** received UART data and displayed it on a locally hosted web interface.
* **Oscilloscope validation** confirmed accurate 10 µs trigger and echo timing.

---

📈 **Results**

| Condition       | Simulation Output         | Hardware Output | Web Output     |
| --------------- | ------------------------- | --------------- | -------------- |
| Obstacle ≥ 5 cm | Distance stable at ~49 cm | Correct display | 49 cm (normal) |
| Obstacle < 5 cm | Alert triggered           | RED indicator   | 2 cm + ALERT   |

✅ **Waveform Accuracy:** ±1 cm error margin
✅ **System Stability:** Consistent readings across test cases
✅ **Wireless Dashboard:** Real-time update at 0.25 s refresh rate

---

⚠️ **Challenges & Solutions**

| Challenge                         | Solution                                       |
| --------------------------------- | ---------------------------------------------- |
| Signal instability at short range | Added timeout logic and cooldown delay         |
| UART sync errors                  | Implemented start/stop bit verification        |
| Limited sensor accuracy           | Calibrated COUNTS_PER_CM constant in Verilog   |
| Power noise on breadboard         | Used shielded wiring and decoupling capacitors |

---

🚗 **Applications**

* Vehicle collision avoidance systems
* Smart robotics and autonomous navigation
* IoT-based distance monitoring systems
* Industrial proximity sensing

---

📚 **References**

1. Xilinx Inc., *Vivado Design Suite User Guide*, 2025.
2. HC-SR04 Datasheet, SparkFun Electronics.

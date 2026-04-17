# SPI to Wishbone Bridge with Neuromorphic X1 Core

## 📌 Overview

This project implements a complete **SPI to Wishbone (WB) bridge system** integrated with a **Neuromorphic X1 behavioral core**. It enables external SPI masters to perform read and write operations to an internal WB-based system.

The design supports:

* **SPI WRITE transactions** (command `0x60`)
* **SPI READ transactions** (command `0x40`)
* **Same-frame read response** (low-latency readback)
* Integration with a **Wishbone master and slave architecture**
* A behavioral neuromorphic processing core with FIFO-based data handling

 <img width="972" height="275" alt="image" src="https://github.com/user-attachments/assets/87dfe8b3-a2e6-41e3-b32d-a4690e9ddac4" />


---

## 🏗️ Architecture

```
SPI Master
    │
    ▼
SPI Slave (spi_slave_fast_sameframe_read)
    │
    ▼
Controller (spi_to_wb_ctrl_sameframe_read)
    │
    ▼
Wishbone Master (wb_master_simple)
    │
    ▼
Wishbone Slave (Neuromorphic_X1_wb)
    │
    ▼
Neuromorphic Core (Neuromorphic_X1_beh)
```

---

## 📂 Module Description

### 🔹 1. `spi_wb_x1_top`

Top-level module integrating:

* SPI slave
* SPI-to-WB controller
* Wishbone master
* Neuromorphic WB slave

Handles all interconnections and signal routing.

---

### 🔹 2. `spi_slave_fast_sameframe_read`

SPI slave implementing:

* Command decoding (`0x60` = WRITE, `0x40` = READ)
* Early nibble detection at bit 3
* Immediate read request triggering
* 40-bit SPI frame handling:

  * 8-bit command
  * 32-bit data
* Same-frame read response using `MISO`

#### Features:

* Zero-wait read initiation
* Buffered TX shifting
* SPI Mode-0 compliant

---

### 🔹 3. `spi_to_wb_ctrl_sameframe_read`

Controller bridging SPI domain and WB domain:

* Synchronizes SPI pulses into WB clock domain
* Generates WB transactions:

  * Write after full frame reception
  * Read immediately on request
* Captures WB read data and returns to SPI

#### FSM States:

* `S_IDLE`
* `S_WR_START`
* `S_RD_START`
* `S_WAIT_BUSY`
* `S_WAIT_DONE`

---

### 🔹 4. `wb_master_simple`

Minimal Wishbone master:

* Initiates transactions using `start`
* Handles:

  * `cyc`, `stb`, `we`, `ack`
* Supports:

  * Single-cycle write/read initiation
  * Wait for acknowledgment

---

### 🔹 5. `Neuromorphic_X1_wb`

Wishbone wrapper for the neuromorphic core:

* Address-mapped interface (`0x3000_0004`)
* Converts WB signals to core interface
* Generates acknowledgment (`ack`)

---

### 🔹 6. `Neuromorphic_X1_beh`

Behavioral neuromorphic core:

* 32x32 memory array
* Input FIFO (`ip_fifo`)
* Output FIFO (`op_fifo`)

#### Operations:

* **Write Operation (****`DI[31:30] == 2'b11`****)**

  * Writes processed bit into memory

* **Read Operation (****`DI[31:30] == 2'b01`****)**

  * Reads memory and pushes result to output FIFO

#### Latencies:

* Write delay: `WR_Dly = 200 cycles`
* Read delay: `RD_Dly = 44 cycles`

---

## 🔄 SPI Protocol

### ✅ WRITE Transaction

```
| 8-bit CMD (0x60) | 32-bit DATA |
```

* Full frame required
* Data sent to WB after frame completion

---

### ✅ READ Transaction

```
| 8-bit CMD (0x40) | 32-bit DUMMY |
```

* Read request triggered early (after 4 bits)
* WB read starts immediately
* Data returned in same SPI frame

---

## 🧩 32-bit Data Frame Format (Neuromorphic Core)

The 32-bit payload sent over SPI is interpreted by the neuromorphic core as:

```
[31:30]  -> Mode
[29:25]  -> Row Address
[24:20]  -> Column Address
[19:8]   -> Reserved (0)
[7:0]    -> Data (LSB 8 bits)
```

### 🔹 Field Description

#### Mode `[31:30]`

* `11` → Write / Program operation
* `01` → Read operation

#### Row Address `[29:25]`

* Selects one of 32 rows

#### Column Address `[24:20]`

* Selects one of 32 columns

#### Data `[7:0]`

* Used only during WRITE
* Determines stored bit:

  * `> 0x7F` → Program **1**
  * `≤ 0x7F` → Program **0**

#### Reserved `[19:8]`

* Must be `0`

---

## ✍️ Write Operation Behavior

1. SPI sends:

   ```
   | CMD (0x60) | 32-bit formatted data |
   ```

2. Data reaches neuromorphic core via Wishbone

3. Core decodes:

   * Mode = `11`
   * Row & Column address
   * LSB 8-bit data

4. Programming logic:

   * If LSB > `0x7F` → store **1**
   * Else → store **0**

5. Bit is written into:

   ```
   array_mem[row][column]
   ```

---

## 📥 Read Operation Behavior

1. SPI sends:

   ```
   | CMD (0x40) | dummy data |
   ```

2. Read request is triggered early

3. Core accesses:

   ```
   array_mem[row][column]
   ```

4. Returned value:

   * If stored value = **1** → WB returns `1`
   * If stored value = **0** → WB returns `0`

5. Data flow:

   * Stored into `op_fifo`
   * Sent via Wishbone as `rdata`
   * Shifted out on SPI `MISO`

👉 **Key Insight:**

* WRITE → programs memory based on threshold
* READ → returns stored bit (0 or 1)

---

## 🧪 Testbench (`tb_spi_wb_x1_top`)

### Features:

* Generates:

  * 20 MHz WB clock
  * SPI clock (~5 MHz behavior)

* Performs:

  1. Two SPI WRITE transactions
  2. Delay for processing
  3. SPI READ transaction

* Observes:

  * Internal FIFOs
  * WB read data
  * SPI MISO response

---

## ▶️ Simulation Instructions (ModelSim)

```tcl
vlib work
vmap work work

vlog +acc +sv spi_wb_x1_top.v tb_spi_wb_x1_top.v

vsim work.tb_spi_wb_x1_top

add wave -position insertpoint sim:/tb_spi_wb_x1_top/dut/u_spi_slave/*
add wave -position insertpoint sim:/tb_spi_wb_x1_top/dut/u_ctrl/*
add wave -position insertpoint sim:/tb_spi_wb_x1_top/dut/u_wb_master/*

run -all
```

---

## 📊 Key Signals to Observe

### SPI Slave

* `cmd_shift`
* `rx_shift`
* `tx_shift`
* `bit_cnt`
* `cmd_type`
* `tx_loaded`

### Controller

* `state`
* `start`
* `we`
* `addr`
* `rd_data_valid_wb`

### WB Master

* `wb_cyc_o`, `wb_stb_o`
* `wb_ack_i`
* `rdata`

---

## ⚡ Key Design Highlights

* 🚀 Same-frame SPI read response
* 🔄 Clock domain crossing via synchronizers
* 🧠 FIFO-based neuromorphic processing
* ⚡ Low-latency read initiation
* 🧩 Modular and scalable architecture

---

## ⚠️ Limitations

* No burst transactions (single WB access only)
* No WB error handling

<h1 align="center"> APB Bus (Advanced Peripheral Bus) - Verilog RTL Design </h1>

<p align="center">
<img src="https://img.shields.io/badge/Protocol-AMBA%20APB-blue?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Design-RTL-orange?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Language-Verilog-green?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Stage-Bus%20Design-purple?style=for-the-badge"/>
</p>

<p align="center">
<img src="https://img.shields.io/badge/Status-Completed-success?style=flat-square"/>
<img src="https://img.shields.io/badge/Type-On--Chip%20Protocol-blue?style=flat-square"/>
<img src="https://img.shields.io/badge/Role-Interconnect-informational?style=flat-square"/>
</p>

---

<p align="center">
This project implements an <b>AMBA APB (Advanced Peripheral Bus)</b> interconnect in Verilog, enabling communication between an <b>AHB-APB bridge (master)</b> and multiple <b>peripheral slaves</b>.
</p>

---

# Overview

- Low-power, low-complexity on-chip bus  
- Non-pipelined protocol  
- Two-phase transfer: SETUP → ACCESS  
- Used for peripheral register access  

APB is designed for **simple register-level communication**, making it ideal for low-speed peripherals.

---

# APB Architecture

```mermaid
flowchart LR
    MASTER[AHB-APB Bridge] --> APB[APB BUS]

    APB --> RAM
    APB --> UART
    APB --> SPI
    APB --> I2C
    APB --> USB
```

The APB bus connects a single master (bridge) to multiple slaves using **address-based selection**.

---

# APB Transfer Phases

```mermaid
flowchart LR
    IDLE --> SETUP
    SETUP --> ACCESS
    ACCESS -->|PREADY=1| IDLE
    ACCESS -->|PREADY=0| ACCESS
```

- **SETUP Phase**: Address and control signals are driven  
- **ACCESS Phase**: Data transfer happens  
- **PREADY** allows insertion of wait states  

This simple state machine ensures predictable timing.

---

# Types of Transfers

## Write Transfer

<img width="490" height="247" alt="image" src="https://github.com/user-attachments/assets/d6a09fab-1830-4d92-8af1-31a3299c41ce" />


- PWRITE = 1  
- Master drives data on PWDATA  
- Slave captures data  

**Condition:**
- PSEL = 1 during SETUP phase  
- PENABLE = 1 during ACCESS phase  
- Transfer completes when PREADY = 1  

## Read Transfer

<img width="547" height="252" alt="image" src="https://github.com/user-attachments/assets/46c95f13-f787-4772-9aed-442fa3440396" />


- PWRITE = 0  
- Slave drives data on PRDATA  
- Master samples data  

**Condition:**
- PSEL = 1 and PENABLE = 1  
- PRDATA valid when PREADY = 1  
- Data must be stable at end of ACCESS phase  

## Write Transfer (No Wait State)

<img width="399" height="223" alt="image" src="https://github.com/user-attachments/assets/958b4d2d-05ff-43d1-99f5-ea7ca4e47eb1" />


- Data accepted immediately  
- Single ACCESS cycle  

**Condition:**
- PREADY = 1 in first ACCESS cycle  
- Transfer completes in 2 cycles (SETUP + ACCESS)  
- Signals remain stable throughout transfer :contentReference[oaicite:0]{index=0}  


## Read Transfer (No Wait State)

<img width="389" height="228" alt="image" src="https://github.com/user-attachments/assets/74bc9c97-b6b5-41af-a22e-6b3c5057c356" />


- Data returned without delay  
- No stall cycles  

**Condition:**
- PREADY = 1 during ACCESS phase  
- PRDATA valid before end of transfer  
- Completes in 2 cycles :contentReference[oaicite:1]{index=1}  


## Write Transfer (With Wait State)

<img width="541" height="222" alt="image" src="https://github.com/user-attachments/assets/0eca1162-ccc2-4aac-aa0d-72ef014a74ad" />


- Slave delays data acceptance  
- Multiple ACCESS cycles  

**Condition:**
- PREADY = 0 for one or more cycles  
- PADDR, PWRITE, PSEL, PWDATA remain stable  
- Transfer completes when PREADY = 1  

## Read Transfer (With Wait State)

<img width="548" height="218" alt="image" src="https://github.com/user-attachments/assets/194af210-791b-445e-8db2-c44924020860" />


- Slave delays data response  
- Data available after wait  

**Condition:**
- PREADY = 0 extends ACCESS phase  
- PRDATA valid only when PREADY = 1  
- Control signals remain unchanged
  
## Transfer with Wait States

- Slave inserts delay using PREADY = 0  
- Master holds all signals stable  

**Condition:**
- PENABLE = 1 while waiting  
- PADDR, PWRITE, PSEL, PWDATA remain unchanged  
- Transfer completes when PREADY transitions to 1 :contentReference[oaicite:2]{index=2}  


## Error Transfer

- PSLVERR = 1 indicates failure  
- Can occur in read or write  

**Condition:**
- Valid only when PSEL = 1, PENABLE = 1, PREADY = 1  
- Error reported in final cycle of transfer :contentReference[oaicite:3]{index=3}  

---

# Signal Description

| Signal | Direction | Description |
|--------|----------|-------------|
| PADDR  | Input  | Address bus |
| PWRITE | Input  | Write (1) / Read (0) |
| PSEL   | Input  | Slave select |
| PENABLE| Input  | Enables transfer phase |
| PWDATA | Input  | Write data |
| PRDATA | Output | Read data |
| PREADY | Output | Transfer complete |
| PSLVERR| Output | Error signal |

These signals form the **core APB handshake**, controlling address, data, and transfer completion.

---

# Address Mapping

| Address Range | Peripheral |
|--------------|-----------|
| 0x0000_0000  | RAM |
| 0x0000_1000  | UART |
| 0x0000_2000  | SPI |
| 0x0000_3000  | I2C |
| 0x0000_4000  | USB |

The address space is divided into **fixed regions**, each mapped to a specific peripheral.

---

# Decoder Logic

```verilog
assign psel_ram  = psel & (paddr[15:12] == 4'h0);
assign psel_uart = psel & (paddr[15:12] == 4'h1);
assign psel_spi  = psel & (paddr[15:12] == 4'h2);
assign psel_i2c  = psel & (paddr[15:12] == 4'h3);
assign psel_usb  = psel & (paddr[15:12] == 4'h4);
```

The decoder uses upper address bits to **select one slave at a time**, ensuring only one peripheral is active.

---

# Data Path (Mux Logic)

```verilog
always @(*) begin
    case (paddr[15:12])
        4'h0: begin prdata=prdata_ram; pready=pready_ram; pslverr=pslverr_ram; end
        4'h1: begin prdata=prdata_uart; pready=pready_uart; pslverr=pslverr_uart; end
        4'h2: begin prdata=prdata_spi; pready=pready_spi; pslverr=pslverr_spi; end
        4'h3: begin prdata=prdata_i2c; pready=pready_i2c; pslverr=pslverr_i2c; end
        4'h4: begin prdata=prdata_usb; pready=pready_usb; pslverr=pslverr_usb; end
        default: begin prdata=32'h0; pready=1'b1; pslverr=1'b1; end
    endcase
end
```

This logic **multiplexes outputs** from the selected slave back to the master.

---

# Data Flow

```mermaid
flowchart LR
    CPU --> AHB
    AHB --> BRIDGE
    BRIDGE --> APB
    APB --> UART
    UART --> DONE[Data Stored]
```

- CPU generates transaction  
- AHB handles high-speed transfer  
- Bridge converts protocol  
- APB delivers data to peripheral  

---

# Key Features

- Address-based slave selection  
- Simple two-phase protocol  
- Support for wait states and errors  
- Scalable architecture  

---

# Role in SoC

- Acts as **low-speed peripheral bus**  
- Reduces complexity compared to high-speed buses  
- Enables modular integration of peripherals  

---

<p align="center"><b>
This APB implementation provides a clean and scalable interconnect for integrating multiple peripherals into a SoC using AMBA standards.
</p>

---

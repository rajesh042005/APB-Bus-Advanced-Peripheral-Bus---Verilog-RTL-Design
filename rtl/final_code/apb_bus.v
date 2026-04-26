`timescale 1ns/1ps

module apb_bus (

    ////////////////////////////////////////////////////////////
    // FROM MASTER (Bridge)
    ////////////////////////////////////////////////////////////
    input  [31:0] paddr,
    input         pwrite,
    input         penable,
    input         psel,        // FIXED (comma added)
    input  [31:0] pwdata,
    input         pclk,
    input         presetn,

    ////////////////////////////////////////////////////////////
    // TO SLAVES
    ////////////////////////////////////////////////////////////
    output        psel_ram,
    output        psel_uart,
    output        psel_spi,
    output        psel_i2c,
    output        psel_usb,

    ////////////////////////////////////////////////////////////
    // FROM SLAVES
    ////////////////////////////////////////////////////////////
    input  [31:0] prdata_ram,
    input  [31:0] prdata_uart,
    input  [31:0] prdata_spi,
    input  [31:0] prdata_i2c,
    input  [31:0] prdata_usb,

    input         pready_ram,
    input         pready_uart,
    input         pready_spi,
    input         pready_i2c,
    input         pready_usb,

    input         pslverr_ram,
    input         pslverr_uart,
    input         pslverr_spi,
    input         pslverr_i2c,
    input         pslverr_usb,

    ////////////////////////////////////////////////////////////
    // BACK TO MASTER
    ////////////////////////////////////////////////////////////
    output reg [31:0] prdata,
    output reg        pready,
    output reg        pslverr
);

////////////////////////////////////////////////////////////
// ADDRESS MAP
////////////////////////////////////////////////////////////
// 0x0000_0000 → RAM
// 0x0000_1000 → UART
// 0x0000_2000 → SPI
// 0x0000_3000 → I2C
// 0x0000_4000 → USB

////////////////////////////////////////////////////////////
// DECODER
////////////////////////////////////////////////////////////
assign psel_ram  = psel & (paddr[15:12] == 4'h0);
assign psel_uart = psel & (paddr[15:12] == 4'h1);
assign psel_spi  = psel & (paddr[15:12] == 4'h2);
assign psel_i2c  = psel & (paddr[15:12] == 4'h3);
assign psel_usb  = psel & (paddr[15:12] == 4'h4);

////////////////////////////////////////////////////////////
// MUX + READY + ERROR
////////////////////////////////////////////////////////////
always @(*) begin

    case (paddr[15:12])

        4'h0: begin
            prdata  = prdata_ram;
            pready  = pready_ram;
            pslverr = pslverr_ram;
        end

        4'h1: begin
            prdata  = prdata_uart;
            pready  = pready_uart;
            pslverr = pslverr_uart;
        end

        4'h2: begin
            prdata  = prdata_spi;
            pready  = pready_spi;
            pslverr = pslverr_spi;
        end

        4'h3: begin
            prdata  = prdata_i2c;
            pready  = pready_i2c;
            pslverr = pslverr_i2c;
        end

        4'h4: begin
            prdata  = prdata_usb;
            pready  = pready_usb;
            pslverr = pslverr_usb;
        end

        //////////////////////////////////////////////////////
        // DEFAULT (INVALID ADDRESS)
        //////////////////////////////////////////////////////
        default: begin
            prdata  = 32'h0;
            pready  = 1'b1;
            pslverr = 1'b1;
        end

    endcase

end

endmodule

`timescale 1ns/1ps

module tb_apb_bus;

////////////////////////////////////////////////////////////
// DUT SIGNALS
////////////////////////////////////////////////////////////
reg  [31:0] paddr;
reg         pwrite;
reg         penable;
reg         psel;
reg  [31:0] pwdata;
reg         pclk;
reg         presetn;

wire        psel_ram;
wire        psel_uart;
wire        psel_spi;
wire        psel_i2c;
wire        psel_usb;

reg  [31:0] prdata_ram;
reg  [31:0] prdata_uart;
reg  [31:0] prdata_spi;
reg  [31:0] prdata_i2c;
reg  [31:0] prdata_usb;

reg         pready_ram;
reg         pready_uart;
reg         pready_spi;
reg         pready_i2c;
reg         pready_usb;

reg         pslverr_ram;
reg         pslverr_uart;
reg         pslverr_spi;
reg         pslverr_i2c;
reg         pslverr_usb;

wire [31:0] prdata;
wire        pready;
wire        pslverr;

////////////////////////////////////////////////////////////
// DUT
////////////////////////////////////////////////////////////
apb_bus dut (
    .paddr(paddr), .pwrite(pwrite), .penable(penable), .psel(psel),
    .pwdata(pwdata), .pclk(pclk), .presetn(presetn),

    .psel_ram(psel_ram), .psel_uart(psel_uart), .psel_spi(psel_spi),
    .psel_i2c(psel_i2c), .psel_usb(psel_usb),

    .prdata_ram(prdata_ram), .prdata_uart(prdata_uart),
    .prdata_spi(prdata_spi), .prdata_i2c(prdata_i2c), .prdata_usb(prdata_usb),

    .pready_ram(pready_ram), .pready_uart(pready_uart),
    .pready_spi(pready_spi), .pready_i2c(pready_i2c), .pready_usb(pready_usb),

    .pslverr_ram(pslverr_ram), .pslverr_uart(pslverr_uart),
    .pslverr_spi(pslverr_spi), .pslverr_i2c(pslverr_i2c), .pslverr_usb(pslverr_usb),

    .prdata(prdata), .pready(pready), .pslverr(pslverr)
);

////////////////////////////////////////////////////////////
// CLOCK
////////////////////////////////////////////////////////////
always #5 pclk = ~pclk;

////////////////////////////////////////////////////////////
// WAVEFORM DUMP
////////////////////////////////////////////////////////////
initial begin
    $dumpfile("apb_bus.vcd");
    $dumpvars(0, tb_apb_bus);
end

////////////////////////////////////////////////////////////
// INIT
////////////////////////////////////////////////////////////
initial begin
    pclk = 0;
    presetn = 0;
    psel = 0;
    penable = 0;
    pwrite = 0;
    paddr = 0;
    pwdata = 0;

    prdata_ram  = 32'hAAAA0000;
    prdata_uart = 32'hBBBB1111;
    prdata_spi  = 32'hCCCC2222;
    prdata_i2c  = 32'hDDDD3333;
    prdata_usb  = 32'hEEEE4444;

    pready_ram = 1;
    pready_uart = 1;
    pready_spi = 1;
    pready_i2c = 1;
    pready_usb = 1;

    pslverr_ram = 0;
    pslverr_uart = 0;
    pslverr_spi = 0;
    pslverr_i2c = 0;
    pslverr_usb = 0;

    #20 presetn = 1;

    // WRITE NO WAIT
    apb_write(32'h0000_1000, 32'hDEADBEEF);

    // READ NO WAIT
    apb_read(32'h0000_2000);

    // WRITE WITH WAIT
    pready_i2c = 0;
    fork begin #30 pready_i2c = 1; end join_none
    apb_write(32'h0000_3000, 32'h12345678);

    // READ WITH WAIT
    pready_usb = 0;
    fork begin #30 pready_usb = 1; end join_none
    apb_read(32'h0000_4000);

    // ERROR CASE
    apb_read(32'h0000_F000);

    #50 $finish;
end

////////////////////////////////////////////////////////////
// TASKS
////////////////////////////////////////////////////////////
task apb_write(input [31:0] addr, input [31:0] data);
begin
    @(posedge pclk);
    paddr <= addr; pwdata <= data; pwrite <= 1; psel <= 1; penable <= 0;

    @(posedge pclk);
    penable <= 1;

    wait(pready);

    @(posedge pclk);
    psel <= 0; penable <= 0;
end
endtask

task apb_read(input [31:0] addr);
begin
    @(posedge pclk);
    paddr <= addr; pwrite <= 0; psel <= 1; penable <= 0;

    @(posedge pclk);
    penable <= 1;

    wait(pready);

    @(posedge pclk);
    $display("READ DATA = %h", prdata);

    psel <= 0; penable <= 0;
end
endtask

endmodule

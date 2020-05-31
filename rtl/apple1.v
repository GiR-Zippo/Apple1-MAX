// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//
// Description: Apple1 hardware core
//
// Author.....: Alan Garfield
//              Niels A. Moseley
// Date.......: 26-1-2018
//

module apple1 #(
    parameter BASIC_FILENAME      = "../../../roms/a1basic.hex",
    parameter FONT_ROM_FILENAME   = "../../../roms/vga_font_bitreversed.hex",
    parameter VRAM_FILENAME       = "../../../roms/vga_vram.bin",
    parameter WOZMON_ROM_FILENAME = "../../../roms/wozmon.hex"
) (
	input  clk50,               // 50 MHz master clock
    input  clk25,               // 25 MHz clock
    input  rst_n,               // active low synchronous reset (needed for simulation)

    // I/O interface to computer
    input  uart_rx,             // asynchronous serial data input from computer
    output uart_tx,             // asynchronous serial data output to computer
    output uart_cts,            // clear to send flag to computer

    // I/O interface to keyboard
    input ps2_clk,              // PS/2 keyboard serial clock input
    input ps2_din,              // PS/2 keyboard serial data input

    // Outputs to VGA display
    output vga_h_sync,          // hozizontal VGA sync pulse
    output vga_v_sync,          // vertical VGA sync pulse
    output vga_red,             // red VGA signal
    output vga_grn,             // green VGA signal
    output vga_blu,             // blue VGA signal
    input  vga_cls,             // clear screen button

	//SDRAM
	output sdram_clk,           // SDRAM clock
	output sdram_clke,          // SDRAM clock enable
	output sdram_cs,            // SDRAM chip select
	output sdram_we,            // SDRAM write enable
	output sdram_ras,           // SDRAM row addr select
	output sdram_cas,           // SDRAM column addr select
	inout  [15:0] sdram_dq,     // SDRAM data
	output [11:0] sdram_addr,   // SDRAM addr
	output [1:0] sdram_bs,      // SDRAM bank
	output sdram_udqm,
	output sdram_ldqm,
	 
	//SEG_Display
	output [7:0] segment,
	output [3:0] digit,
	 
	//LEDs
	output [3:0] leds
);

    //////////////////////////////////////////////////////////////////////////
    // Registers and Wires

    wire [15:0] ab;
    wire [15:0] cpuab;
    wire [7:0] dbi;
    wire [7:0] dbo;
    wire cpuwe;
    wire we;

    //////////////////////////////////////////////////////////////////////////
    // Clocks

    wire cpu_clken;
    clock my_clock(
        .clk25(clk25),
        .rst_n(rst_n),
        .cpu_clken(cpu_clken),
        .sid_clken(sid_clken)
    );

    //////////////////////////////////////////////////////////////////////////
    // Reset

    wire rst;
    pwr_reset my_reset(
        .clk25(clk25),
        .rst_n(rst_n),
        .enable(cpu_clken),
        .rst(rst)
    );

	 //////////////////////////////////////////////////////////////////////////
	 // Seg_Display
	 SEG_Display addr_display(
			.clk   (clk50),
			.rst_n (rst_n),
			.data  (ab),
			.seg   (segment),  
			.cs	   (digit)
	 );

    //////////////////////////////////////////////////////////////////////////
    // 6502
    arlet_6502 my_cpu(
			.clk    (clk25),
			.enable (cpu_clken),
			.rst    (rst),
			.ab     (cpuab),
			.dbi    (dbi),
			.dbo    (dbo),
			.we     (cpuwe),
			.irq_n  (1'b1),
			.nmi_n  (1'b1),
			.ready  (cpu_clken)
    );
 
    //////////////////////////////////////////////////////////////////////////
    // MMU
    apple1_buslogic apple1_buslogic(
        .LED            (leds),
        .clk            (clk25),
        .reset          (rst_n),
        .cpuHasBus      (1'b1),
		.cpuWe          (cpuwe),
		.cpuAddr        (cpuab),
		.cpuDataIn      (dbi),
        .cpuDataOut     (dbo),
        .systemAddr     (ab),
        .systemWe       (we),
        
        .cs_ram         (ram_cs),
        .ram_data       (ram_dout),

        .cs_ehbasicrom  (ehbasic_cs),
        .ehbasicrom_data(ehbasic_dout),

        .cs_ps2kb       (ps2kb_cs),
        .ps2kb_data     (ps2_dout),

        .cs_vga         (vga_cs),
        //.vga_data

        .cs_uart        (uart_cs),
        .uart_data      (uart_dout),

        .cs_vga_mode    (vga_mode_cs),
        .vga_mode_data  (vga_mode_dout),

        .cs_a1asmrom    (a1asm_cs),
        .a1asmrom_data  (a1asm_dout),

        .cs_basicrom    (basic_cs),
        .basicrom_data  (basic_dout),

        .cs_biosrom     (ehbasicbios_cs),
        .biosrom_data   (ehbasicbios_dout)
    );
 
    //////////////////////////////////////////////////////////////////////////
    // RAM and ROM

	 wire [7:0] ram_dout;
	 SDRAM_ctrl ram_ctrl(
			.clk		(clk50),
			.SDRAM_CLK	(sdram_clk),
			.SDRAM_CKE 	(sdram_clke),
			.SDRAM_WEn  (sdram_we),
			.SDRAM_CASn	(sdram_cas),
			.SDRAM_RASn	(sdram_ras),
			.SDRAM_A	(sdram_addr),
			.SDRAM_DQ	(sdram_dq),
			.SDRAM_BA	(sdram_bs),
			
			// read agent
			.RdReq		(~we & ram_cs),
			.RdAddr		(ab[15:0]),
			.RdData		(ram_dout),

			// write agent
			.WrReq		(we & ram_cs),
			.WrAddr		(ab[15:0]),
			.WrData		(dbo)
	 );

    // WozMon ROM
    /*wire [7:0] rom_dout;
    rom_wozmon #(
        .WOZMON_ROM_FILENAME (WOZMON_ROM_FILENAME)
    ) my_rom_wozmon(
        .clk(clk25),
        .address(ab[7:0]),
        .dout(rom_dout)
    );*/

    // a1asm ROM
    wire [7:0] a1asm_dout;
    rom_a1asm #(
        .A1ASM_FILENAME ("../../../roms/a1ae.hex")
    ) my_rom_a1asm(
        .clk(clk25),
        .address(ab[11:0]),
        .dout(a1asm_dout),
        .cs (a1asm_cs)
    );
 
	 // EHBasicBios ROM and WOZ MON
    wire [7:0] ehbasicbios_dout;
    rom_ehbasicbios #(
        .EHBASICBIOS_FILENAME ("../../../roms/bios.hex")
    ) my_rom_ehbasicbios(
        .clk(clk25),
        .address(ab[13:0]),
        .dout(ehbasicbios_dout),
        .cs (ehbasicbios_cs)
    );
	 
    // Basic ROM
    wire [7:0] basic_dout;
    rom_basic #(
        .BASIC_FILENAME (BASIC_FILENAME)
    ) my_rom_basic(
        .clk(clk25),
        .address(ab[11:0]),
        .dout(basic_dout),
        .cs (basic_cs)
    );
 
	// EHBasic ROM
    wire [7:0] ehbasic_dout;
    rom_ehbasic #(
        .EHBASIC_FILENAME ("../../../roms/EHbasic.hex")
    ) my_rom_ehbasic(
        .clk(clk25),
        .address(ab[15:0]),
        .dout(ehbasic_dout),
        .cs (ehbasic_cs)
    );
    //////////////////////////////////////////////////////////////////////////
    // Peripherals

    // UART
    wire [7:0] uart_dout;
    uart #(
        `ifdef SIM
        100, 10, 2 // for simulation don't need real baud rates
        `else
        25000000, 115200, 8 // 25MHz, 115200 baud, 8 times RX oversampling
        `endif
    ) my_uart(
        .clk(clk25),
        .enable(uart_cs & cpu_clken),
        .rst(rst),

        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .uart_cts(uart_cts),

        .address(ab[1:0]),        // for uart
        .w_en(we & uart_cs),
        .din(dbo),
        .dout(uart_dout)
    );

    // PS/2 keyboard interface
    wire [7:0] ps2_dout;
    ps2keyboard keyboard(
        .clk25(clk25),
        .rst(rst),
        .key_clk(ps2_clk),
        .key_din(ps2_din),
        .cs(ps2kb_cs),
        .address(ab[0]),
        .dout(ps2_dout)
    );

    // VGA Display interface
    reg [2:0] fg_colour;
    reg [2:0] bg_colour;
    reg [1:0] font_mode;
    reg [7:0] vga_mode_dout;

    vga #(
        .VRAM_FILENAME (VRAM_FILENAME),
        .FONT_ROM_FILENAME (FONT_ROM_FILENAME)
    ) my_vga(
        .clk25(clk25),
        .enable(vga_cs),
        .rst(rst),

        .vga_h_sync(vga_h_sync),
        .vga_v_sync(vga_v_sync),
        .vga_red(vga_red),
        .vga_grn(vga_grn),
        .vga_blu(vga_blu),

        .address(ab[0]),
        .w_en(we & vga_cs),
        .din(dbo),
        .mode(font_mode),
        .fg_colour(fg_colour),
        .bg_colour(bg_colour),
        .clr_screen(vga_cls)
    );

    // Handle font mode and foreground and background
    // colours. This so isn't Apple One authentic, but
    // it can't hurt to have some fun. :D
    always @(posedge clk25 or posedge rst)
    begin
        if (rst)
        begin
            font_mode <= 2'b0;
            fg_colour <= 3'd7;
            bg_colour <= 3'd0;
        end
        else
        begin
            case (ab[1:0])
            2'b00:
            begin
                vga_mode_dout = {5'b0, bg_colour};
                if (vga_mode_cs & we & cpu_clken)
                    bg_colour <= dbo[2:0];
            end
            2'b01:
            begin
                vga_mode_dout = {5'b0, fg_colour};
                if (vga_mode_cs & we & cpu_clken)
                    fg_colour <= dbo[2:0];
            end
            2'b10:
            begin
                vga_mode_dout = {6'b0, font_mode};
                if (vga_mode_cs & we & cpu_clken)
                    font_mode <= dbo[1:0];
            end
            default:
                vga_mode_dout = 8'b0;
            endcase
        end
    end


endmodule

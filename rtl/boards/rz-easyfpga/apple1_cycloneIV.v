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
// Description: Apple 1 implementation for the iCE40HX8K dev
//              board.
//
// Author.....: Alan Garfield
// Date.......: 26-1-2018
//

module apple1_top #(
    parameter BASIC_FILENAME      = "../../../roms/a1basic.hex",
    parameter FONT_ROM_FILENAME   = "../../../roms/vga_font_bitreversed.hex",
    parameter VRAM_FILENAME       = "../../../roms/vga_vram.bin",
    parameter WOZMON_ROM_FILENAME = "../../../roms/wozmon.hex"
) (    
    input   CLK_50MHZ,      // the 50 MHz master clock

    // UART I/O signals
    output  UART_TXD,       // UART transmit pin on board
    input   UART_RXD,       // UART receive pin on board
    
	 //PS2 KBD
    input   PS2_KBCLK,
    input   PS2_KBDAT,

	 //Buttons
    input   BUTTON,         // Button for RESET
    input   SWITCH,         // Switch between PS/2 input and UART

	 //Display
    output  VGA_R,
    output  VGA_G,
    output  VGA_B,
    output  VGA_HS,
    output  VGA_VS,	 
	 
	 //SDRAM
	 output SDRAM_CLK,
	 output SDRAM_CLKE,
	 output SDRAM_CS,
	 output SDRAM_WE,
	 output SDRAM_RAS,
	 output SDRAM_CAS,
	 
	 //-SDRAM Address
	 output [11:0]SDRAM_ADDR,
	 //-SDRAM Data
	 inout  [15:0] SDRAM_DQ,
	 //-SDRAM BankSelect
	 output [1:0]SDRAM_BS,
	 
	 output SDRAM_UDQM,
	 output SDRAM_LDQM,
	 
	 // Segment Display
	 output [7:0] DISP_SEG,
	 output [3:0] DISP_DIG,
	 
	 //LEDS
	 output [3:0] LEDs
);

    //////////////////////////////////////////////////////////////////////////    
    // Registers and Wires
    reg clk25;

    wire rst_n;    
    assign rst_n = BUTTON;

	 
    // generate 25MHz clock from 50MHz master clock
    always @(posedge CLK_50MHZ)
    begin
        clk25 <= ~clk25;
    end    
    
    //////////////////////////////////////////////////////////////////////////    
    // Core of system
    apple1 #(
        .BASIC_FILENAME (BASIC_FILENAME),
        .FONT_ROM_FILENAME (FONT_ROM_FILENAME),
        .VRAM_FILENAME (VRAM_FILENAME),
        .WOZMON_ROM_FILENAME (WOZMON_ROM_FILENAME)
    ) apple1_top(
	    .clk50(CLK_50MHZ),
        .clk25(clk25),
        .rst_n(rst_n),
        .uart_rx(UART_RXD),
        .uart_tx(UART_TXD),
        .ps2_clk(PS2_KBCLK),
        .ps2_din(PS2_KBDAT),
        .vga_h_sync(VGA_HS),
        .vga_v_sync(VGA_VS),
        .vga_red(VGA_R),
        .vga_grn(VGA_G),
        .vga_blu(VGA_B),
        .vga_cls(~rst_n),
		  
		.sdram_clk(SDRAM_CLK),
		.sdram_clke(SDRAM_CLKE),
		.sdram_cs(SDRAM_CS),
		.sdram_we(SDRAM_WE),
		.sdram_ras(SDRAM_RAS),
		.sdram_cas(SDRAM_CAS),
		.sdram_addr(SDRAM_ADDR),
		.sdram_dq(SDRAM_DQ),
		.sdram_bs(SDRAM_BS),
		.sdram_udqm(SDRAM_UDQM),
		.sdram_ldqm(SDRAM_LDQM),
			
		.segment (DISP_SEG),
		.digit	(DISP_DIG),
           
        .leds    (LEDs)
    );
    
endmodule

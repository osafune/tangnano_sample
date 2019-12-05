// ===================================================================
// TITLE : Tang-NANO top module
//
//     DESIGN : s.osafune@j7system.jp (J-7SYSTEM WORKS LIMITED)
//     DATE   : 2019/11/21
// ===================================================================
//
// The MIT License (MIT)
// Copyright (c) 2019 J-7SYSTEM WORKS LIMITED.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

`default_nettype none

module tangnano_top (
	input wire			XTAL_IN,
	input wire	[1:0]	KEY_n,

//	output wire			FPGA_TXD,
//	input wire			FPGA_RXD,

	output wire			LED_R_n,
	output wire			LED_G_n,
	output wire			LED_B_n,

	output wire			PSRAM_CE_n,
	output wire			PSRAM_SCK,
	inout wire	[3:0]	PSRAM_SIO,

	output wire			LCD_DCLK,
	output wire			LCD_HSYNC_n,
	output wire			LCD_VSYNC_n,
	output wire			LCD_DE,
	output wire	[4:0]	LCD_R,
	output wire	[5:0]	LCD_G,
	output wire	[4:0]	LCD_B,

	output wire			PIO
);


/* ===== Internal nodes ====================== */

	wire		clock_sig = XTAL_IN;
	wire		reset_sig = ~KEY_n[0];
	wire		vclock_sig, pll_locked_sig;

	wire		led_r_sig, led_g_sig, led_b_sig;
	wire		hsync_sig, vsync_sig, de_sig;
	wire [7:0]	cb_r_sig, cb_g_sig, cb_b_sig;



/* ===== Module description ============== */

	assign PSRAM_CE_n = 1'b1;
	assign PSRAM_SCK = 1'b0;
	assign PSRAM_SIO = 4'bzzzz;


	pll_vclk			// 480x272 @9.0MHz
//	pll_vclk_wvga		// 800x480 @30.0MHz
	u_pll (
		.clkin		(clock_sig),		// input 24.0MHz
		.clkout		(vclock_sig),		// video clock
		.lock		()
	);


	rgb_lampy
	u0 (
		.reset		(reset_sig),
		.clock		(clock_sig),

		.pwm_red	(led_r_sig),
		.pwm_green	(led_g_sig),
		.pwm_blue	(led_b_sig)
	);

	assign {LED_R_n, LED_G_n, LED_B_n} = ~{led_r_sig, led_g_sig, led_b_sig};


	melodychime #(
		.CLOCK_FREQ_HZ	(24000000)
	)
	u1 (
		.reset		(reset_sig),
		.clk		(clock_sig),

		.start		(~KEY_n[1]),
		.timing_1ms	(),
		.tempo_led	(),
		.aud_out	(PIO)
	);


	vga_syncgen #(
		.H_TOTAL	(525),		// ATM0430D5(480x272,60Hz) / 9.0MHz
		.H_SYNC		(40),
		.H_BACKP	(3),
		.H_ACTIVE	(480),
		.V_TOTAL	(286),
		.V_SYNC		(3),
		.V_BACKP	(2),
		.V_ACTIVE	(272)

//		.H_TOTAL	(953),		// SH050JGB30-05004Y(800x480,60Hz) / 30.0MHz
//		.H_SYNC		(40),
//		.H_BACKP	(6),
//		.H_ACTIVE	(800),
//		.V_TOTAL	(525),
//		.V_SYNC		(3),
//		.V_BACKP	(20),
//		.V_ACTIVE	(480)
	)
	u2 (
		.reset		(reset_sig),
		.video_clk	(vclock_sig),

		.scan_ena	(1'b0),
		.framestart	(),
		.linestart	(),
		.pixelena	(),

		.hsync		(hsync_sig),
		.vsync		(vsync_sig),
		.hblank		(),
		.vblank		(),
		.dotenable	(de_sig),
		.cb_rout	(cb_r_sig),
		.cb_gout	(cb_g_sig),
		.cb_bout	(cb_b_sig)
	);

	assign LCD_DCLK = vclock_sig;
	assign LCD_HSYNC_n = ~hsync_sig;
	assign LCD_VSYNC_n = ~vsync_sig;
	assign LCD_DE = de_sig;
	assign LCD_R = cb_r_sig[7:3];
	assign LCD_G = cb_g_sig[7:2];
	assign LCD_B = cb_b_sig[7:3];


endmodule

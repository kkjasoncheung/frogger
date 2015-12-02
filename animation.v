// Animation

module animation
	(
		CLOCK_50,						//	On Board 50 MHz
		SW,								//  Switches[17:0]
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK,						//	VGA BLANK
		VGA_SYNC,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		//************** PS2 IMPLEMENTATION **************//
		KEY,							//	Push Button[3:0]
		HEX0, HEX1, HEX2, HEX3, 		//  HEX displays
		HEX4, HEX5, HEX6, HEX7,
		LEDG, LEDR,						//  LED lights
		PS2_DAT,
		PS2_CLK,
		GPIO_0,
		GPIO_1
	);

	input			CLOCK_50;				//	50 MHz
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK;				//	VGA BLANK
	output			VGA_SYNC;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	//************** PS2 IMPLEMENTATION **************//
	input   [3:0]   KEY;  					//  Push Buttons[3:0]
	input   [0:0]   SW; 					//  DPDT Switch [0]
	output  [6:0]   HEX0, HEX1, HEX2, HEX3; //  7-SEG Displays
	output  [6:0]   HEX4, HEX5, HEX6, HEX7;
	output  [8:0]   LEDG; 				//  LED Green[8:0]
	output  [17:0]  LEDR;  					//  LED Red[17:0]
				
	input	PS2_DAT;						//  PS2 data and clock lines
	input	PS2_CLK;
		
	inout  [35:0]  GPIO_0, GPIO_1;			//  GPIO Connections
	
	wire resetn;
	assign resetn = SW[0];
	
	// Create the color, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] color;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	wire collision; // Detects collision b/t player and cars
	wire [3:0] score;
	wire [1:0] lives;
	
	//************** PS2 IMPLEMENTATION **************//
	
	//  set all inout ports to tri-state
assign  GPIO_0    =  36'hzzzzzzzzz;
assign  GPIO_1    =  36'hzzzzzzzzz;

wire RST;
assign RST = KEY[0];


// Connect dip switches to red LEDs
//assign LEDR[17:0] = SW[17:0];

// turn off green LEDs
//assign LEDG = 0;

wire reset = 1'b0;
wire [7:0] scan_code;

reg [7:0] history[1:4];
wire read, scan_ready;

oneshot pulser(
   .pulse_out(read),
   .trigger_in(scan_ready),
   .clk(CLOCK_50)
);

keyboard kbd(
  .keyboard_clk(PS2_CLK),
  .keyboard_data(PS2_DAT),
  .clock50(CLOCK_50),
  .reset(reset),
  .read(read),
  .scan_ready(scan_ready),
  .scan_code(scan_code)
);

//hex_7seg dsp0(history[1][3:0],HEX0);	// Show PS2 HEX code
//hex_7seg dsp1(history[1][7:4],HEX1);
//
//hex_7seg dsp2(history[2][3:0],HEX2);
//hex_7seg dsp3(history[2][7:4],HEX3);
//
//hex_7seg dsp4(history[3][3:0],HEX4);
//hex_7seg dsp5(history[3][7:4],HEX5);
//
//hex_7seg dsp6(history[4][3:0],HEX6);
//hex_7seg dsp7(history[4][7:4],HEX7);

	reg posx,posy;
	reg negx,negy;
	reg backspace;	// Will act as reset
	
// Smooth move w/ numlock off & step move w/o numlock on
always @ (posedge CLOCK_50)	// (posedge scan_ready)
begin
	if (scan_code == 8'h74)
		begin
			posy <= 1;
			posx <= 0;
			negy <= 1;
			negx <= 1;
			backspace <= 1;
		end
	else if (scan_code == 8'h75)
		begin
			posy <= 0;
			posx <= 1;
			negy <= 1;
			negx <= 1;
			backspace <= 1;
		end
	else if (scan_code == 8'h6b)
		begin
			posy <= 1;
			posx <= 1; 
			negy <= 1;
			negx <= 0;
			backspace <= 1;
		end
	else if (scan_code == 8'h72)
		begin
			posy <= 1;
			posx <= 1;
			negy <= 0;
			negx <= 1;
			backspace <= 1;
		end
	else if (scan_code == 8'h66)
		begin
			posy <= 1;
			posx <= 1;
			negy <= 1;
			negx <= 1;
			backspace <= 0;
		end
	else
		begin
			posy <= 1;
			posx <= 1;
			negy <= 1;
			negx <= 1;
			backspace <= 1;
		end
	history[4] <= history[3];
	history[3] <= history[2];
	history[2] <= history[1];
	history[1] <= scan_code;
end

//assign LEDG[0] = posx;	// Check direction input
//assign LEDG[1] = posy;
//assign LEDG[2] = negy;
//assign LEDG[3] = negx;
//assign LEDG[4] = backspace;


	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(color),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK),
			.VGA_SYNC(VGA_SYNC),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.COLOUR_CHANNEL_DEPTH = 1;
		defparam VGA.BACKGROUND_IMAGE = "image.colour.mif";//"tomsbkg.mif";
			
	// Put your code here. Your code should produce signals x,y,color and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
		
	test_plotting FSM(.CLOCK_50(CLOCK_50), .resetN(resetn), .collision(collision), .x(x), .y(y), .color(color), .write_En(writeEn),.negx(negx),.negy(negy),.posx(posx),.posy(posy),.backspace(backspace),.score(score),.test(LEDR[1]), .lives_lost(lives));
	
//	Bin2Hex_7seg score_count(score,HEX0);
//	Bin2Hex_7seg life_count(lives,HEX1);
//	
//	assign LEDR[0] = collision;
//	
endmodule

module Bin2Hex_7seg(x,HEX);
	input [3:0]x;
	output [6:0]HEX;
	
	assign HEX[0] = ~x[3]&x[2]&~x[1]&~x[0] | ~x[3]&~x[2]&~x[1]&x[0] | x[3]&x[2]&~x[1]&x[0] | x[3]&~x[2]&x[1]&x[0];
	assign HEX[1] = ~x[3]&x[2]&~x[1]&x[0] | x[3]&x[2]&~x[0] | x[2]&x[1]&~x[0] | x[3]&x[1]&x[0];
	assign HEX[2] = ~x[3]&~x[2]&x[1]&~x[0] | x[3]&x[2]&~x[1]&~x[0] | x[3]&x[2]&x[1];
	assign HEX[3] = ~x[3]&~x[2]&~x[1]&x[0] | ~x[3]&x[2]&~x[1]&~x[0] | x[2]&x[1]&x[0] | x[3]&~x[2]&x[1]&~x[0];
	assign HEX[4] = ~x[3]&x[0] | ~x[3]&x[2]&~x[1] | x[3]&~x[2]&~x[1]&x[0];
	assign HEX[5] = ~x[3]&~x[2]&x[1] | ~x[3]&~x[2]&x[0] | ~x[3]&x[1]&x[0] | x[3]&x[2]&~x[1]&x[0];
	assign HEX[6] = ~x[3]&~x[2]&~x[1] | ~x[3]&x[2]&x[1]&x[0] | x[3]&x[2]&~x[1]&~x[0];

endmodule
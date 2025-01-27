`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 山东大学
// Engineer: 周健平
// 
// Create Date: 2020/07/29 23:59:07
// Design Name: 
// Module Name: vga1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: vga图像浮动显示，实现条纹方块屏幕保护
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vga1(
    input clk,  //时钟信号
    input rst_n,    //复位信号
    output reg [2:0] r,//rgb三颜色输出
    output reg [2:0] g,
    output reg [1:0] b,
    output hs,      //行信号输出
    output vs       //列信号输出
    );
    wire reset=~rst_n;  //复位信号取反，保证上升沿触发
    //设定方块区域的边界
    parameter UP_BOUND = 31;    //设定上边界
	parameter DOWN_BOUND = 510;    //设定下边界
	parameter LEFT_BOUND = 144;    //设定左边界
	parameter RIGHT_BOUND = 783;   //设定右边界
	//定义状态机的四种状态
	parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;
	reg [2:0] state, nextstate;    //定义状态机的状态和下一次的状态
	reg [2:0] nextr, nextg;        //定义状态机下一次输出的颜色rgb
	reg [1:0] nextb;
	
	reg h_speed, v_speed;
	reg [9:0] up_pos, down_pos, left_pos, right_pos;//定义方块的上下左右边界定位
    //行信号和列信号决定着当前像素是否显示出来，VGA显示是逐行扫描像素点
    //由于除了可见区域还有不可见区域的像素点，因此通过边界来控制是否输出
	wire myclk;
	reg [1:0] count;
	reg [9:0] hcount, vcount;

	always@(posedge clk)//时钟上升沿
	begin
		if(reset)//复位
			count <= 0;
		else
			count <= count + 1'b1;
	end
	assign myclk = count[1];//实现时钟分频，每16个clk周期实现一次myclk翻转，100MHZ/32
	
	always@(posedge myclk or posedge reset)//注意这里是reset上升沿触发，对应前面需要对rst_n取反
	begin
		if(reset)
			hcount <= 0;
		else if(hcount == 799)
			hcount <= 0;
		else
			hcount <= hcount + 1'b1;
	end
	assign hs = (hcount < 96) ? 1'b0 : 1'b1;//输出行同步信号
	assign vs = (vcount < 2) ? 1'b0 : 1'b1;//输出场同步信号
	//颜色持续变换形成彩色轮变。彩色变化通过状态机来实现。
	//每一列像素点对应一个颜色，只有方块区域内才通过彩色显示，其余区域为黑色
	always@(posedge myclk or posedge reset)
	begin
		if(reset)
			vcount <= 0;
		else if(hcount == 799) 
            begin
                if(vcount == 520)
                    vcount <= 0;
                else
                    vcount <= vcount + 1'b1;
            end
		else
			vcount <= vcount;
	end
	
	always@(posedge myclk or posedge reset)
	begin
		if(reset) 
            begin
                r <= 0;
                g <= 0;
                b <= 0;
            end
		else 
            begin
                if((vcount >= up_pos) && (vcount <= down_pos)
                     && (hcount >= left_pos)&& (hcount<=right_pos)) 
                    begin
                        r <= nextr; 
                        g <= nextg; 
                        b <= nextb;
                    end
                else 
                    begin
                        r <= 3'b000;
                        g <= 3'b000;
                        b <= 2'b00;
                    end
            end
	end
	
	always@(posedge myclk or posedge reset)
	begin
		if(reset)
			state <= S0;
		else
			state <= nextstate;
	end
	
	always@(*)
	begin
		case(state)
			S0:		nextstate <= S1;
			S1:		nextstate <= S2;
			S2:		nextstate <= S3;
			S3:		nextstate <= S0;
			default:	nextstate <= S0;
		endcase
	end
	
	always@(*)
	begin
		case(state)
			S0:begin nextr <= 3'b111; nextg <= 3'b000; nextb <= 2'b00; end
			S1:begin nextr <= 3'b000; nextg <= 3'b111; nextb <= 2'b00; end
			S2:begin nextr <= 3'b000; nextg <= 3'b000; nextb <= 2'b11; end
			S3:begin nextr <= 3'b111; nextg <= 3'b111; nextb <= 2'b00; end
			default:begin nextr <= 3'b111; nextg <= 3'b000; nextb <= 2'b11; end
		endcase
	end
	
	always@(negedge vs or posedge reset)
	begin
		if(reset)
            begin
                h_speed <= 1;
                v_speed <= 0;
            end
		else 
            begin
                if(up_pos == UP_BOUND)
                    v_speed <= 1;
                else if(down_pos == DOWN_BOUND)
                    v_speed <= 0;
                else
                    v_speed <= v_speed;
                
                if (left_pos == LEFT_BOUND)
                    h_speed <= 1;
                else if (right_pos == RIGHT_BOUND)
                    h_speed <= 0;
                else
                    h_speed <= h_speed;
            end
	end
	
	always@(posedge vs or posedge reset)
	begin
		if(reset) 
            begin
                up_pos <= 391;
                down_pos <= 510;
                left_pos <= 384;
                right_pos <= 543;
            end
		else
            begin
                if(v_speed) 
                    begin
                        up_pos <= up_pos + 1'b1;
                        down_pos <= down_pos + 1'b1;
                    end
                else 
                    begin
                        up_pos <= up_pos - 1'b1;
                        down_pos <= down_pos - 1'b1;
                    end     
                if(h_speed)
                    begin
                        left_pos <= left_pos + 1'b1;
                        right_pos <= right_pos + 1'b1;
                    end
                else 
                    begin
                        left_pos <= left_pos - 1'b1;
                        right_pos <= right_pos - 1'b1;
                    end
            end
	end
endmodule

`timescale 1ns / 1ps
/*I2C功能模块
考虑了物理时序
*/
module iic_func_module(
input CLK,//选用20MHz
input RSTn,
input[1:0]Start_Sig,//表示它有两个"内部功能"
input[7:0]Addr_Sig,//指WordAddress（字地址）而不是设备地址，设备地址已经嵌入在里边了。
input[7:0]WrData,

output[7:0]RdData,
output Done_Sig,
output SCL,
inout SDA,
output [4:0]SQ_i
    );
//---------------------------------------------
parameter FREQ=9'd200;//普通模式 100kb/s   （1/100k）/（1/20M）=200

reg[4:0]i;
reg[4:0]Go;//伪函数的返回用
reg[8:0]C1;//计数时钟
reg[7:0]rData;//数据暂存和驱动
reg rSCL;//驱动SCL
reg rSDA;//驱动SDA
reg isAck;//暂存应答结果
reg isDone;//反馈完成信号
reg isOut;//isOut用来决定SDA是输出还是输入


always@(posedge CLK or negedge RSTn)
if(!RSTn)
begin
i<=5'd0;
Go<=5'd0;
C1<=9'd0;
rData<=8'd0;
rSCL<=1'b1;//SCL和SDA信号在"空闲时"处于高电平
rSDA<=1'b1;
isAck<=1'b1;
isDone<=1'b0;
isOut=1'b1;//isOut初值为逻辑1，则表示SDA在初始状态是输出
end
else if(Start_Sig[0])//写字节操作
case(i)
0://start
begin
isOut=1'b1;//为了让在此刻立刻变为1，使用阻塞赋值

rSCL<=1'b1;

if(C1==0)rSDA<=1'b1;
else if(C1==100)rSDA<=1'b0;

if(C1==FREQ-1)
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

1://WriteDeviceAddr
begin
rData<={4'b1010,3'b000,1'b0};i<=5'd7;Go<=i+1'b1;//{4'b1010（产品系列），3'b000（总线地址），1'b0（写方向）}
end

2://WirteWordAddr
begin
rData<=Addr_Sig;i<=5'd7;Go<=i+1'b1;
end

3://WriteData
begin
rData<=WrData;i<=5'd7;Go<=i+1'b1;
end

4://Stop
begin
isOut=1'b1;

if(C1==0)rSCL<=1'b0;
else if(C1==50)rSCL<=1'b1;

if(C1==0)rSDA<=1'b0;
else if(C1==150)rSDA<=1'b1;

if(C1==50+FREQ-1)
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

5:
begin
isDone<=1'b1;i<=i+1'b1;
end

6:
begin
isDone<=1'b0;i<=5'd0;
end
//初始准备阶段------------------------------------------------
7,8,9,10,11,12,13,14:
begin
isOut=1'b1;

rSDA<=rData[14-i];//由高到低，注意与Uart区别

if(C1==0)rSCL<=1'b0;
else if(C1==100)rSCL<=1'b1;


if(C1==FREQ-1)
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

15://应答位
begin
isOut=1'b0;
if(C1==150)isAck<=SDA;//100其实已经可以，150是为了保险考虑

if(C1==0)rSCL<=1'b0;
else if(C1==100)rSCL<=1'b1;

if(C1==FREQ-1)
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

16://如果应答位的结果不为0的话（从机不应答）就重新操作
if(isAck!=0)i<=5'd0;
else i<=Go;

endcase
//一次性写操作阶段------------------------------------------------
else if(Start_Sig[1])//读操作

case(i)
0://start
begin
isOut=1'b1;//为了让在此刻立刻变为1，使用阻塞赋值

rSCL<=1'b1;

if(C1==0)rSDA<=1'b1;
else if(C1==100)rSDA<=1'b0;

if(C1==FREQ-1)//最后50个时钟是"保险作用"没有什么特别
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

1://WriteDeviceAddr
begin
rData<={4'b1010,3'b000,1'b0};i<=5'd9;Go<=i+1'b1;//{4'b1010（产品系列），3'b000（总线地址），1'b0（写方向）}
end

2://WirteWordAddr
begin
rData<=Addr_Sig;i<=5'd9;Go<=i+1'b1;
end



3://Start again
begin
isOut=1'b1;//为了让在此刻立刻变为1，使用阻塞赋值

if( C1 == 0 ) rSCL <= 1'b0;
else if( C1 == 50 ) rSCL <= 1'b1;
else if( C1 == 250 ) rSCL <= 1'b0;

if( C1 == 0 ) rSDA <= 1'b0;
else if( C1 == 50 ) rSDA <= 1'b1;
else if( C1 == 150 ) rSDA <= 1'b0;

if( C1 == 300 -1 ) 
begin C1 <= 9'd0; i <= i + 1'b1; 
end
else C1 <= C1 + 1'b1;

end

4://WriteDeviceAddr(Read)
begin
rData<={4'b1010,3'b000,1'b1};i<=5'd9;Go<=i+1'b1;
end

5://ReadData
begin
rData<=8'd0;i<=5'd19;Go<=i+1'b1;//寄存器清零
end

6://Stop
begin
isOut=1'b1;

if(C1==0)rSCL<=1'b0;
else if(C1==50)rSCL<=1'b1;

if(C1==0)rSDA<=1'b0;
else if(C1==150)rSDA<=1'b1;

if(C1==50+FREQ-1)
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

7:
begin
isDone<=1'b1;i<=i+1'b1;
end

8:
begin
isDone<=1'b0;i<=5'd0;
end
//初始准备阶段------------------------------------------------
9,10,11,12,13,14,15,16:
begin
isOut=1'b1;

rSDA<=rData[16-i];//由高到低，注意与Uart区别

if(C1==0)rSCL<=1'b0;
else if(C1==100)rSCL<=1'b1;

if(C1==FREQ-1)
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

17://应答位
begin
isOut=1'b0;
if(C1==100)isAck<=SDA;

if(C1==0)rSCL<=1'b0;
else if(C1==1000)rSCL<=1'b1;

if(C1==FREQ-1)
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

18://如果应答位的结果不为0的话（从机不应答）就重新操作
if(isAck!=0)i<=5'd0;
else i<=Go;

19,20,21,22,23,24,25,26://Read
begin
isOut=1'b0;

rData[26-i]<=SDA;//由高到低，注意与Uart区别

if(C1==0)rSCL<=1'b0;
else if(C1==100)rSCL<=1'b1;

if(C1==FREQ-1)
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

27://应答位
begin
isOut=1'b0;
//if(C1==100)isAck<=SDA;

if(C1==0)rSCL<=1'b0;
else if(C1==100)rSCL<=1'b1;

if(C1==FREQ-1)
begin
C1<=9'd0;i<=Go;
end
else C1<=C1+1'b1;

end

endcase

//一次性读操作阶段------------------------------------------------
assign Done_Sig=isDone;
assign RdData=rData;
assign SCL=rSCL;
assign SDA=isOut?rSDA:1'bz;
assign SQ_i=i;

endmodule

`timescale 1ns / 1ps
/*I2C����ģ��
����������ʱ��
*/
module iic_func_module(
input CLK,//ѡ��20MHz
input RSTn,
input[1:0]Start_Sig,//��ʾ��������"�ڲ�����"
input[7:0]Addr_Sig,//ָWordAddress���ֵ�ַ���������豸��ַ���豸��ַ�Ѿ�Ƕ��������ˡ�
input[7:0]WrData,

output[7:0]RdData,
output Done_Sig,
output SCL,
inout SDA,
output [4:0]SQ_i
    );
//---------------------------------------------
parameter FREQ=9'd200;//��ͨģʽ 100kb/s   ��1/100k��/��1/20M��=200

reg[4:0]i;
reg[4:0]Go;//α�����ķ�����
reg[8:0]C1;//����ʱ��
reg[7:0]rData;//�����ݴ������
reg rSCL;//����SCL
reg rSDA;//����SDA
reg isAck;//�ݴ�Ӧ����
reg isDone;//��������ź�
reg isOut;//isOut��������SDA�������������


always@(posedge CLK or negedge RSTn)
if(!RSTn)
begin
i<=5'd0;
Go<=5'd0;
C1<=9'd0;
rData<=8'd0;
rSCL<=1'b1;//SCL��SDA�ź���"����ʱ"���ڸߵ�ƽ
rSDA<=1'b1;
isAck<=1'b1;
isDone<=1'b0;
isOut=1'b1;//isOut��ֵΪ�߼�1�����ʾSDA�ڳ�ʼ״̬�����
end
else if(Start_Sig[0])//д�ֽڲ���
case(i)
0://start
begin
isOut=1'b1;//Ϊ�����ڴ˿����̱�Ϊ1��ʹ��������ֵ

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
rData<={4'b1010,3'b000,1'b0};i<=5'd7;Go<=i+1'b1;//{4'b1010����Ʒϵ�У���3'b000�����ߵ�ַ����1'b0��д����}
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
//��ʼ׼���׶�------------------------------------------------
7,8,9,10,11,12,13,14:
begin
isOut=1'b1;

rSDA<=rData[14-i];//�ɸߵ��ͣ�ע����Uart����

if(C1==0)rSCL<=1'b0;
else if(C1==100)rSCL<=1'b1;


if(C1==FREQ-1)
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

15://Ӧ��λ
begin
isOut=1'b0;
if(C1==150)isAck<=SDA;//100��ʵ�Ѿ����ԣ�150��Ϊ�˱��տ���

if(C1==0)rSCL<=1'b0;
else if(C1==100)rSCL<=1'b1;

if(C1==FREQ-1)
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

16://���Ӧ��λ�Ľ����Ϊ0�Ļ����ӻ���Ӧ�𣩾����²���
if(isAck!=0)i<=5'd0;
else i<=Go;

endcase
//һ����д�����׶�------------------------------------------------
else if(Start_Sig[1])//������

case(i)
0://start
begin
isOut=1'b1;//Ϊ�����ڴ˿����̱�Ϊ1��ʹ��������ֵ

rSCL<=1'b1;

if(C1==0)rSDA<=1'b1;
else if(C1==100)rSDA<=1'b0;

if(C1==FREQ-1)//���50��ʱ����"��������"û��ʲô�ر�
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

1://WriteDeviceAddr
begin
rData<={4'b1010,3'b000,1'b0};i<=5'd9;Go<=i+1'b1;//{4'b1010����Ʒϵ�У���3'b000�����ߵ�ַ����1'b0��д����}
end

2://WirteWordAddr
begin
rData<=Addr_Sig;i<=5'd9;Go<=i+1'b1;
end



3://Start again
begin
isOut=1'b1;//Ϊ�����ڴ˿����̱�Ϊ1��ʹ��������ֵ

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
rData<=8'd0;i<=5'd19;Go<=i+1'b1;//�Ĵ�������
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
//��ʼ׼���׶�------------------------------------------------
9,10,11,12,13,14,15,16:
begin
isOut=1'b1;

rSDA<=rData[16-i];//�ɸߵ��ͣ�ע����Uart����

if(C1==0)rSCL<=1'b0;
else if(C1==100)rSCL<=1'b1;

if(C1==FREQ-1)
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

17://Ӧ��λ
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

18://���Ӧ��λ�Ľ����Ϊ0�Ļ����ӻ���Ӧ�𣩾����²���
if(isAck!=0)i<=5'd0;
else i<=Go;

19,20,21,22,23,24,25,26://Read
begin
isOut=1'b0;

rData[26-i]<=SDA;//�ɸߵ��ͣ�ע����Uart����

if(C1==0)rSCL<=1'b0;
else if(C1==100)rSCL<=1'b1;

if(C1==FREQ-1)
begin
C1<=9'd0;i<=i+1'b1;
end
else C1<=C1+1'b1;

end

27://Ӧ��λ
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

//һ���Զ������׶�------------------------------------------------
assign Done_Sig=isDone;
assign RdData=rData;
assign SCL=rSCL;
assign SDA=isOut?rSDA:1'bz;
assign SQ_i=i;

endmodule

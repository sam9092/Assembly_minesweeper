;�ե�DOS�A�Ȩӵ�����L��J
GetChar macro Char
	mov ah,06h			;�q�зǿ�J�˸m�]�q�`�O��L�^Ū���@�Ӧr��
	mov dl,0ffh			;�N�Ӧr�Ū� ASCII �ȩ�J DL
	int 21h
	mov Char,al
endm

;�N0�s�x��ah���A��ܭn�ե�BIOS���_�\��00h�A�]�w��ܼҦ�
;�N"mode"�s�x��al���A��ܭn�]�m��������ܼҦ�
;�ե�int 10h���_�A�N�]�m����ܼҦ����Ω���ܾ��W
SetMode macro mode		;�]�w��ܼҦ�
	mov ah,00h
	mov al,mode
	int 10h
endm

;INT 10h�BAH=0Bh : �]�w����C��
SetColor macro mode,color	;�]�m��r�C��
	mov ah,0bh
	mov bh,mode			;���w�һݪ���ܭ���
	mov bl,color		;��ܩһݪ���r�C��
	int 10h
endm

;INT 10h�BAH = 0Ch : �]�w��ӹ������C��
WrPixel macro row,col,color
	mov ah,0ch
	mov bh,00h			;�������X (0-7)
	mov al,color		;�C��X (0-15)
	mov cx,row			;�C�� (0-199)
	mov dx,col			;�渹 (0-319)
	int 10h
endm

SET_CUR macro Row,Col  		;�N�̹��W���Ҧb��аO���ʨ���w����M�C��m
	mov dh,Row
	mov dl,Col
	mov bx,0000h
	mov ah,02h
	int 10h
endm

data segment

getc 		db 	0	;��J�r��
cheat 	db 	0	;�@���X���\����

difficulty 	db 	0	;�C������(1:²�� 2:���q 3:�x��)

;0:�S���Q���} ,1:�L�p�� ,2:���X�� ,10:�a�p��
BlockState 	db 	768 dup(0)	;�C�����(�̤j24*32)
;0��8:����a�p�� ,9:���u ,10: �ɥ~,99:�_�l�I 
mineState 	db 	768 dup(0)

mineCount	db	0	;�p��a�p��
mineNumber 	dw 	0	;�a�p�`��

bomCount 	db 	0
soundtimes 	dw 	0
firstBlock 	dw 	0
position 	db 	0,0,0  ;col row
BlockWide 	dw 	20
checkCount 	dw 	0
isStart 	db 	0
;�p��ch,��cl,��dh,�@��dl
timeCount 	dw 	0	;�ɶ��p��
timeCount1 	db 	0

scanCount 	dw 	0	;�p�ⱽ�y��

row 		dw 	0	;��
col 		dw 	0	;�C

RowCounter 	dw 	0	;��p��
ColCounter 	dw 	0	;�C�p��

;���(�C�j20)
XLimit	dw	640	;32��,col
YLimit	dw	480	;24��,row

score 	db 	0,0,0

winMessage1		db 	"|-------------------------------------------|$"
winMessage2		db 	"| __     __          __          ___        |$"
winMessage3		db 	"| \ \   / /          \ \        / (_)       |$"
winMessage4		db 	"|  \ \_/ /__  _   _   \ \  /\  / / _ _ __   |$"
winMessage5		db 	"|   \   / _ \| | | |   \ \/  \/ / | | '_ \  |$"
winMessage6		db 	"|    | | (_) | |_| |    \  /\  /  | | | | | |$"
winMessage7		db 	"|    |_|\___/ \__,_|     \/  \/   |_|_| |_| |$"
winMessage8		db 	"|                                           |$"
winMessage9		db 	"|                Time:000000                |$"
winMessage10	db 	"|-------------------------------------------|$"

loseMessage1 	db 	"|-------------------------------------------|$"
loseMessage2 	db 	"| __     __           _                     |$"
loseMessage3 	db 	"| \ \   / /          | |                    |$"
loseMessage4 	db 	"|  \ \_/ /__  _   _  | |     ___  ___  ___  |$"
loseMessage5 	db 	"|   \   / _ \| | | | | |    / _ \/ __|/ _ \ |$"
loseMessage6 	db 	"|    | | (_) | |_| | | |___| (_) \__ \  __/ |$"
loseMessage7 	db 	"|    |_|\___/ \__,_| |______\___/|___/\___| |$"
loseMessage8 	db 	"|                                           |$"
loseMessage9 	db 	"|-------------------------------------------|$"

;10,13 �N��^��.���檺ASCII�X
mineSweeper 	db 	"          __  __ _             _____ ",10,13
			db 	"         |  \/  (_)           / ____|",10,13
			db 	"         |      |_ _ __   ___| (_____      _____  ___ _ __   ___ _ __ ",10,13
           		db 	"         | |\/| | | '_ \ / _ \\___ \ \ /\ / / _ \/ _ \ '_ \ / _ \ '__|",10,13
            	db 	"         | |  | | | | | |  __/____) | V  V |  __/  __/ |_) |  __/ |",10,13
            	db 	"         |_|  |_|_|_| |_|\___|_____/ \_/\_/ \___|\___| .__/ \___|_|",10,13
            	db 	"                                                     | | ",10,13
            	db 	"                                                     |_|  ",10,13;
			db 	10,13;
			db 	10,13
			db 	"                                 How to play ",10,13
			db 	"                    <w>:up  <s>:down  <a>:left  <d>:right ",10,13
			db 	"                      <j>:open block  <k>:set/reset flag   ",10,13
			db 	10,13
			db 	10,13
			db 	"                               <c>Change mine",10,13
			db 	10,13
			db 	"                          Choose difficulty and start",10,13
			db 	" <1>:Easy(8x8,10 mines)  <2>:Normal(16x16,40 mines)  <3>:Hard(24x32,120 mines)",10,13
			db 	"                                  <e>:exit game$",10,13

;�w�q�@�Ӥ��(20*20)���Ϯ� �Ω�b�C���e���W���
;�Ʀr�ϥ�(0~9)
selectedBitmap0	db 	20 dup(08h)
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	20 dup(08h)

selectedBitmap1 	db 	20 dup(08h)
			db 	08h,18 dup(07h),08h
			db 	08h,7 dup(07h),3 dup(09h),8 dup(07h),08h
			db 	08h,6 dup(07h),4 dup(09h),8 dup(07h),08h
			db 	08h,5 dup(07h),5 dup(09h),8 dup(07h),08h
			db 	08h,5 dup(07h),2 dup(09h),07h,2 dup(09h),8 dup(07h),08h
			db 	08h,8 dup(07h),2 dup(09h),8 dup(07h),08h
			db 	08h,8 dup(07h),2 dup(09h),8 dup(07h),08h
			db 	08h,8 dup(07h),2 dup(09h),8 dup(07h),08h
			db 	08h,8 dup(07h),2 dup(09h),8 dup(07h),08h
			db 	08h,8 dup(07h),2 dup(09h),8 dup(07h),08h
			db 	08h,8 dup(07h),2 dup(09h),8 dup(07h),08h
			db 	08h,8 dup(07h),2 dup(09h),8 dup(07h),08h
			db 	08h,8 dup(07h),2 dup(09h),8 dup(07h),08h
			db 	08h,8 dup(07h),2 dup(09h),8 dup(07h),08h
			db 	08h,8 dup(07h),2 dup(09h),8 dup(07h),08h
			db 	08h,4 dup(07h),10 dup(09h),4 dup(07h),08h
			db 	08h,4 dup(07h),10 dup(09h),4 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	20 dup(08h)

selectedBitmap2 	db 	20 dup(08h)
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,6 dup(07h),6 dup(0ah),6 dup(07h),08h
			db 	08h,5 dup(07h),8 dup(0ah),5 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(0ah),5 dup(07h),3 dup(0ah),4 dup(07h),08h
			db 	08h,4 dup(07h),1 dup(0ah),7 dup(07h),2 dup(0ah),4 dup(07h),08h
			db 	08h,12 dup(07h),2 dup(0ah),4 dup(07h),08h
			db 	08h,12 dup(07h),2 dup(0ah),4 dup(07h),08h
			db 	08h,11 dup(07h),3 dup(0ah),4 dup(07h),08h
			db 	08h,9 dup(07h),4 dup(0ah),5 dup(07h),08h
			db 	08h,7 dup(07h),4 dup(0ah),7 dup(07h),08h
			db 	08h,6 dup(07h),3 dup(0ah),9 dup(07h),08h
			db 	08h,5 dup(07h),3 dup(0ah),10 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(0ah),12 dup(07h),08h
			db 	08h,4 dup(07h),10 dup(0ah),4 dup(07h),08h
			db 	08h,5 dup(07h),9 dup(0ah),4 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	20 dup(08h)

selectedBitmap3 	db 	20 dup(08h)
			db 	08h,18 dup(07h),08h
			db 	08h,6 dup(07h),6 dup(0ch),6 dup(07h),08h
			db 	08h,5 dup(07h),8 dup(0ch),5 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(0ch),5 dup(07h),3 dup(0ch),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(0ch),6 dup(07h),2 dup(0ch),4 dup(07h),08h
			db 	08h,12 dup(07h),2 dup(0ch),4 dup(07h),08h
			db 	08h,12 dup(07h),2 dup(0ch),4 dup(07h),08h
			db 	08h,7 dup(07h),7 dup(0ch),4 dup(07h),08h
			db 	08h,7 dup(07h),6 dup(0ch),5 dup(07h),08h
			db 	08h,11 dup(07h),2 dup(0ch),5 dup(07h),08h
			db 	08h,12 dup(07h),2 dup(0ch),4 dup(07h),08h
			db 	08h,12 dup(07h),2 dup(0ch),4 dup(07h),08h
			db 	08h,12 dup(07h),2 dup(0ch),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(0ch),6 dup(07h),2 dup(0ch),4 dup(07h),08h
			db 	08h,4 dup(07h),9 dup(0ch),5 dup(07h),08h
			db 	08h,5 dup(07h),7 dup(0ch),6 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	20 dup(08h)

selectedBitmap4 	db 	20 dup(08h)
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,9 dup(07h),2 dup(01h),7 dup(07h),08h
			db 	08h,8 dup(07h),3 dup(01h),7 dup(07h),08h
			db 	08h,7 dup(07h),4 dup(01h),7 dup(07h),08h
			db 	08h,6 dup(07h),2 dup(01h),1 dup(07h),2 dup(01h),7 dup(07h),08h
			db 	08h,5 dup(07h),2 dup(01h),2 dup(07h),2 dup(01h),7 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(01h),3 dup(07h),2 dup(01h),7 dup(07h),08h
			db 	08h,3 dup(07h),2 dup(01h),4 dup(07h),2 dup(01h),7 dup(07h),08h
			db 	08h,3 dup(07h),11 dup(01h),4 dup(07h),08h
			db 	08h,3 dup(07h),11 dup(01h),4 dup(07h),08h
			db 	08h,9 dup(07h),2 dup(01h),7 dup(07h),08h
			db 	08h,9 dup(07h),2 dup(01h),7 dup(07h),08h
			db 	08h,9 dup(07h),2 dup(01h),7 dup(07h),08h
			db 	08h,9 dup(07h),2 dup(01h),7 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	20 dup(08h)

selectedBitmap5 	db 	20 dup(08h)
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,5 dup(07h),9 dup(04h),4 dup(07h),08h
			db 	08h,4 dup(07h),9 dup(04h),5 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(04h),12 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(04h),12 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(04h),12 dup(07h),08h
			db 	08h,4 dup(07h),8 dup(04h),6 dup(07h),08h
			db 	08h,5 dup(07h),8 dup(04h),5 dup(07h),08h
			db 	08h,11 dup(07h),3 dup(04h),4 dup(07h),08h
			db 	08h,12 dup(07h),2 dup(04h),4 dup(07h),08h
			db 	08h,12 dup(07h),2 dup(04h),4 dup(07h),08h
			db 	08h,12 dup(07h),2 dup(04h),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(04h),5 dup(07h),3 dup(04h),4 dup(07h),08h
			db 	08h,4 dup(07h),9 dup(04h),5 dup(07h),08h
			db 	08h,5 dup(07h),7 dup(04h),6 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	20 dup(08h)

selectedBitmap6 	db 	20 dup(08h)
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,5 dup(07h),9 dup(01h),4 dup(07h),08h
			db 	08h,4 dup(07h),9 dup(01h),5 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(01h),12 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(01h),12 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(01h),12 dup(07h),08h
			db 	08h,4 dup(07h),8 dup(01h),6 dup(07h),08h
			db 	08h,4 dup(07h),9 dup(01h),5 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(01h),5 dup(07h),3 dup(01h),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(01h),6 dup(07h),2 dup(01h),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(01h),6 dup(07h),2 dup(01h),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(01h),6 dup(07h),2 dup(01h),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(01h),5 dup(07h),3 dup(01h),4 dup(07h),08h
			db 	08h,4 dup(07h),9 dup(01h),5 dup(07h),08h
			db 	08h,5 dup(07h),7 dup(01h),6 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	20 dup(08h)

selectedBitmap7 	db 	20 dup(08h)
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,5 dup(07h),9 dup(00h),4 dup(07h),08h
			db 	08h,6 dup(07h),9 dup(00h),3 dup(07h),08h
			db 	08h,13 dup(07h),2 dup(00h),3 dup(07h),08h
			db 	08h,13 dup(07h),2 dup(00h),3 dup(07h),08h
			db 	08h,13 dup(07h),2 dup(00h),3 dup(07h),08h
			db 	08h,13 dup(07h),2 dup(00h),3 dup(07h),08h
			db 	08h,12 dup(07h),2 dup(00h),4 dup(07h),08h
			db 	08h,12 dup(07h),2 dup(00h),4 dup(07h),08h
			db 	08h,11 dup(07h),2 dup(00h),5 dup(07h),08h
			db 	08h,11 dup(07h),2 dup(00h),5 dup(07h),08h
			db 	08h,11 dup(07h),2 dup(00h),5 dup(07h),08h
			db 	08h,11 dup(07h),2 dup(00h),5 dup(07h),08h
			db 	08h,10 dup(07h),2 dup(00h),6 dup(07h),08h
			db 	08h,10 dup(07h),2 dup(00h),6 dup(07h),08h
			db 	08h,10 dup(07h),2 dup(00h),6 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	20 dup(08h)

selectedBitmap8 	db 	20 dup(08h)
			db 	08h,18 dup(07h),08h
			db 	08h,6 dup(07h),6 dup(08h),6 dup(07h),08h
			db 	08h,5 dup(07h),8 dup(08h),5 dup(07h),08h
			db 	08h,4 dup(07h),3 dup(08h),4 dup(07h),3 dup(08h),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(08h),6 dup(07h),2 dup(08h),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(08h),6 dup(07h),2 dup(08h),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(08h),6 dup(07h),2 dup(08h),4 dup(07h),08h
			db 	08h,5 dup(07h),2 dup(08h),4 dup(07h),2 dup(08h),5 dup(07h),08h
			db 	08h,6 dup(07h),6 dup(08h),6 dup(07h),08h
			db 	08h,5 dup(07h),8 dup(08h),5 dup(07h),08h
			db 	08h,4 dup(07h),3 dup(08h),4 dup(07h),3 dup(08h),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(08h),6 dup(07h),2 dup(08h),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(08h),6 dup(07h),2 dup(08h),4 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(08h),6 dup(07h),2 dup(08h),4 dup(07h),08h
			db 	08h,4 dup(07h),3 dup(08h),4 dup(07h),3 dup(08h),4 dup(07h),08h
			db 	08h,5 dup(07h),8 dup(08h),5 dup(07h),08h
			db 	08h,6 dup(07h),6 dup(08h),6 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	20 dup(08h)

selectedBitmap9 	db 	20 dup(08h)
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,3 dup(07h),1 dup(00h),4 dup(07h),2 dup(00h),4 dup(07h),1 dup(00h),3 dup(07h),08h
			db 	08h,4 dup(07h),1 dup(00h),2 dup(07h),4 dup(00h),2 dup(07h),1 dup(00h),4 dup(07h),08h
			db 	08h,5 dup(07h),8 dup(00h),5 dup(07h),08h
			db 	08h,5 dup(07h),1 dup(00h),3 dup(0fh),4 dup(00h),5 dup(07h),08h
			db 	08h,4 dup(07h),2 dup(00h),3 dup(0fh),5 dup(00h),4 dup(07h),08h
			db 	08h,3 dup(07h),3 dup(00h),3 dup(0fh),6 dup(00h),3 dup(07h),08h
			db 	08h,3 dup(07h),12 dup(00h),3 dup(07h),08h
			db 	08h,4 dup(07h),10 dup(00h),4 dup(07h),08h
			db 	08h,5 dup(07h),8 dup(00h),5 dup(07h),08h
			db 	08h,5 dup(07h),8 dup(00h),5 dup(07h),08h
			db 	08h,4 dup(07h),1 dup(00h),2 dup(07h),4 dup(00h),2 dup(07h),1 dup(00h),4 dup(07h),08h
			db 	08h,3 dup(07h),1 dup(00h),4 dup(07h),2 dup(00h),4 dup(07h),1 dup(00h),3 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	08h,18 dup(07h),08h
			db 	20 dup(08h)

;��ɤ���ϥ�
edgeBitmap	db 	20 dup(08h)
		db 	08h,08h,16 dup(07h),08h,08h
		db 	08h,07h,08h,14 dup(07h),08h,07h,08h
		db 	08h,7,7,8,12 dup(07h),8,7,7,08h
		db 	08h,7,7,7,8,10 dup(07h),8,7,7,7,08h
		db 	08h,7,7,7,7,8,8 dup(07h),8,7,7,7,7,08h
		db 	08h,7,7,7,7,7,8,6 dup(07h),8,7,7,7,7,7,08h
		db 	08h,7,7,7,7,7,7,8,4 dup(07h),8,7,7,7,7,7,7,08h
		db 	08h,7,7,7,7,7,7,7,8,2 dup(07h),8,7,7,7,7,7,7,7,08h
		db 	08h,8 dup(7),8,8,8 dup(7),08h
		db 	08h,8 dup(7),8,8,8 dup(7),08h
		db 	08h,7,7,7,7,7,7,7,8,2 dup(07h),8,7,7,7,7,7,7,7,08h
		db 	08h,7,7,7,7,7,7,8,4 dup(07h),8,7,7,7,7,7,7,08h
		db 	8h,7,7,7,7,7,8,6 dup(07h),8,7,7,7,7,7,08h
		db 	08h,7,7,7,7,8,8 dup(07h),8,7,7,7,7,08h
		db 	08h,7,7,7,8,10 dup(07h),8,7,7,7,08h
		db 	08h,7,7,8,12 dup(07h),8,7,7,08h
		db 	08h,07h,08h,14 dup(07h),08h,07h,08h
		db 	08h,08h,16 dup(07h),08h,08h
		db 	20 dup(08h)

;����ϥ�
BlockBitmap db 	39 dup(0fh),08h
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	2 dup(0fh),16 dup(07h),2 dup(08h)
		db 	0fh,39 dup(08h)

;�X�m�ϥ�
flagBitmap	db 	39 dup(0fh),08h
		db 	2 dup(0fh),7 dup(07h),2 dup(0ch),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),6 dup(07h),3 dup(0ch),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),5 dup(07h),4 dup(0ch),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),4 dup(07h),5 dup(0ch),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),3 dup(07h),6 dup(0ch),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),2 dup(07h),7 dup(0ch),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),3 dup(07h),6 dup(0ch),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),4 dup(07h),5 dup(0ch),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),5 dup(07h),4 dup(0ch),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),6 dup(07h),3 dup(0ch),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),7 dup(07h),2 dup(0ch),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),8 dup(07h),1 dup(00h),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),8 dup(07h),1 dup(00h),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),8 dup(07h),1 dup(00h),7 dup(07h),2 dup(08h)
		db 	2 dup(0fh),3 dup(07h),10 dup(00h),3 dup(07h),2 dup(08h)
		db 	2 dup(0fh),2 dup(07h),12 dup(00h),2 dup(07h),2 dup(08h)
		db 	0fh,39 dup(08h)

;�a�p�ϥ�
bombBitmap	db 	20 dup(08h)
		db 	08h,18 dup(07h),08h
		db 	08h,18 dup(07h),08h
		db 	08h,18 dup(07h),08h
		db 	08h,3 dup(07h),1 dup(00h),4 dup(07h),2 dup(00h),4 dup(07h),1 dup(00h),3 dup(07h),08h
		db 	08h,4 dup(07h),1 dup(00h),2 dup(07h),4 dup(00h),2 dup(07h),1 dup(00h),4 dup(07h),08h
		db 	08h,5 dup(07h),8 dup(00h),5 dup(07h),08h
		db 	08h,5 dup(07h),1 dup(00h),3 dup(0fh),4 dup(00h),5 dup(07h),08h
		db 	08h,4 dup(07h),2 dup(00h),3 dup(0fh),5 dup(00h),4 dup(07h),08h
		db	08h,3 dup(07h),3 dup(00h),3 dup(0fh),6 dup(00h),3 dup(07h),08h
		db 	08h,3 dup(07h),12 dup(00h),3 dup(07h),08h
		db 	08h,4 dup(07h),10 dup(00h),4 dup(07h),08h
		db 	08h,5 dup(07h),8 dup(00h),5 dup(07h),08h
		db 	08h,5 dup(07h),8 dup(00h),5 dup(07h),08h
		db 	08h,4 dup(07h),1 dup(00h),2 dup(07h),4 dup(00h),2 dup(07h),1 dup(00h),4 dup(07h),08h
		db 	08h,3 dup(07h),1 dup(00h),4 dup(07h),2 dup(00h),4 dup(07h),1 dup(00h),3 dup(07h),08h
		db 	08h,18 dup(07h),08h
		db 	08h,18 dup(07h),08h
		db 	08h,18 dup(07h),08h
		db 	20 dup(08h)

dihongBitmap	db 	10 dup(9),10 dup(12)
			db 	9,9,15,9,15,9,15,9,9,9,10 dup(12)
			db 	8 dup(9),15,9,10 dup(12)
			db 	9,15,9,9,2 dup(15),4 dup(9),10 dup(12)
			db 	3 dup(9),4 dup(15),9,15,9,10 dup(12)
			db 	9,15,9,4 dup(15),3 dup(9),10 dup(12)
			db 	4 dup(9),2 dup(15),9,9,15,9,10 dup(12)
			db 	9,15,8 dup(9),10 dup(12)
			db 	9,9,9,15,9,15,9,15,9,9,10 dup(12)
			db 	10 dup(9),10 dup(12)
			db 	200 dup(12)

flowerBitmap	db 	40 dup(7);7 14 15
			db 	9 dup(7),15,15,9 dup(7)
			db 	3 dup(7),3 dup(15),2 dup(7),4 dup(15),2 dup(7),3 dup(15),3 dup(7)
			db 	3 dup(7),4 dup(15),1 dup(7),4 dup(15),1 dup(7),4 dup(15),3 dup(7)
			db 	3 dup(7),14 dup(15),3 dup(7)
			db 	4 dup(7),12 dup(15),4 dup(7)
			db 	5 dup(7),3 dup(15),1 dup(7),2 dup(15),1 dup(7),3 dup(15),5 dup(7)
			db 	3 dup(7),4 dup(15),1 dup(7),4 dup(14),1 dup(7),4 dup(15),3 dup(7)
			db 	2 dup(7),6 dup(15),4 dup(14),6 dup (15),2 dup(7)
			db 	2 dup(7),6 dup(15),4 dup(14),6 dup (15),2 dup(7)
			db 	3 dup(7),4 dup(15),1 dup(7),4 dup(14),1 dup(7),4 dup(15),3 dup(7)
			db 	5 dup(7),3 dup(15),1 dup(7),2 dup(15),1 dup(7),3 dup(15),5 dup(7)
			db 	4 dup(7),12 dup(15),4 dup(7)
			db 	3 dup(7),14 dup(15),3 dup(7)
			db 	3 dup(7),4 dup(15),1 dup(7),4 dup(15),1 dup(7),4 dup(15),3 dup(7)
			db 	3 dup(7),3 dup(15),2 dup(7),4 dup(15),2 dup(7),3 dup(15),3 dup(7)
			db 	9 dup(7),15,15,9 dup(7)
			db 	40 dup(7)
;�Ϥ��ϥ�
fireworkRow dw 	56,60,96,100
		dw 	52,56,92,96
		dw 	52,84,88
		dw 	8,12,48,52,76,80;3
		dw 	12,16,48,72
		dw 	16,20,24,28,48,68,72
		dw 	0,4,8,12,28,32,48,68,100,104
		dw 	12,16,32,48,64,92,96,100;7
		dw 	16,20,36,48,60,84,88,92
		dw 	24,36,84
		dw 	28,32,40,80,84
		dw 	12,16,40,76,80;11
		dw 	4,8,20,24,72,76
		dw 	28,32,84,88,92,96,100
		dw 	44,48,100,104
		dw 	28,40,72,76,108;15
		dw 	24,36,40,52,56,80,84,108,112
		dw 	20,32,48,88,112;17
		dw 	16,28,32,44,56,72,92,96
		dw 	12,28,40,56,72,84,96
		dw 	8,24,36,40,56,72,84,100
		dw 	8,20,24,36,56,72,88,104
		dw 	4,20,36,56,72,92,104
		dw 	4,20,32,56,76,92,108;23
		dw 	0,20,32,60,76,96,108
		dw 	0,20,32,60,76,96,108
		dw 	0,20,32,60,80,96;26
		dw 	36,60,64,84,96
		dw 	36,96
		dw 	96

fireworkCol dw 	4 dup(0),4 dup(4),3 dup(8)
		dw	6 dup(12),4 dup(16),7 dup(20),10 dup(24),8 dup(28),8 dup(32)
		dw 	3 dup(36),5 dup(40),5 dup(44),6 dup(48),7 dup(52),4 dup(56)
		dw 	5 dup(60),9 dup(64),5 dup(68),8 dup(72),7 dup(76),8 dup(80)
		dw 	8 dup(84),7 dup(88),7 dup(92),7 dup(96),7 dup(100),6 dup(104)
		dw 	5 dup(108),2 dup(112),116

fireworkBitmap 	db 	4,4,14,14
			db 	4,4,14,14
			db 	4,14,14
			db 	14,14,4,4,14,14
			db 	14,14,4,14;4
			db 	14,14,14,14,4,14,14
			db 	4,4,4,4,14,14,4,14,14,14
			db 	4,4,14,4,14,14,14,14
			db 	4,4,14,4,14,14,14,14
			db 	4,14,14;9
			db 	4,4,14,14,14
			db 	14,14,14,14,14
			db 	14,14,14,14,14,14
			db 	14,14,4,4,4,4,4
			db 	14,14,4,4;14
			db 	4,14,14,14,4
			db 	4,14,14,4,4,14,14,4,4
			db 	4,14,4,14,4
			db 	4,14,14,4,14,4,14,14;18
			db 	4,14,4,14,4,4,14
			db 	4,14,4,4,14,4,4,14
			db 	4,14,14,4,14,4,4,14
			db 	4,14,4,14,4,4,14;22
			db 	4,14,4,14,4,4,14
			db 	4,14,4,14,4,4,14
			db 	4,14,4,14,4,4,14
			db 	4,14,4,14,4,4;26
			db 	4,14,14,4,4
			db 	4,4
			db 	4,100

data ends

code 	segment
	; �����O�A�i�D��Ķ���N�X�q������
    	assume cs:code, ds:data
	org     100h
main proc
start:
	mov ax, data	; �N data ���a�}��� ax �Ȧs��
   	mov ds, ax		; �N ax ���ȩ�� ds �Ȧs��

	Setmode 12h		;�n�N��ܾ��]�m��80x25���奻�Ҧ�
	SetColor 00h,00h
	SET_CUR 3,0
	mov ah,09h
	lea dx,mineSweeper
	int 21h
	call showChange
readStart:
	mov ah,07h	;�q�зǿ�J�]��Ū���@�Ӧr��
	int 21h
	cmp al,'e'
	je exit	;���}�C������
	cmp al,'1'
	je easy   	;²��Ҧ�
	cmp al,'2'
	je normal	;���q�Ҧ�
	cmp al,'3'
	je hard	;�x���Ҧ�

	cmp al,'c'
	je changeMine	;�������u�˦�
	jmp readStart

exit:
	SetMode 03h		;��ܼҦ����奻�Ҧ�
    	mov ax, 4c00h	;�h�X�{�� �]�m�����\��
  	int 21h		;�եΨt�Υ\��

easy:
    call easy_PROC
    jmp afterSelect
normal:
    call normal_PROC
    jmp afterSelect
hard:
    call hard_PROC
    jmp afterSelect

changeMine:
	inc mineCount		;�W�[�a�p�ƶq�p�ƾ�
	cmp mineCount,0   	;�p�GmineCount=0
	je setBombBitmap  	;����setbombitmap
	cmp mineCount,1	  	;�p�GmineCount=1
	je setFlowerBitmap	;����setFlowerBitmap
	cmp mineCount,2	  	;�p�GmineCount=2
	je setDiHongBitmap	;����setDiHong
	mov mineCount,0	  	;�p�GmineCount>2,���m�^0
	jmp setBombBitmap 	;����setbombitmap
  setDiHongBitmap:
	mov ax,ds
	mov es,ax
	mov si,offset dihongBitmap    ;�Nsi�]�m��dihongBitmap �Ϲ��������q
	mov di,offset selectedBitmap9 ;�Ndi�]�m��selectedBitmap9 �Ϲ��������q
	mov cx,400 				;�]�m�p�ƾ�
	rep movsb 				;�N�ƾڱqsi�h����di �ô��cx����0
	call showChange
	jmp readStart
  setBombBitmap:
	mov ax,ds
	mov es,ax
	mov si,offset bombBitmap	;�Nsi�]�m��bombBitmap �Ϲ��������q
	mov di,offset selectedBitmap9	;�Nsi�]�m��selectedBitmap9 �Ϲ��������q
	mov cx,400
	rep movsb				;�N�ƾڱqsi�h����di �ô��cx����0
	call showChange
	jmp readStart
  setFlowerBitmap:
	mov ax,ds
	mov es,ax
	mov si,offset flowerBitmap	;�N���V�ᦷ��ϼƾڪ����w���J SI ��
	mov di,offset selectedBitmap9 ;���V��ܽw�s�Ϫ����w���J DI ��
	mov cx,400				;�]�m�p�ƾ�
	rep movsb				;�N�ƾڱqsi�h����di �ô��cx����0
	call showChange
	jmp readStart

afterSelect:
	mov bp,0
	call scanMap

Flash:
	call printChoose		;�ե�printChoose �C�L��ܬ���
	call checkWin		;�ե�checkWin �P�_�ӧQ����
readin:
	GetChar getc		;�q��L��J������@�Ӧr��
	inc timeCount		;timeCount +1
	cmp timeCount,0ffffh	;�p�GtimeCount�F��0ffffh(65536)
	jne notCarry		;�S�F�� ����notCarry
	mov timeCount,0		;�F�� �NtimeCount�k�s
	inc timeCount1		;�ñNtimeCount1 +1
	cmp timeCount1,00fh	;�p�GtimeCount�F��00fh
	jne notCarry		;�S�F�� ����notCarry
	inc score[2]		;�F�� score[2] +1
	mov timeCount1,0		;�ñNtimeCount1�k�s
	cmp score[2],100		;�p�Gscore[2]�F��100
	jne notCarry		;�S�F�� ����notCarry
	mov score[2],0		;�F��h�Nscore[2]�k�s
	inc score[1]		;�ñNscore[1]+1
	cmp score[1],100		;�p�Gscore[1]�F��100
	jne notCarry		;�S�F�� ����notCarry
	mov score[1],0		;�F��h�Nscore[1]�k�s
	inc score[0]		;�ñNscore[0]+1
  notCarry:
	cmp getc,'w'
	je up				;����up �P�_"�W"���ʧ@
	cmp getc,'d'
	je right			;����right �P�_"�k"���ʧ@
	cmp getc,'a'
	je left			;����left �P�_"��"���ʧ@
	cmp getc,'s'
	je down			;����down �P�_"�U"���ʧ@
	cmp getc,'j'
	je select_jmp		;����select �P�_"���U"�ʧ@
	cmp getc,'k'
	je setFlag_jmp		;����setFlag �P�_"�]�X"�ʧ@
	;�@���� ��k�P�_
	;�W�W�U�U���k���kba
	cmp getc,72			;�W��V��
	je cheatUp			;����cheatUp �P�_�@���X
	cmp getc,77			;�k��V��
	je cheatRight		;����cheatRight �P�_�@���X
	cmp getc,75			;����V��
	je cheatLeft		;����cheatLeft �P�_�@���X
	cmp getc,80			;�U��V��
	je cheatDown		;����cheatDown �P�_�@���X
	cmp getc,'b'		;'b'
	je cheatB			;����cheatB �P�_�@���X
	jmp readin			;����readin ���s��J
select_jmp:
    jmp select
setFlag_jmp:
    jmp setFlag
up:
    call up_PROC
    jmp Flash
down:
    call down_PROC
    jmp Flash
right:
    call right_PROC
    jmp Flash
left:
	cmp cheat,9			;��@���X���\���ר�9 ���\���U�̫�@�X'a'
	je setCheat			;�O ����setCheat
	mov cheat,0			;�@���X�k�s
	call reChoose		;�ե�reChoose �M�����m����
	cmp position[0],0		;�p�G�b�̥���
	je LLimit			;�O ����LLimit
	dec position[0]		;���-1
	jmp chooseLeft		;����"������"�ʧ@
  LLimit:
	mov position[0],31	;�q�̥��䨫��̥k��
  chooseLeft:
	xor ax,ax			;�Nax�k�s
	mov al,20
	mul position[0]		;mul���O�|�Nal���ȩMposition[0]���Ȭۭ� �N���G�s�x�bax
	mov row,ax
	jmp Flash			;����Flash ��ܿ������

cheatUp:
    call cheatUp_PROC
    jmp readin			;�M�����readin
cheatDown:
    call cheatDown_PROC
    jmp readin			;�M�����readin
cheatLeft:
    call cheatLeft_PROC
    jmp readin			;�M�����readin
cheatRight:
    call cheatRight_PROC
    jmp readin			;�M�����readin
cheatB:
    call cheatB_PROC
    jmp readin			;�M�����readin
setCheat:
	mov di,0 			;�Ndi�]��0
  openCheat:
	cmp mineState[di],9 	;���ineState[di]�M9�O�_�۵�
	je cheatNext        	;�p�G�۵� ����cheatNext
	mov BlockState[di],1	;BlockState[di]�]��1
  cheatNext:
	inc di 			;di+1
	cmp di,768 			;���di�O�_=768
	jne openCheat 		;di!=768�N����openCheat
	mov row,0 			;�p�G�ˬd���F�Ҧ��϶��A�N row �M col �]�� 0
	mov col,0
	call scanMap
	call checkWin


select:
	mov cheat,0
	cmp isStart,0
	jne started
	mov isStart,1
	mov timeCount,0
	mov timeCount1,0
	mov score[0],0
	mov score[1],0
	mov score[2],0
	xor ax,ax
	mov al,32
	mul position[2]
	add ax,word ptr position[0]
	mov di,ax
	mov mineState[di],99
	mov firstBlock,di
	call setmine
	call calculate
started:
	xor ax,ax
	mov al,32
	mul position[2]
	add ax,word ptr position[0]
	mov di,ax
	cmp BlockState[di],0
	jne Flash_jmp
	mov BlockState[di],1
	push di
	call reChoose
	pop di
	cmp mineState[di],9
	je lose
	push di
	call selectSound
	pop di
	cmp mineState[di],0
	jne Flash_jmp
	call check
	push col
	push row
	mov row,0
	mov col,0
	call scanMap
	pop row
	pop col
	jmp Flash
Flash_jmp:
    jmp Flash
lose:
	call bombSound
	call runLose
	SET_CUR 11,17
	lea dx,loseMessage1
	mov ah,09h
	int 21h
	SET_CUR 12,17
	lea dx,loseMessage2
	mov ah,09h
	int 21h
	SET_CUR 13,17
	lea dx,loseMessage3
	mov ah,09h
	int 21h
	SET_CUR 14,17
	lea dx,loseMessage4
	mov ah,09h
	int 21h
	SET_CUR 15,17
	lea dx,loseMessage5
	mov ah,09h
	int 21h
	SET_CUR 16,17
	lea dx,loseMessage6
	mov ah,09h
	int 21h
	SET_CUR 17,17
	lea dx,loseMessage7
	mov ah,09h
	int 21h
	SET_CUR 18,17
	lea dx,loseMessage8
	mov ah,09h
	int 21h
	SET_CUR 19,17
	lea dx,loseMessage9
	mov ah,09h
	int 21h
	call loseSound
	mov ah,07h
	int 21h
	call reset
	jmp start

setFlag:
	mov cheat,0
	xor ax,ax 				;�Nax�M0
	mov al,32 				;�N al �]�� 32�A�Ψӭp����ަ�m
	mul position[2] ;�Nal��y�y��
	add ax,word ptr position[0]	;�[�Wx�y�� (�Nposition[0]�[��ax����A�i�H�p��X�����϶��b BlockState�����ަ�m�C)
	mov di,ax 				;�⵲�G���di
	cmp BlockState[di],0 		;�P�_�o�Ӧ�m���S���Q���}
	jne notSet 				;�p�G�w�g�Q½�}�δ��X�A���� notSet ����
	mov BlockState[di],2 		;��o�Ӧ�m�]�w�����X���A
	call reChoose
	call setFlagSound  		;���񴡺X����
	jmp Flash ;
  notSet:
	cmp BlockState[di],2 		;�P�_���S�����X�l
	jne Flash_jmp2 			;�p�G���O����flash
	mov BlockState[di],0 		;�����X�l
	call reChoose
	call resetFlagSound 		;����������X����
	jmp Flash
Flash_jmp2:
    jmp Flash
main endp

;²��Ҧ�(8*8)
easy_PROC proc
    mov mineNumber,10			;10���a�p
    mov di,0
Le1:
	mov ax,di
	mov bl,32				;�`���(24*32)
	div bl				;�ت��O�p��渹�M�C�� ax=(row)
	cmp ah,8				;�O���O8��
	jae Le2
	cmp al,8				;�O���O8�C
	jae Le2
	inc di
	cmp di,768				;�ˬd�`�@�O���O768��(24*32)
	je Le3				;�O768�� �a�Ϥw�B�z����
	jmp Le1
Le2:
	mov BlockState[di],1
	mov mineState[di],10
	inc di
	cmp di,768				;�ˬd�`�@�O���O768��(24*32)
	je Le3				;�O768�� �a�Ϥw�B�z����
	jmp Le1
Le3:
	mov di,0
	mov difficulty,1
	ret
easy_PROC endp

;���q�Ҧ�
normal_PROC proc
    mov mineNumber,40			;40���a�p
    mov di,0
Ln1:
	mov ax,di
	mov bl,32				;�`���(24*32)
	div bl				;�ت��O�p��渹�M�C�� ax=(row)
	cmp ah,16				;�O���O16��
	jae Ln2
	cmp al,16				;�O���O16�C
	jae Ln2
	inc di				;�����w�B�z�Ӯ��
	cmp di,768				;�ˬd����768��(24*32)�O���O���B�z�F
	je Ln3				;�O768�� �a�Ϥw�B�z����
	jmp Ln1
Ln2:
	mov BlockState[di],1		;�аO����m�O�S�a�p
	mov mineState[di],10		;�аO����m�O�a�p
	inc di
	cmp di,768				;�ˬd�`�@�O���O768��(24*32)
	je Ln3				;�O768�� �a�Ϥw�B�z����
	jmp Ln1
Ln3:
	mov di,0
	mov difficulty,2
	ret
normal_PROC endp

;�x���Ҧ�
hard_PROC proc
    mov mineNumber,120			;120���a�p
    ret
hard_PROC endp

;�P�_���U'w'
up_PROC proc
	mov cheat,0				;�@���X�k�s
	call reChoose			;�ե�reChoose �M�����m����
	cmp position[2],0			;�p�G�b�̤W�h
	je top				;�O ����top
	dec position[2]			;�C��-1
	jmp chooseUp			;����"���W��"�ʧ@
top:
	mov position[2],23 		;�q�̤W�h����̤U�h
chooseUp:
	xor ax,ax 				;�Nax�k�s
	mov al,20
	mul position[2]			;mul���O�|�Nal���ȩMposition[2]���Ȭۭ� �N���G�s�x�bax
	mov col,ax
	ret
up_PROC endp

;�P�_���U'd'
right_PROC proc
	mov cheat,0				;�@���X�k�s
	call reChoose			;�ե�reChoose �M�����m����
	cmp position[0],31		;�p�G�b�̥k��(24*32)
	je RLimit				;�O ����RLimit
	inc position[0]			;���+1
	jmp chooseRight			;����"���k��"�ʧ@
RLimit:
	mov position[0],0			;�q�̥k�h��̥��h
chooseRight:
	xor ax,ax				;�Nax�k�s
	mov al,20
	mul position[0]			;mul���O�|�Nal���ȩMposition[0]���Ȭۭ� �N���G�s�x�bax
	mov row,ax
	ret
right_PROC endp

;�P�_���U's'
down_PROC proc
	mov cheat,0				;�@���X�k�s
	call reChoose			;�ե�reChoose �M�����m����
	cmp position[2],23		;�p�G�b�̤U�h(24*32)
	je bottom				;�O ����bottom
	inc position[2]			;�C��+1
	jmp chooseDown			;����"���U��"�ʧ@
bottom:
	mov position[2],0			;�q�̩��U����̤W�h
chooseDown:
	xor ax,ax				;�Nax�k�s
	mov al,20
	mul position[2]			;mul���O�|�Nal���ȩMposition[2]���Ȭۭ� �N���G�s�x�bax
	mov col,ax
	ret
down_PROC endp

;�P�_���U'�W'
cheatUp_PROC proc
    cmp cheat,2   			;���cheat�M2
	jae exit_cheatUp			;�p�Gcheat>=2����resetCheat
	inc cheat 				;cheat+1
	ret
exit_cheatUp:
    call resetCheat_PROC
    ret
cheatUp_PROC endp

;�P�_���U'�U'
cheatDown_PROC proc
	cmp cheat,2 			;���cheat�M2
	jb exit_cheatDown			;�p�Gcheat<2�h����resetCheat
	cmp cheat,4 			;���cheat 4
	jae exit_cheatDown		;�p�Gcheat>=4����resetCheat
	inc cheat  				;cheat+1
	ret
exit_cheatDown:
    call resetCheat_PROC
    ret
cheatDown_PROC endp

;�P�_���U'��'
cheatLeft_PROC proc
	cmp cheat,4 			;���cheat�M4
	jne cheatL2 			;���۵��h����cheatL2
	inc cheat   			;cheat+1
	ret
  cheatL2:
	cmp cheat,6 			;���cheat�M6
	jne exit_cheatLeft 		;���۵��h����resetCheat
	inc cheat   			;cheat+1
	ret
exit_cheatLeft:
    call resetCheat_PROC
    ret
cheatLeft_PROC endp

;�P�_���U'�k'
cheatRight_PROC proc
	cmp cheat,5 			;���cheat�M5
	jne cheatR2 			;���۵��h����cheatR2
	inc cheat   			;cheat+1
	ret
  cheatR2:
	cmp cheat,7 			;���cheat�M7
	jne exit_cheatRight 		;���۵��h����resetCheat
	inc cheat 				;cheat+1
	ret
exit_cheatRight:
    	call resetCheat_PROC
    	ret
cheatRight_PROC endp

cheatB_PROC proc
	cmp cheat,8 			;���cheat�M8
	jne exit_cheatB  			;���۵��h����resetCheat
	inc cheat 				;cheat+1
	ret
exit_cheatB:
    	call resetCheat_PROC
    	ret
cheatB_PROC endp

resetCheat_PROC proc
	mov cheat,0 			;�Ncheat�]��0
	ret
resetCheat_PROC endp

;�Ƶ{�� �C�L����Ƶ{��(�|�����})
printblock proc near
	cmp BlockState[di],2		;��� BlockState[di] �O�_�� 2�A�P�_���S���X�l
	jne notFlag				;�p�G�S�X�l�A�h���� notFlag
	mov bp,400				;�p�G���X�l,�Nbp�]��400,�n�L�X�l���Ϯ�
notFlag:
	mov di,0				;di=0
	add di,bp				;di+bp �M�w�n�L���Ϯ�
	mov cx,row
	mov dx,col
	mov RowCounter,0
	mov ColCounter,0
PRow:
	WrPixel cx,dx,BlockBitmap[di]	;di+bp �M�w�n�L���Ϯ�
	inc cx				;cx+1
	inc di				;di+1  ���V�U�@�ӭn�L���Ϯ�
	inc RowCounter
	mov si,RowCounter
	cmp si,20				;�P�_�O�_�w�L���@��(row)�A�p�G�O�N���� over
	je over
	jmp PRow				;�p�G�٨S�L���@��(row)�A�N�~��L
over:
	mov cx,row
	inc dx				;dx+1 ���V�U�@�C(col)
	inc ColCounter
	mov si,ColCounter
	mov RowCounter,0
	cmp si,20				;�P�_�O�_�w�L���@�C(col)�A�p�G�O�N����done
	je done
	jmp PRow				;�p�G�٨S�L���@�C(col)�A�N�~��L
done:
	mov bp,0
	ret					;��^�I�sprocedure(return)
printblock endp

;�Ƶ{�� ��s�C���e��
;�M��'BlockState'�}�C�å��L�������
scanMap proc near
	mov di,0				;'BlockState'�}�Cindex
	mov scanCount,0			;�M���p�ƾ�
initial:
	mov di,scanCount
	cmp BlockState[di],1
    	je Show				;�p�GBlockState[di]����1 ����show
	call printblock			;�ե�printblock ���L���
	jmp change				;����change
show:
	call printSelect			;�ե�printSelect ���L��ܤ��
change:
	inc scanCount			;scanCount+=1
	add row,20				;row+=20
	mov ax,XLimit			;XLimit = 640(32*20)
	cmp row,ax				;�ˬd�O�_�M������e�C���Ҧ����
	je NextCol				;�O ����NextCol
	jmp initial				;����initial
NextCol:
	mov row,0				;row�q�Y���s�}�l
	add col,20				;col+=20
	mov ax,YLimit			;YLimit = 480(24*20)
	add ax,20				;480+20=500(�W�X�ɽu)
	cmp col,ax				;�ˬd�O�_�M�����Ҧ����
	je initialDone			;�O ����initialDone
	jmp initial				;����initial
initialDone:
	mov row,0				;row�k�s
	mov col,0				;col�k�s
	mov di,0				;di�k�s
	ret					;��^
scanMap endp

;�Ƶ{�� �C�L��ܬ���
printChoose proc near
	mov cx,row				;��
	mov dx,col				;�C
	mov RowCounter,0			;�M�Ŧ�p�ƾ�
	mov ColCounter,0			;�M�ŦC�p�ƾ�
PRowCUp:					;�b��ܮؤW�b�������Ĥ@�湳�������
	WrPixel cx,dx,04h 		;�b���w��m�L�X����
	inc cx				;row+1
	inc RowCounter			;RowCounter+1
	mov si,RowCounter 		;si=RowCounter
	cmp si,20				;row=20�ɡA����overCUp
	je overCUp
	jmp PRowCUp				;�j��
overCup:					;��ܮؤW�b�������̫�@��
	mov cx,row
	inc dx				;col+1
	inc ColCounter			;ColCounter+1
	mov si,ColCounter			;si=RowCounter
	mov RowCounter,0			;RowCounter�k�s
	cmp si,2				;RowCounter=2�ɡAø�s�W�b������
	je doneCUp
	jmp PRowCUp
doneCUp:					;��ܮؤW�b����ø�s����
	mov cx,row
	mov RowCounter,0
	mov ColCounter,0
PRowCMid1:					;�����������Ĥ@��
	WrPixel cx,dx,04h			;�b���w��m�L�X����
	inc cx				;row+1
	inc RowCounter			;RowCounter+1
	mov si,RowCounter 		;si=RowCounter
	cmp si,2				;RowCounter=2�ɡA����overCMid1
	je overCMid1
	jmp PRowCMid1			;�j��
overCMid1:					;�����������̫�@��
	add cx,15				;row+15
	WrPixel cx,dx,04h 		;�b���w��m�L�X����
	inc cx				;row+1
	inc RowCounter			;RowCounter+1
	mov si,RowCounter			;si=RowCounter
	cmp si,4				;RowCounter=4�ɡA����overCMid2
	je overCMid2
	sub cx,15				;row-15
	jmp overCMid1			;�j��
overCMid2:					;�����U�b�������Ĥ@��
	mov cx,row
	inc dx				;col+1
	mov RowCounter,0			;RowCounter�k�s
	inc ColCounter			;ColCounter+1
	mov si,ColCounter 		;si=ColCounter
	cmp si,16				;ColCounter=16�ɡAø�s�����U�b��������
	je doneCMid
	jmp PRowCMid1
doneCMid:					;��������ø�s����
	mov cx,row
	mov RowCounter,0
	mov ColCounter,0
PRowCBot:					;�b��ܮة������Ĥ@�湳�������
	WrPixel cx,dx,04h 		;�b���w��m�L�X����
	inc cx				;row+1
	inc RowCounter			;RowCounter+1
	mov si,RowCounter 		;si=RowCounter
	cmp si,20				;RowCounter=20�ɡA����overCBot
	je overCBot
	jmp PRowCBot			;�j��
overCBot:					;�U���������̫�@��
	mov cx,row
	inc dx				;col+1
	inc ColCounter			;ColCounter+1
	mov si,ColCounter			;si=ColCounter
	mov RowCounter,0			;RowCounter�k�s
	cmp si,2				;ColCounter=2�ɡAø�s�U����������
	je doneC
	jmp PRowCBot
doneC:					;��ܮ�ø�s�����A�ê�^�C
	ret
printChoose endp

;�Ƶ{�� �M�����m����
reChoose proc near
	xor ax,ax
	mov al,32
	mul position[2]
	add ax,word ptr position[0]
	mov di,ax
	cmp BlockState[di],0
	je unSelected
	cmp BlockState[di],2
	je flag
	call printSelect
	ret
unSelected:
	call printblock
	ret
flag:
	mov bp,400
	call printblock
	ret
reChoose endp

;�Ƶ{�� �C�L���(�w���}�����e)
;�L�X�C�����襤����l
printSelect proc near
	xor ax,ax				;�Nax�]��0
	mov al,mineState[di]		;���XmineState������l�����A ��Jal
	mov bx,400				;��l�j�p(20*20)
	mul bx				;ax*=bx
	mov di,ax				;�Nax�]�w��selectedBitmap0�}�C��������l���_�l��m
	mov cx,row				;��e��l���C
	mov dx,col				;��e��l����
	mov RowCounter,0
	mov ColCounter,0
PRowS:
	WrPixel cx,dx,selectedBitmap0[di]
	inc cx				;�n�L�X�����+1
	inc di				;�n�L�X����Ư���+1
	inc RowCounter			;�p��L�X�������ƶq
	mov si,RowCounter
	cmp si,20				;�P�_�O�_�w�g�L�X�@��檺����
	je overS				;�O ����overS
	jmp PRowS				;����PRowS �~��L�U�@��
overS:
	mov cx,row				;row=0 �q�Y���s�}�l
	inc dx				;�C��+1
	inc ColCounter			;�p��C�Ƽƶq
	mov si,ColCounter
	mov RowCounter,0
	cmp si,20				;�P�_�O�_�W�X20�C
	je doneS				;�O �����C�L��l
	jmp PRowS				;����PRowS �~��L�U�@��_�l��m��
doneS:
	ret					;��^
printSelect endp

;�Ƶ{�� �p������ܪ��Ʀr
calculate proc
	mov di,0
start0:
	cmp mineState[di],9
	jae n3
	cmp mineState[di+1],9
	jne n1
	inc mineState[di]
  n1:
	cmp mineState[di+32],9
	jne n2
	inc mineState[di]
  n2:
	cmp mineState[di+33],9
	jne n3
	inc mineState[di]
  n3:
	inc di
start1to30:
	cmp mineState[di],9
	jae n8
	cmp mineState[di-1],9
	jne n4
	inc mineState[di]
  n4:
	cmp mineState[di+1],9
	jne n5
	inc mineState[di]
  n5:
	cmp mineState[di+31],9
	jne n6
	inc mineState[di]
  n6:
	cmp mineState[di+32],9
	jne n7
	inc mineState[di]
  n7:
	cmp mineState[di+33],9
	jne n8
	inc mineState[di]
  n8:
	inc di
	cmp di,30
	jbe start1to30
start31:
	cmp mineState[di],9
	jae n11
	cmp mineState[di-1],9
	jne n9
	inc mineState[di]
  n9:
	cmp mineState[di+31],9
	jne n10
	inc mineState[di]
  n10:
	cmp mineState[di+32],9
	jne n11
	inc mineState[di]
  n11:
	inc di
startC32to704:
	cmp mineState[di],9
	jae n16
	cmp mineState[di-32],9
	jne n12
	inc mineState[di]
  n12:
	cmp mineState[di-31],9
	jne n13
	inc mineState[di]
  n13:
	cmp mineState[di+1],9
	jne n14
	inc mineState[di]
  n14:
	cmp mineState[di+32],9
	jne n15
	inc mineState[di]
  n15:
	cmp mineState[di+33],9
	jne n16
	inc mineState[di]
  n16:
	add di,32
	cmp di,704
	jbe startC32to704
	mov di,63
startC63to735:
	cmp mineState[di],9
	jae n21
	cmp mineState[di-33],9
	jne n17
	inc mineState[di]
  n17:
	cmp mineState[di-32],9
	jne n18
	inc mineState[di]
  n18:
	cmp mineState[di-1],9
	jne n19
	inc mineState[di]
  n19:
	cmp mineState[di+31],9
	jne n20
	inc mineState[di]
  n20:
	cmp mineState[di+32],9
	jne n21
	inc mineState[di]
  n21:
	add di,32
	cmp di,735
	jbe startC63to735
	mov di,33
startM33to734:
	cmp mineState[di],9
	jae n29
	cmp mineState[di-33],9
	jne n22
	inc mineState[di]
  n22:
	cmp mineState[di-32],9
	jne n23
	inc mineState[di]
  n23:
	cmp mineState[di-31],9
	jne n24
	inc mineState[di]
  n24:
	cmp mineState[di-1],9
	jne n25
	inc mineState[di]
  n25:
	cmp mineState[di+1],9
	jne n26
	inc mineState[di]
  n26:
	cmp mineState[di+31],9
	jne n27
	inc mineState[di]
  n27:
	cmp mineState[di+32],9
	jne n28
	inc mineState[di]
  n28:
	cmp mineState[di+33],9
	jne n29
	inc mineState[di]
  n29:
	inc di
	cmp di,735
	je n30
	mov ax,di
	mov bl,32
	div bl
	cmp ah,31
	je nextL
	jmp startM33to734
  nextL:
	add di,2
	jmp startM33to734
  n30:
	mov di,736
start736:
	cmp mineState[di],9
	jae n33
	cmp mineState[di-32],9
	jne n31
	inc mineState[di]
  n31:
	cmp mineState[di-31],9
	jne n32
	inc mineState[di]
  n32:
	cmp mineState[di+1],9
	jne n33
	inc mineState[di]
  n33:
	inc di
start737to766:
	cmp mineState[di],9
	jae n38
	cmp mineState[di-33],9
	jne n34
	inc mineState[di]
  n34:
	cmp mineState[di-32],9
	jne n35
	inc mineState[di]
  n35:
	cmp mineState[di-31],9
	jne n36
	inc mineState[di]
  n36:
	cmp mineState[di-1],9
	jne n37
	inc mineState[di]
  n37:
	cmp mineState[di+1],9
	jne n38
	inc mineState[di]
  n38:
	inc di
	cmp di,766
	jbe start737to766
start767:
	cmp mineState[di],9
	jae calculateDone
	cmp mineState[di-33],9
	jne n39
	inc mineState[di]
  n39:
	cmp mineState[di-32],9
	jne n40
	inc mineState[di]
  n40:
	cmp mineState[di-1],9
	jne calculateDone
	inc mineState[di]
calculateDone:
	ret
calculate endp

;�Ƶ{�� �Y���}���Ů�A�I�}�Ҧ��۾F���Ů檽�즳�Ʀr
check proc near
again:
	mov di,0
	mov checkCount,0
checkRight:
	cmp BlockState[di],1
	jne c1
	cmp mineState[di],0
	jne c1
	cmp BlockState[di+1],0
	jne c1
	mov BlockState[di+1],1
	mov checkCount,1
  c1:
	inc di
	cmp di,767
	je c2
	mov ax,di
	mov bl,32
	div bl
	cmp ah,31
	jne checkRight
	inc di
	jmp checkRight
  c2:
	mov di,1
checkLeft:
	cmp BlockState[di],1
	jne c3
	cmp mineState[di],0
	jne c3
	cmp BlockState[di-1],0
	jne c3
	mov BlockState[di-1],1
	mov checkCount,1
  c3:
	inc di
	cmp di,768
	je c4
	mov ax,di
	mov bl,32
	div bl
	cmp ah,0
	jne checkLeft
	inc di
	jmp checkLeft
  c4:
	mov di,0
checkDown:
	cmp BlockState[di],1
	jne c5
	cmp mineState[di],0
	jne c5
	cmp BlockState[di+32],0
	jne c5
	mov BlockState[di+32],1
	mov checkCount,1
  c5:
	inc di
	cmp di,736
	je c6
	jmp checkDown
  c6:
	mov di,32
checkUp:
	cmp BlockState[di],1
	jne c7
	cmp mineState[di],0
	jne c7
	cmp BlockState[di-32],0
	jne c7
	mov BlockState[di-32],1
	mov checkCount,1
  c7:
	inc di
	cmp di,768
	je c8
	jmp checkUp
  c8:
	cmp checkCount,1
	je c8_again
	ret
  c8_again:
    jmp again
check endp

;�Ƶ{�� �ˬd�O�_�q���A�Y�q����ܳq���e��(+3 ���Ϥ�)
checkWin proc
	mov di,0
checkw:
	cmp BlockState[di],0		;�Y BlockState[di]!=0 �N����w1
	jne w1
	cmp mineState[di],9		;�YmineState[di]!=9 �N����w2
	jne w2
  w1:
	inc di
	cmp di,768				;�Ydi=768�N����w3
	je w3
	jmp checkw				;�_�h��������checkw
  w2:
	ret
  w3:
	;��sTime
	xor ax,ax				;�k�s
	mov al,score[0]
	mov bl,10
	div bl
	add ah,30h
	add al,30h
	mov WinMessage9[23],ah
	mov WinMessage9[22],al
	xor ax,ax
	mov al,score[1]
	mov bl,10
	div bl
	add ah,30h
	add al,30h
	mov WinMessage9[25],ah
	mov WinMessage9[24],al
	xor ax,ax
	mov al,score[2]
	mov bl,10
	div bl
	add ah,30h
	add al,30h
	mov WinMessage9[27],ah
	mov WinMessage9[26],al

	;ø�s��Ӫ�dialog
	SET_CUR 11,17
	lea dx,WinMessage1
	mov ah,09h
	int 21h
	SET_CUR 12,17
	lea dx,WinMessage2
	mov ah,09h
	int 21h
	SET_CUR 13,17
	lea dx,WinMessage3
	mov ah,09h
	int 21h
	SET_CUR 14,17
	lea dx,WinMessage4
	mov ah,09h
	int 21h
	SET_CUR 15,17
	lea dx,WinMessage5
	mov ah,09h
	int 21h
	SET_CUR 16,17
	lea dx,WinMessage6
	mov ah,09h
	int 21h
	SET_CUR 17,17
	lea dx,WinMessage7
	mov ah,09h
	int 21h
	SET_CUR 18,17
	lea dx,WinMessage8
	mov ah,09h
	int 21h
	SET_CUR 19,17
	lea dx,WinMessage9
	mov ah,09h
	int 21h
	SET_CUR 20,17
	lea dx,WinMessage10
	mov ah,09h
	int 21h
	;�o�g�Ϥ�
	call firework
	call firework
	call firework
	call reset
	mov ah,07h
	int 21h
	;�^���
	call main
checkWin endp

;�Ƶ{�� �C�����ѫ���ܥ����a�p
runLose proc
	mov di,0
  L1:
	cmp mineState[di],9
	jne L2
	mov BlockState[di],1
  L2:
	inc di
	cmp di,768
	jne L1
	mov row,0
	mov col,0
	call scanMap
	ret
runLose endp

;�Ƶ{�� ���m�C���Ѽ�
reset proc
	mov cheat,0 			;��@���X���\�����k�s
	mov row,0				;����k�s
	mov col,0				;��C�k�s
	mov isStart,0
	mov difficulty,0			;�������k�s
	mov position[0],0			;���m���k�s
	mov position[1],0			;���m�C�k�s
	mov ax,ds				;��ax�k�s
	mov es,ax				;��es�k�s
	mov di,offset BlockState	;�NBlockState����}���J�ت��a�H�s��di��
	cld
	xor al,al				;��al�k�s
	mov cx,768				;��cx�k�s
	rep stosb

	mov ax,ds				;��al�k�s
	mov es,ax				;��es�k�s
	mov di,offset mineState		;�NmineState����}���J�ت��a�H�s��di��
	cld
	xor al,al				;��al�k�s
	mov cx,768				;��cx�k�s
	rep stosb
	ret
reset endp

;�Ƶ{�� �H���ͦ��a�p(�����Ĥ@���I�}�����)
setmine proc
	mov cx,mineNumber			;cx = mineNumber
mineSet:
	push cx				;�j��p�ƾ�,�T�Ocx���|�Q�ק�
   	mov ah, 2Ch				;�եΨt�ήɶ����\��
    	int 21h
    	mov bx, dx				;����ɶ��s��bx
    	in ax,40h				;�q40hŪ��,��bax(0~255)
    	mul bx				;�W�[��h�ܤƩ�

	xor dx,dx				;dx�k�s
	mov bx,768				;bx=768
	div bx				;ax���Ȱ��Hbx,�ө�bax,�l�Ʃ�bdx
	mov di,dx				;dx(�l��)���ȩ��di
    	pop cx				;�j��p�ƾ�,�T�Ocx���|�Q�ק�

	cmp BlockState[di],0		;�p�G����0 �X��
	jne mineskip
	cmp mineState[di],9		;����9 ���u
	je mineskip
	cmp mineState[di],99		;����99 �_�l�I
	je mineskip
	mov mineState[di],9		;�񬵼u
	
	loop mineSet
  mineskip:
	inc cx				;cx++
	loop mineSet			;�^mineSet
	mov di,firstBlock
	mov mineState[di],0
	ret
SetMine endp

;�Ƶ{�� �����ܭ���
selectSound proc
	mov di,200
setFreq:
	cmp soundtimes,3
	je exSound
	inc soundtimes
	mov si,0
	mov al, 0b6H
    	out 43h, al
    	mov dx, 12h
    	mov ax, 348ch
    	div di
    	out 42h, al

    	mov al, ah
    	out 42h, al
SL1:
	in al, 61h
    	mov ah, al
    	or al, 3
    	out 61h, al

	cmp si,0fffh
	je SL2
	inc si
	jmp SL1
SL2:
	mov di,230
	jmp setFreq
exSound:
	in al, 61h
	and al,0fch
	out 61h,al
	mov soundtimes,0
	ret
selectSound endp

;�Ƶ{�� �ͦ��Ϥ��έ���
firework proc
	mov di,2000
	in ax,40h
	mov bx,500
	mov dx,0
	div bx
	mov row,dx
	in ax,40h
	mov bx,360
	mov dx,0
	div bx
	mov col,dx
fireworkL:
	cmp soundtimes,400
	je exFirework_jmp
	inc soundtimes
	mov al, 0b6H
    	out 43h, al
    	mov dx, 12h
    	mov ax, 348ch
    	div di
    	out 42h, al

    	mov al, ah
    	out 42h, al
FL1:
	in al, 61h
    	mov ah, al
    	or al, 3
    	out 61h, al

	cmp si,0ffh
	je FL2
	inc si
	jmp FL1
FL2:
	mov si,0
	cmp soundtimes,360
	je bom
	dec di
	jmp fireworkL
exFirework_jmp:
    jmp exFirework
bom:
	mov si,0
	mov di,0
	mov bomCount,0
	mov bp,0
  bomLoop:
	mov cx,row
	mov dx,col
	add cx,fireworkRow[di]
	add dx,fireworkCol[di]
  bomLoop1:
	WrPixel cx,dx,fireworkBitmap[bp]
	inc si
	inc cx
	cmp si,4
	jb bomLoop1
	cmp bomCount,3
	je bomLoop2
	inc bomCount
	inc dx
	sub cx,4
	mov si,0
	jmp bomLoop1
bomLoop2:
	add di,2
	mov si,0
	inc bp
	mov bomCount,0
	cmp fireworkBitmap[bp],100
	je bomSound
	jmp bomLoop
bomSound:
	mov di,250
	je fireworkL_jmp
fireworkL_jmp:
    jmp fireworkL

exFirework:
	in al, 61h
	and al,0fch
	out 61h,al
	mov soundtimes,0
	mov cx,0002h
Fdelay1:
	mov bp,09000h
Fdelay2:
	dec bp
	cmp bp,0
	jnz Fdelay2
	Loop Fdelay1
	ret
firework endp

;�Ƶ{�� ��ܶ}�l�e�����a�p�y��
showChange proc
	mov row,310
	mov col,270
	mov di,0
	mov mineState[0],9
	call printSelect
	mov mineState[0],0
	mov di,0
	mov row,0
	mov col,0
	ret
showChange endp

;�Ƶ{�� ���X����
setFlagSound proc
	mov di,500
setFFreq:
	cmp soundtimes,3
	je exFSound
	inc soundtimes
	mov si,0
	mov al, 0b6H
    	out 43h, al
   	mov dx, 12h
    	mov ax, 348ch
    	div di
    	out 42h, al

    	mov al, ah
    	out 42h, al
SFL1:
	in al, 61h
    	mov ah, al
    	or al, 3
    	out 61h, al

	cmp si,0fffh
	je SFL2
	inc si
	jmp SFL1
SFL2:
	mov di,530
	jmp setFFreq
exFSound:
	in al, 61h
	and al,0fch
	out 61h,al
	mov soundtimes,0
	ret
setFlagSound endp

;�Ƶ{�� �������X����
resetFlagSound proc
	mov di,530
resetFFreq:
	cmp soundtimes,3
	je exRFSound
	inc soundtimes
	mov si,0
	mov al, 0b6H
    	out 43h, al
    	mov dx, 12h
   	 mov ax, 348ch
    	div di
    	out 42h, al

    	mov al, ah
    	out 42h, al
RFL1:
	in al, 61h
    	mov ah, al
    	or al, 3
    	out 61h, al

	cmp si,0fffh
	je RFL2
	inc si
	jmp RFL1
RFL2:
	mov di,500
	jmp resetFFreq
exRFSound:
	in al, 61h
	and al,0fch
	out 61h,al
	mov soundtimes,0
	ret
resetFlagSound endp

;�Ƶ{�� �a�p�z������
bombSound proc
	mov di,130
bombFreq:
	mov si,0
	mov al, 0b6H
    	out 43h, al
    	mov dx, 12h
    	mov ax, 348ch
    	div di
    	out 42h, al

    	mov al, ah
    	out 42h, al
BL1:
	in al, 61h
    mov ah, al
    or al, 3
    out 61h, al

	in al, 61h
	and al,0fch
	out 61h,al

	cmp si,0fffh
	je exBSound
	inc si
	jmp BL1
exBSound:
	ret
bombSound endp

;�Ƶ{�� �C�����ѭ���
loseSound proc
	mov di,200
loseFreq:
	cmp soundtimes,5
	je exLSound
	inc soundtimes
	mov si,0
	mov al, 0b6H
    	out 43h, al
    	mov dx, 12h
    	mov ax, 348ch
    	div di
    	out 42h, al

    	mov al, ah
    	out 42h, al
LL1:
	in al, 61h
    	mov ah, al
    	or al, 3
    	out 61h, al

	cmp si,03200h
	je LL2
	inc si
	jmp LL1
LL2:
	sub di,15
	jmp loseFreq
exLSound:
	in al, 61h
	and al,0fch
	out 61h,al
	mov soundtimes,0
	ret
loseSound endp

code	ends
	end     start

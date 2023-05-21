;調用DOS服務來等待鍵盤輸入
GetChar macro Char
	mov ah,06h			;從標準輸入裝置（通常是鍵盤）讀取一個字符
	mov dl,0ffh			;將該字符的 ASCII 值放入 DL
	int 21h
	mov Char,al
endm

;將0存儲到ah中，表示要調用BIOS中斷功能00h，設定顯示模式
;將"mode"存儲到al中，表示要設置的具體顯示模式
;調用int 10h中斷，將設置的顯示模式應用於顯示器上
SetMode macro mode		;設定顯示模式
	mov ah,00h
	mov al,mode
	int 10h
endm

;INT 10h、AH=0Bh : 設定邊界顏色
SetColor macro mode,color	;設置文字顏色
	mov ah,0bh
	mov bh,mode			;指定所需的顯示頁面
	mov bl,color		;表示所需的文字顏色
	int 10h
endm

;INT 10h、AH = 0Ch : 設定單個像素的顏色
WrPixel macro row,col,color
	mov ah,0ch
	mov bh,00h			;頁面號碼 (0-7)
	mov al,color		;顏色碼 (0-15)
	mov cx,row			;列號 (0-199)
	mov dx,col			;行號 (0-319)
	int 10h
endm

SET_CUR macro Row,Col  		;將屏幕上的所在格標記移動到指定的行和列位置
	mov dh,Row
	mov dl,Col
	mov bx,0000h
	mov ah,02h
	int 10h
endm

data segment

getc 		db 	0	;輸入字符
cheat 	db 	0	;作弊碼成功長度

difficulty 	db 	0	;遊戲難度(1:簡單 2:普通 3:困難)

;0:沒有被打開 ,1:無雷區 ,2:插旗區 ,10:地雷區
BlockState 	db 	768 dup(0)	;遊戲方塊(最大24*32)
;0～8:附近地雷數 ,9:炸彈 ,10: 界外,99:起始點 
mineState 	db 	768 dup(0)

mineCount	db	0	;計算地雷數
mineNumber 	dw 	0	;地雷總數

bomCount 	db 	0
soundtimes 	dw 	0
firstBlock 	dw 	0
position 	db 	0,0,0  ;col row
BlockWide 	dw 	20
checkCount 	dw 	0
isStart 	db 	0
;小時ch,分cl,秒dh,毫秒dl
timeCount 	dw 	0	;時間計數
timeCount1 	db 	0

scanCount 	dw 	0	;計算掃描數

row 		dw 	0	;行
col 		dw 	0	;列

RowCounter 	dw 	0	;行計數
ColCounter 	dw 	0	;列計數

;邊界(每隔20)
XLimit	dw	640	;32格,col
YLimit	dw	480	;24格,row

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

;10,13 代表回車.換行的ASCII碼
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

;定義一個方塊(20*20)的圖案 用於在遊戲畫面上顯示
;數字圖示(0~9)
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

;邊界方塊圖示
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

;方塊圖示
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

;旗幟圖示
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

;地雷圖示
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
;煙火圖示
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
	; 偽指令，告訴組譯器代碼段的對應
    	assume cs:code, ds:data
	org     100h
main proc
start:
	mov ax, data	; 將 data 的地址放到 ax 暫存器
   	mov ds, ax		; 將 ax 的值放到 ds 暫存器

	Setmode 12h		;要將顯示器設置為80x25的文本模式
	SetColor 00h,00h
	SET_CUR 3,0
	mov ah,09h
	lea dx,mineSweeper
	int 21h
	call showChange
readStart:
	mov ah,07h	;從標準輸入設備讀取一個字符
	int 21h
	cmp al,'e'
	je exit	;離開遊戲頁面
	cmp al,'1'
	je easy   	;簡單模式
	cmp al,'2'
	je normal	;普通模式
	cmp al,'3'
	je hard	;困難模式

	cmp al,'c'
	je changeMine	;切換炸彈樣式
	jmp readStart

exit:
	SetMode 03h		;顯示模式為文本模式
    	mov ax, 4c00h	;退出程式 設置結束功能
  	int 21h		;調用系統功能

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
	inc mineCount		;增加地雷數量計數器
	cmp mineCount,0   	;如果mineCount=0
	je setBombBitmap  	;跳到setbombitmap
	cmp mineCount,1	  	;如果mineCount=1
	je setFlowerBitmap	;跳到setFlowerBitmap
	cmp mineCount,2	  	;如果mineCount=2
	je setDiHongBitmap	;跳到setDiHong
	mov mineCount,0	  	;如果mineCount>2,重置回0
	jmp setBombBitmap 	;跳到setbombitmap
  setDiHongBitmap:
	mov ax,ds
	mov es,ax
	mov si,offset dihongBitmap    ;將si設置為dihongBitmap 圖像的偏移量
	mov di,offset selectedBitmap9 ;將di設置為selectedBitmap9 圖像的偏移量
	mov cx,400 				;設置計數器
	rep movsb 				;將數據從si搬移到di 並減少cx直到0
	call showChange
	jmp readStart
  setBombBitmap:
	mov ax,ds
	mov es,ax
	mov si,offset bombBitmap	;將si設置為bombBitmap 圖像的偏移量
	mov di,offset selectedBitmap9	;將si設置為selectedBitmap9 圖像的偏移量
	mov cx,400
	rep movsb				;將數據從si搬移到di 並減少cx直到0
	call showChange
	jmp readStart
  setFlowerBitmap:
	mov ax,ds
	mov es,ax
	mov si,offset flowerBitmap	;將指向花朵位圖數據的指針載入 SI 中
	mov di,offset selectedBitmap9 ;指向顯示緩存區的指針載入 DI 中
	mov cx,400				;設置計數器
	rep movsb				;將數據從si搬移到di 並減少cx直到0
	call showChange
	jmp readStart

afterSelect:
	mov bp,0
	call scanMap

Flash:
	call printChoose		;調用printChoose 列印選擇紅框
	call checkWin		;調用checkWin 判斷勝利條件
readin:
	GetChar getc		;從鍵盤輸入中獲取一個字符
	inc timeCount		;timeCount +1
	cmp timeCount,0ffffh	;如果timeCount達到0ffffh(65536)
	jne notCarry		;沒達到 跳到notCarry
	mov timeCount,0		;達到 將timeCount歸零
	inc timeCount1		;並將timeCount1 +1
	cmp timeCount1,00fh	;如果timeCount達到00fh
	jne notCarry		;沒達到 跳到notCarry
	inc score[2]		;達到 score[2] +1
	mov timeCount1,0		;並將timeCount1歸零
	cmp score[2],100		;如果score[2]達到100
	jne notCarry		;沒達到 跳到notCarry
	mov score[2],0		;達到則將score[2]歸零
	inc score[1]		;並將score[1]+1
	cmp score[1],100		;如果score[1]達到100
	jne notCarry		;沒達到 跳到notCarry
	mov score[1],0		;達到則將score[1]歸零
	inc score[0]		;並將score[0]+1
  notCarry:
	cmp getc,'w'
	je up				;跳到up 判斷"上"的動作
	cmp getc,'d'
	je right			;跳到right 判斷"右"的動作
	cmp getc,'a'
	je left			;跳到left 判斷"左"的動作
	cmp getc,'s'
	je down			;跳到down 判斷"下"的動作
	cmp getc,'j'
	je select_jmp		;跳到select 判斷"按下"動作
	cmp getc,'k'
	je setFlag_jmp		;跳到setFlag 判斷"設旗"動作
	;作弊攻略 方法判斷
	;上上下下左右左右ba
	cmp getc,72			;上方向鍵
	je cheatUp			;跳到cheatUp 判斷作弊碼
	cmp getc,77			;右方向鍵
	je cheatRight		;跳到cheatRight 判斷作弊碼
	cmp getc,75			;左方向鍵
	je cheatLeft		;跳到cheatLeft 判斷作弊碼
	cmp getc,80			;下方向鍵
	je cheatDown		;跳到cheatDown 判斷作弊碼
	cmp getc,'b'		;'b'
	je cheatB			;跳到cheatB 判斷作弊碼
	jmp readin			;跳到readin 重新輸入
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
	cmp cheat,9			;當作弊碼成功長度到9 成功按下最後一碼'a'
	je setCheat			;是 跳到setCheat
	mov cheat,0			;作弊碼歸零
	call reChoose		;調用reChoose 清除原位置紅框
	cmp position[0],0		;如果在最左邊
	je LLimit			;是 跳到LLimit
	dec position[0]		;行數-1
	jmp chooseLeft		;跳到"往左走"動作
  LLimit:
	mov position[0],31	;從最左邊走到最右邊
  chooseLeft:
	xor ax,ax			;將ax歸零
	mov al,20
	mul position[0]		;mul指令會將al的值和position[0]的值相乘 將結果存儲在ax
	mov row,ax
	jmp Flash			;跳至Flash 顯示選取紅框

cheatUp:
    call cheatUp_PROC
    jmp readin			;然後跳到readin
cheatDown:
    call cheatDown_PROC
    jmp readin			;然後跳到readin
cheatLeft:
    call cheatLeft_PROC
    jmp readin			;然後跳到readin
cheatRight:
    call cheatRight_PROC
    jmp readin			;然後跳到readin
cheatB:
    call cheatB_PROC
    jmp readin			;然後跳到readin
setCheat:
	mov di,0 			;將di設為0
  openCheat:
	cmp mineState[di],9 	;比較ineState[di]和9是否相等
	je cheatNext        	;如果相等 跳到cheatNext
	mov BlockState[di],1	;BlockState[di]設為1
  cheatNext:
	inc di 			;di+1
	cmp di,768 			;比較di是否=768
	jne openCheat 		;di!=768就跳到openCheat
	mov row,0 			;如果檢查完了所有區塊，將 row 和 col 設為 0
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
	xor ax,ax 				;將ax清0
	mov al,32 				;將 al 設為 32，用來計算索引位置
	mul position[2] ;將al乘y座標
	add ax,word ptr position[0]	;加上x座標 (將position[0]加到ax中後，可以計算出相應區塊在 BlockState的索引位置。)
	mov di,ax 				;把結果放到di
	cmp BlockState[di],0 		;判斷這個位置有沒有被打開
	jne notSet 				;如果已經被翻開或插旗，跳到 notSet 標籤
	mov BlockState[di],2 		;把這個位置設定為插旗狀態
	call reChoose
	call setFlagSound  		;播放插旗音效
	jmp Flash ;
  notSet:
	cmp BlockState[di],2 		;判斷有沒有插旗子
	jne Flash_jmp2 			;如果不是跳到flash
	mov BlockState[di],0 		;取消旗子
	call reChoose
	call resetFlagSound 		;播放取消插旗音效
	jmp Flash
Flash_jmp2:
    jmp Flash
main endp

;簡單模式(8*8)
easy_PROC proc
    mov mineNumber,10			;10顆地雷
    mov di,0
Le1:
	mov ax,di
	mov bl,32				;總行數(24*32)
	div bl				;目的是計算行號和列號 ax=(row)
	cmp ah,8				;是不是8行
	jae Le2
	cmp al,8				;是不是8列
	jae Le2
	inc di
	cmp di,768				;檢查總共是不是768格(24*32)
	je Le3				;是768格 地圖已處理完畢
	jmp Le1
Le2:
	mov BlockState[di],1
	mov mineState[di],10
	inc di
	cmp di,768				;檢查總共是不是768格(24*32)
	je Le3				;是768格 地圖已處理完畢
	jmp Le1
Le3:
	mov di,0
	mov difficulty,1
	ret
easy_PROC endp

;普通模式
normal_PROC proc
    mov mineNumber,40			;40顆地雷
    mov di,0
Ln1:
	mov ax,di
	mov bl,32				;總行數(24*32)
	div bl				;目的是計算行號和列號 ax=(row)
	cmp ah,16				;是不是16行
	jae Ln2
	cmp al,16				;是不是16列
	jae Ln2
	inc di				;紀錄已處理個格數
	cmp di,768				;檢查全部768格(24*32)是不是都處理了
	je Ln3				;是768格 地圖已處理完畢
	jmp Ln1
Ln2:
	mov BlockState[di],1		;標記此位置是沒地雷
	mov mineState[di],10		;標記此位置是地雷
	inc di
	cmp di,768				;檢查總共是不是768格(24*32)
	je Ln3				;是768格 地圖已處理完畢
	jmp Ln1
Ln3:
	mov di,0
	mov difficulty,2
	ret
normal_PROC endp

;困難模式
hard_PROC proc
    mov mineNumber,120			;120顆地雷
    ret
hard_PROC endp

;判斷按下'w'
up_PROC proc
	mov cheat,0				;作弊碼歸零
	call reChoose			;調用reChoose 清除原位置紅框
	cmp position[2],0			;如果在最上層
	je top				;是 跳到top
	dec position[2]			;列數-1
	jmp chooseUp			;跳到"往上走"動作
top:
	mov position[2],23 		;從最上層走到最下層
chooseUp:
	xor ax,ax 				;將ax歸零
	mov al,20
	mul position[2]			;mul指令會將al的值和position[2]的值相乘 將結果存儲在ax
	mov col,ax
	ret
up_PROC endp

;判斷按下'd'
right_PROC proc
	mov cheat,0				;作弊碼歸零
	call reChoose			;調用reChoose 清除原位置紅框
	cmp position[0],31		;如果在最右邊(24*32)
	je RLimit				;是 跳到RLimit
	inc position[0]			;行數+1
	jmp chooseRight			;跳到"往右走"動作
RLimit:
	mov position[0],0			;從最右層到最左層
chooseRight:
	xor ax,ax				;將ax歸零
	mov al,20
	mul position[0]			;mul指令會將al的值和position[0]的值相乘 將結果存儲在ax
	mov row,ax
	ret
right_PROC endp

;判斷按下's'
down_PROC proc
	mov cheat,0				;作弊碼歸零
	call reChoose			;調用reChoose 清除原位置紅框
	cmp position[2],23		;如果在最下層(24*32)
	je bottom				;是 跳到bottom
	inc position[2]			;列數+1
	jmp chooseDown			;跳到"往下走"動作
bottom:
	mov position[2],0			;從最底下走到最上層
chooseDown:
	xor ax,ax				;將ax歸零
	mov al,20
	mul position[2]			;mul指令會將al的值和position[2]的值相乘 將結果存儲在ax
	mov col,ax
	ret
down_PROC endp

;判斷按下'上'
cheatUp_PROC proc
    cmp cheat,2   			;比較cheat和2
	jae exit_cheatUp			;如果cheat>=2跳到resetCheat
	inc cheat 				;cheat+1
	ret
exit_cheatUp:
    call resetCheat_PROC
    ret
cheatUp_PROC endp

;判斷按下'下'
cheatDown_PROC proc
	cmp cheat,2 			;比較cheat和2
	jb exit_cheatDown			;如果cheat<2則跳到resetCheat
	cmp cheat,4 			;比較cheat 4
	jae exit_cheatDown		;如果cheat>=4跳到resetCheat
	inc cheat  				;cheat+1
	ret
exit_cheatDown:
    call resetCheat_PROC
    ret
cheatDown_PROC endp

;判斷按下'左'
cheatLeft_PROC proc
	cmp cheat,4 			;比較cheat和4
	jne cheatL2 			;不相等則跳到cheatL2
	inc cheat   			;cheat+1
	ret
  cheatL2:
	cmp cheat,6 			;比較cheat和6
	jne exit_cheatLeft 		;不相等則跳到resetCheat
	inc cheat   			;cheat+1
	ret
exit_cheatLeft:
    call resetCheat_PROC
    ret
cheatLeft_PROC endp

;判斷按下'右'
cheatRight_PROC proc
	cmp cheat,5 			;比較cheat和5
	jne cheatR2 			;不相等則跳到cheatR2
	inc cheat   			;cheat+1
	ret
  cheatR2:
	cmp cheat,7 			;比較cheat和7
	jne exit_cheatRight 		;不相等則跳到resetCheat
	inc cheat 				;cheat+1
	ret
exit_cheatRight:
    	call resetCheat_PROC
    	ret
cheatRight_PROC endp

cheatB_PROC proc
	cmp cheat,8 			;比較cheat和8
	jne exit_cheatB  			;不相等則跳到resetCheat
	inc cheat 				;cheat+1
	ret
exit_cheatB:
    	call resetCheat_PROC
    	ret
cheatB_PROC endp

resetCheat_PROC proc
	mov cheat,0 			;將cheat設為0
	ret
resetCheat_PROC endp

;副程式 列印方塊副程式(尚未打開)
printblock proc near
	cmp BlockState[di],2		;比較 BlockState[di] 是否為 2，判斷有沒有旗子
	jne notFlag				;如果沒旗子，則跳到 notFlag
	mov bp,400				;如果有旗子,將bp設成400,要印旗子的圖案
notFlag:
	mov di,0				;di=0
	add di,bp				;di+bp 決定要印的圖案
	mov cx,row
	mov dx,col
	mov RowCounter,0
	mov ColCounter,0
PRow:
	WrPixel cx,dx,BlockBitmap[di]	;di+bp 決定要印的圖案
	inc cx				;cx+1
	inc di				;di+1  指向下一個要印的圖案
	inc RowCounter
	mov si,RowCounter
	cmp si,20				;判斷是否已印完一行(row)，如果是就跳到 over
	je over
	jmp PRow				;如果還沒印完一行(row)，就繼續印
over:
	mov cx,row
	inc dx				;dx+1 指向下一列(col)
	inc ColCounter
	mov si,ColCounter
	mov RowCounter,0
	cmp si,20				;判斷是否已印完一列(col)，如果是就跳到done
	je done
	jmp PRow				;如果還沒印完一列(col)，就繼續印
done:
	mov bp,0
	ret					;返回呼叫procedure(return)
printblock endp

;副程式 更新遊戲畫面
;遍歷'BlockState'陣列並打印相應方塊
scanMap proc near
	mov di,0				;'BlockState'陣列index
	mov scanCount,0			;遍歷計數器
initial:
	mov di,scanCount
	cmp BlockState[di],1
    	je Show				;如果BlockState[di]等於1 跳到show
	call printblock			;調用printblock 打印方塊
	jmp change				;跳到change
show:
	call printSelect			;調用printSelect 打印選擇方塊
change:
	inc scanCount			;scanCount+=1
	add row,20				;row+=20
	mov ax,XLimit			;XLimit = 640(32*20)
	cmp row,ax				;檢查是否遍歷完當前列的所有方塊
	je NextCol				;是 跳到NextCol
	jmp initial				;跳到initial
NextCol:
	mov row,0				;row從頭重新開始
	add col,20				;col+=20
	mov ax,YLimit			;YLimit = 480(24*20)
	add ax,20				;480+20=500(超出界線)
	cmp col,ax				;檢查是否遍歷完所有方塊
	je initialDone			;是 跳到initialDone
	jmp initial				;跳到initial
initialDone:
	mov row,0				;row歸零
	mov col,0				;col歸零
	mov di,0				;di歸零
	ret					;返回
scanMap endp

;副程式 列印選擇紅框
printChoose proc near
	mov cx,row				;行
	mov dx,col				;列
	mov RowCounter,0			;清空行計數器
	mov ColCounter,0			;清空列計數器
PRowCUp:					;在選擇框上半部分的第一行像素的顯示
	WrPixel cx,dx,04h 		;在指定位置印出像素
	inc cx				;row+1
	inc RowCounter			;RowCounter+1
	mov si,RowCounter 		;si=RowCounter
	cmp si,20				;row=20時，跳到overCUp
	je overCUp
	jmp PRowCUp				;迴圈
overCup:					;選擇框上半部分的最後一行
	mov cx,row
	inc dx				;col+1
	inc ColCounter			;ColCounter+1
	mov si,ColCounter			;si=RowCounter
	mov RowCounter,0			;RowCounter歸零
	cmp si,2				;RowCounter=2時，繪製上半部完成
	je doneCUp
	jmp PRowCUp
doneCUp:					;選擇框上半部分繪製完成
	mov cx,row
	mov RowCounter,0
	mov ColCounter,0
PRowCMid1:					;中間部分的第一行
	WrPixel cx,dx,04h			;在指定位置印出像素
	inc cx				;row+1
	inc RowCounter			;RowCounter+1
	mov si,RowCounter 		;si=RowCounter
	cmp si,2				;RowCounter=2時，跳到overCMid1
	je overCMid1
	jmp PRowCMid1			;迴圈
overCMid1:					;中間部分的最後一行
	add cx,15				;row+15
	WrPixel cx,dx,04h 		;在指定位置印出像素
	inc cx				;row+1
	inc RowCounter			;RowCounter+1
	mov si,RowCounter			;si=RowCounter
	cmp si,4				;RowCounter=4時，跳到overCMid2
	je overCMid2
	sub cx,15				;row-15
	jmp overCMid1			;迴圈
overCMid2:					;中間下半部分的第一行
	mov cx,row
	inc dx				;col+1
	mov RowCounter,0			;RowCounter歸零
	inc ColCounter			;ColCounter+1
	mov si,ColCounter 		;si=ColCounter
	cmp si,16				;ColCounter=16時，繪製中間下半部分完成
	je doneCMid
	jmp PRowCMid1
doneCMid:					;中間部分繪製完成
	mov cx,row
	mov RowCounter,0
	mov ColCounter,0
PRowCBot:					;在選擇框底部的第一行像素的顯示
	WrPixel cx,dx,04h 		;在指定位置印出像素
	inc cx				;row+1
	inc RowCounter			;RowCounter+1
	mov si,RowCounter 		;si=RowCounter
	cmp si,20				;RowCounter=20時，跳到overCBot
	je overCBot
	jmp PRowCBot			;迴圈
overCBot:					;下面部分的最後一行
	mov cx,row
	inc dx				;col+1
	inc ColCounter			;ColCounter+1
	mov si,ColCounter			;si=ColCounter
	mov RowCounter,0			;RowCounter歸零
	cmp si,2				;ColCounter=2時，繪製下面部分完成
	je doneC
	jmp PRowCBot
doneC:					;選擇框繪製完成，並返回。
	ret
printChoose endp

;副程式 清除原位置紅框
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

;副程式 列印方塊(已打開的內容)
;印出遊戲中選中的格子
printSelect proc near
	xor ax,ax				;將ax設為0
	mov al,mineState[di]		;取出mineState對應格子的狀態 放入al
	mov bx,400				;格子大小(20*20)
	mul bx				;ax*=bx
	mov di,ax				;將ax設定為selectedBitmap0陣列中對應格子的起始位置
	mov cx,row				;當前格子的列
	mov dx,col				;當前格子的行
	mov RowCounter,0
	mov ColCounter,0
PRowS:
	WrPixel cx,dx,selectedBitmap0[di]
	inc cx				;要印出的行數+1
	inc di				;要印出的資料索引+1
	inc RowCounter			;計算印出的像素數量
	mov si,RowCounter
	cmp si,20				;判斷是否已經印出一整行的像素
	je overS				;是 跳到overS
	jmp PRowS				;跳到PRowS 繼續印下一個
overS:
	mov cx,row				;row=0 從頭重新開始
	inc dx				;列數+1
	inc ColCounter			;計算列數數量
	mov si,ColCounter
	mov RowCounter,0
	cmp si,20				;判斷是否超出20列
	je doneS				;是 完成列印格子
	jmp PRowS				;跳到PRowS 繼續印下一行起始位置的
doneS:
	ret					;返回
printSelect endp

;副程式 計算方格顯示的數字
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

;副程式 若打開為空格，點開所有相鄰的空格直到有數字
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

;副程式 檢查是否通關，若通關顯示通關畫面(+3 顆煙火)
checkWin proc
	mov di,0
checkw:
	cmp BlockState[di],0		;若 BlockState[di]!=0 就跳到w1
	jne w1
	cmp mineState[di],9		;若mineState[di]!=9 就跳到w2
	jne w2
  w1:
	inc di
	cmp di,768				;若di=768就跳到w3
	je w3
	jmp checkw				;否則直接跳到checkw
  w2:
	ret
  w3:
	;更新Time
	xor ax,ax				;歸零
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

	;繪製獲勝的dialog
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
	;發射煙火
	call firework
	call firework
	call firework
	call reset
	mov ah,07h
	int 21h
	;回選單
	call main
checkWin endp

;副程式 遊戲失敗後顯示全部地雷
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

;副程式 重置遊戲參數
reset proc
	mov cheat,0 			;把作弊碼成功長度歸零
	mov row,0				;把行歸零
	mov col,0				;把列歸零
	mov isStart,0
	mov difficulty,0			;把難度歸零
	mov position[0],0			;把位置行歸零
	mov position[1],0			;把位置列歸零
	mov ax,ds				;把ax歸零
	mov es,ax				;把es歸零
	mov di,offset BlockState	;將BlockState的位址載入目的地寄存器di中
	cld
	xor al,al				;把al歸零
	mov cx,768				;把cx歸零
	rep stosb

	mov ax,ds				;把al歸零
	mov es,ax				;把es歸零
	mov di,offset mineState		;將mineState的位址載入目的地寄存器di中
	cld
	xor al,al				;把al歸零
	mov cx,768				;把cx歸零
	rep stosb
	ret
reset endp

;副程式 隨機生成地雷(忽略第一個點開的方格)
setmine proc
	mov cx,mineNumber			;cx = mineNumber
mineSet:
	push cx				;迴圈計數器,確保cx不會被修改
   	mov ah, 2Ch				;調用系統時間鐘功能
    	int 21h
    	mov bx, dx				;抓取時間存到bx
    	in ax,40h				;從40h讀取,放在ax(0~255)
    	mul bx				;增加更多變化性

	xor dx,dx				;dx歸零
	mov bx,768				;bx=768
	div bx				;ax的值除以bx,商放在ax,餘數放在dx
	mov di,dx				;dx(餘數)的值放到di
    	pop cx				;迴圈計數器,確保cx不會被修改

	cmp BlockState[di],0		;如果不為0 出界
	jne mineskip
	cmp mineState[di],9		;等於9 炸彈
	je mineskip
	cmp mineState[di],99		;等於99 起始點
	je mineskip
	mov mineState[di],9		;放炸彈
	
	loop mineSet
  mineskip:
	inc cx				;cx++
	loop mineSet			;回mineSet
	mov di,firstBlock
	mov mineState[di],0
	ret
SetMine endp

;副程式 播放選擇音效
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

;副程式 生成煙火及音效
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

;副程式 顯示開始畫面的地雷造型
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

;副程式 插旗音效
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

;副程式 取消插旗音效
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

;副程式 地雷爆炸音效
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

;副程式 遊戲失敗音效
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

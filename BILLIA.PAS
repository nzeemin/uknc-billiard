PROGRAM BILLIARD;
{$S+}
{$A-}
{$T-}

procedure SCGAME; external; { Подготавливаем экран }
procedure SCEXIT; external; { Вернуть стандтартный режим экрана }
procedure DRBALL(X,Y:integer); external; { Нарисовать шар по XOR }
procedure DRCHAR(X,Y:integer; C:char); external;

procedure DrawBall(X,Y:integer; C:char);
begin
	DRBALL(X,Y);
	DRCHAR(X+4,Y+5,C);
end;

var	I,J:integer;
BEGIN
	SCGAME; { Подготавливаем экран }

	WRITE('TEST');
	{DRCHAR(0,0,'0');}
	for I := 0 to 15 do
		for J := 0 to 9 do begin
			DrawBall(I*20,J*20+20,CHR(48+J));
		end;

	{for I := 0 to 9 do begin
		for J := 0 to 12 do
			DRCHAR(I+J*20,I*10+10,CHR(48+I));
	end;}

	READ(I);

	SCEXIT; { Возвращаем стандтартный режим экрана }
END.

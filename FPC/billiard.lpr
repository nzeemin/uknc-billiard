PROGRAM Billiard;
{$apptype GUI}

Uses	Windows,
	WinCrt,
	Graph,
	SysUtils,
	Math;

Const	BoardLeft = 80;
	BoardTop = 120;
	BoardWidth = 640;
	BoardHeight = 320;
	BallRadius = 24; { Радиус шара }
	BallDiamSqr = (BallRadius * BallRadius * 4.0); { Квадрат от диаметра шара }
	BallMax = 6; { Макс. индекс шара }
	Epsilon = 0.0001;

Type	Ball = record
		X,Y: real;
		MX,MY: real;
	end;
	PBall = ^Ball;

var	Balls: array[0..BallMax] of Ball;

procedure DrawBoard;
var I:integer; B:PBall;
begin
	ClearDevice;
	SetColor(White);
	MoveTo(BoardLeft, BoardTop + BoardHeight + 80);
	OutText('Esc - exit');

	Rectangle(BoardLeft, BoardTop, BoardLeft + BoardWidth, BoardTop + BoardHeight);

	for I := 0 to BallMax do begin
		B := @Balls[I];
		SetColor(Green);
		MoveTo(BoardLeft + Round(B^.X), BoardTop + Round(B^.Y));
		LineTo(BoardLeft + Round(B^.X+B^.MX*4), BoardTop + Round(B^.Y+B^.MY*4));
		SetColor(Yellow);
		Ellipse(BoardLeft + Round(B^.X), BoardTop + Round(B^.Y), 0,360, BallRadius, BallRadius);
		MoveTo(BoardLeft + Round(B^.X)-BallRadius div 3, BoardTop + Round(B^.Y)-BallRadius div 3);
		OutText(IntToStr(I));
	end;
end;

{ Скорость шара вдоль заданного угла A }
function SpeedComponent(B:PBall; A:real): real;
begin
	SpeedComponent := Cos(A) * B^.MX + Sin(A) * B^.MY;
end;

{ Изменить скорость шара вдоль угла A на коэффициент S }
procedure AddSpeedComponent(B:PBall; A,S:real);
begin
	B^.MX := B^.MX + Cos(A) * S;
	B^.MY := B^.MY + Sin(A) * S;
end;

{ Вычислить время до столкновения между шарами, не более 1.0 }
function CalcBallCollision(BI,BJ:PBall): real;
var DX,DY,VX,VY,A,B,C,D,S,E:real;
begin
	DX := BI^.X - BJ^.X;
	DY := BI^.Y - BJ^.Y;
	VX := BI^.MX - BJ^.MX;
	VY := BI^.MY - BJ^.MY;
	if (VX = 0.0) or (VY = 0) then
		CalcBallCollision := 1.0
	else begin
		A := VX * VX + VY * VY;
		B := VX * DX + VY * DY;
		D := VX * DY - VY * DX;
		C := BallDiamSqr * A - D * D;
		if C < 0.0 then
			CalcBallCollision := 1.0
		else begin
			D := Sqrt(C);
			S := (-B - D) / A;
			E := (-B + D) / A;
			if (E < 0.0) or (S < (S - E) / 2) or (S < 0.0) then
				CalcBallCollision := 1.0
			else begin
				CalcBallCollision := S;
			end;
		end;
	end;
	if CalcBallCollision > 1.0 then
		CalcBallCollision := 1.0;
end;

{ Обработка столкновения двух шаров }
procedure CollideBalls(BI,BJ:PBall);
var A,VI,VJ:real;
begin
	A := ArcTan2(BJ^.Y - BI^.Y, BJ^.X - BI^.X); { угол }
	VI := SpeedComponent(BI, A);
	VJ := SpeedComponent(BJ, A);
	AddSpeedComponent(BI, A, -VI + VJ);
	AddSpeedComponent(BJ, A, -VJ + VI);
end;

{ Определение столкновений, сдвиг времени до столкновения, обработка столкновения:
* Задаём время T = 1
* Находим время TC ближайшего столкновения; TC <= 1
* Если не нашли - всех двигаем на время T = 1
* Если нашли - всех двигаем на время TC и отрабатываем столкновение
Результат: время TC <= 1 }
function CalcMovement: real;
var I,J,IC,K:integer; B,BJ:PBall; T,TC:real;
begin
	{ Определяем наличие столкновения и время до ближайшего столкновения }
	IC := -1; { Индекс шара столкновения }
	K := -1; { Тип столкновения: -1 нет; -2..-5 стенка; 0..BallMax шар }
	TC := 1.0; { Время до столкновения }
	for I := 0 to BallMax do begin
		B := @Balls[I];
		{ Столкновения со стенками }
		if (B^.MX < -Epsilon) and (B^.X + B^.MX + Epsilon < BallRadius) then begin { Левая стенка }
			T := (BallRadius - B^.X) / B^.MX;
			if T < TC then begin
				IC := I; TC := T; K:= -2;
			end;
		end;
		if (B^.MX > Epsilon) and (B^.X + B^.MX + BallRadius > BoardWidth + Epsilon) then begin { Правая стенка }
			T := (BoardWidth - B^.X - BallRadius) / B^.MX;
			if T < TC then begin
				IC := I; TC := T; K := -3;
			end;
		end;
		if (B^.MY < -Epsilon) and (B^.Y + B^.MY + Epsilon < BallRadius) then begin { Верхняя стенка }
			T := (BallRadius - B^.Y) / B^.MY;
			if T < TC then begin
				IC := I; TC := T; K:= -4;
			end;
		end;
		if (B^.MY > Epsilon) and (B^.Y + B^.MY + BallRadius > BoardHeight + Epsilon) then begin { Нижняя стенка }
			T := (BoardHeight - B^.Y - BallRadius) / B^.MY;
			if T < TC then begin
				IC := I; TC := T; K := -5;
			end;
		end;
		{ Столкновения с другими шарами }
		for J := 0 to I - 1 do begin
			BJ := @Balls[J];
			T := CalcBallCollision(B, BJ);
			if T < TC then begin
				IC := I; TC := T; K := J;
			end;
		end;
	end;

	{ Анализ результатов и обработка столкновения }
	if IC < 0 then begin { Столкновений нет, продвигаемся на время T = 1 }
		for I := 0 to BallMax do begin
			B := @Balls[I];
			B^.X := B^.X + B^.MX;
			B^.Y := B^.Y + B^.MY;
		end;
	end else begin { Есть столкновение, продвигаемся на время TC }
		{if TC < 0 then MessageBox(0, 'Right T < 0', nil, mb_Ok);}
		if TC < 0 then TC := 0;
		for I := 0 to BallMax do begin
			B := @Balls[I];
			B^.X := B^.X + B^.MX * TC;
			B^.Y := B^.Y + B^.MY * TC;
		end;
		B := @Balls[IC];
		case K of
			-2, -3: B^.MX := -B^.MX; { Левая/правая стенка }
			-4, -5: B^.MY := -B^.MY; { Верхняя/нижняя стенка }
			else begin { Столкновение с другим шаром }
				{MessageBox(0, 'Ball collision', nil, mb_Ok);}
				BJ := @Balls[K];
				CollideBalls(B, BJ);
			end;
		end;
		{DrawBoard;}{DEBUG}
		{repeat until KeyPressed;}{DEBUG}
	end;
	CalcMovement := TC;
end;

procedure DoMainLoop;
var X:char; TC:real;
begin
	TC := 1.0;
	repeat
		repeat
			Delay(trunc(TC * 100.0));
			DrawBoard;
			TC := CalcMovement;
		until KeyPressed;
		X := ReadKey;
		if X = #27 then Exit;
	until false;
end;

VAR
	gd, gm, I: integer;
	B: PBall;
BEGIN
	{ShowWindow(GetActiveWindow, 0);}
	gm := m800x600x256;
	gd := VESA;
	InitGraph(gd, gm, '');
	if GraphResult <> grOk then begin
		Writeln('Graph driver ',gd,' graph mode ',gm,' not supported');
		Halt(1);
	end;
	SetBkColor(Black);
	SetViewPort(0, 0, GetMaxX, GetMaxY, False);
	SetFillStyle(SolidFill, 1);
	SetTextStyle(SimpleFont, HorizDir, 2);
	ClearDevice;

	for I := 0 to BallMax do begin
		B := @Balls[I];
		B^.X := Random(BoardWidth);
		B^.Y := Random(BoardHeight);
		B^.MX := Random(20) - 10;
		B^.MY := Random(20) - 10;
	end;	

	DoMainLoop;

	CloseGraph;
END.

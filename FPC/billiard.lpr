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
	BallRadiusSqr = BallRadius * BallRadius; { Квадрат от радиуса шара }
	BallDiamSqr = BallRadius * BallRadius * 4.0; { Квадрат от диаметра шара }
	BallMax = 6; { Макс. индекс шара }
	HoleRadius = 36; { Радиус центральных луз }
	CHoleRadius = 52; { Радиус угловых луз }
	RadiusDiff = HoleRadius - BallRadius;
	Epsilon = 0.0001;

Type	Point = record
		X,Y: real;
	end;
	PPoint = ^Point;
	Ball = record
		X,Y: real;
		MX,MY: real;
		Active: boolean;
	end;
	PBall = ^Ball;

var	Balls: array[0..BallMax] of Ball;
	PointLTopL,PointLTopR, PointCTopL,PointCTopR, PointRTopL,PointRTopR,
	PointLBotL,PointLBotR, PointCBotL,PointCBotR, PointRBotL,PointRBotR: Point; { Угловые точки луз }
	IC:integer; { Индекс шара столкновения; -1 если столкновения нет }
	TC:real; { Время до столкновения; 1.0 если столкновения нет }
	K:integer; { Тип столкновения: -1 нет; -2..-5 стенка; 0..BallMax шар }

procedure DrawBoard;
var I:integer; B:PBall;
begin
	ClearDevice;
	SetColor(White);
	MoveTo(BoardLeft, BoardTop + BoardHeight + 80);
	{SetColor(Green);
	OutText('Esc - exit');}

	{SetColor(Blue);
	Rectangle(BoardLeft, BoardTop, BoardLeft + BoardWidth, BoardTop + BoardHeight);}
	SetColor(Green);
	MoveTo(BoardLeft + CHoleRadius, BoardTop);
	LineTo(BoardLeft + (BoardWidth div 2) - HoleRadius, BoardTop);
	MoveTo(BoardLeft + CHoleRadius, BoardTop + BoardHeight);
	LineTo(BoardLeft + (BoardWidth div 2) - HoleRadius, BoardTop + BoardHeight);
	MoveTo(BoardLeft, BoardTop + CHoleRadius);
	LineTo(BoardLeft, BoardTop + BoardHeight - CHoleRadius);
	MoveTo(BoardLeft + BoardWidth, BoardTop + CHoleRadius);
	LineTo(BoardLeft + BoardWidth, BoardTop + BoardHeight - CHoleRadius);
	MoveTo(BoardLeft + BoardWidth - CHoleRadius, BoardTop);
	LineTo(BoardLeft + (BoardWidth div 2) + HoleRadius, BoardTop);
	MoveTo(BoardLeft + BoardWidth - CHoleRadius, BoardTop + BoardHeight);
	LineTo(BoardLeft + (BoardWidth div 2) + HoleRadius, BoardTop + BoardHeight);
	{Ellipse(BoardLeft + BoardWidth div 2, BoardTop, 0,180, HoleRadius, HoleRadius);
	Ellipse(BoardLeft + BoardWidth div 2, BoardTop + BoardHeight, 180,360, HoleRadius, HoleRadius);}

	for I := 0 to BallMax do begin
		B := @Balls[I];
		if not B^.Active then continue;
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
var DX,DY,VX,VY,A,B,C,D,S,E,Result:real;
begin
	DX := BI^.X - BJ^.X;
	DY := BI^.Y - BJ^.Y;
	VX := BI^.MX - BJ^.MX;
	VY := BI^.MY - BJ^.MY;
	if (VX = 0.0) or (VY = 0.0) then
		Result := 1.0
	else begin
		A := VX * VX + VY * VY;
		B := VX * DX + VY * DY;
		D := VX * DY - VY * DX;
		C := BallDiamSqr * A - D * D;
		if C < 0.0 then
			Result := 1.0
		else begin
			D := Sqrt(C);
			S := (-B - D) / A;
			E := (-B + D) / A;
			if (E < 0.0) or (S < (S - E) / 2) or (S < 0.0) then
				Result := 1.0
			else begin
				Result := S;
			end;
		end;
	end;
	if Result > 1.0 then
		Result := 1.0;
	CalcBallCollision := Result;
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

{ Вычислить время до столкновения шара с угловой точкой, не более 1.0 }
function CalcBallPointCollision(BI:PBall; P:PPoint): real;
var DX,DY,VX,VY,A,B,C,D,S,E,Result:real;
begin
	DX := BI^.X - P^.X;
	DY := BI^.Y - P^.Y;
	VX := BI^.MX;
	VY := BI^.MY;
	if (VX = 0.0) or (VY = 0.0) then
		Result := 1.0
	else begin
		A := VX * VX + VY * VY;
		B := VX * DX + VY * DY;
		D := VX * DY - VY * DX;
		C := BallRadiusSqr * A - D * D;
		if C < 0.0 then
			Result := 1.0
		else begin
			D := Sqrt(C);
			S := (-B - D) / A;
			E := (-B + D) / A;
			if (E < 0.0) or (S < (S - E) / 2) or (S < 0.0) then
				Result := 1.0
			else begin
				Result := S;
			end;
		end;
	end;
	if Result > 1.0 then
		Result := 1.0;
	CalcBallPointCollision := Result;
end;

{ Обработка столкновения шара с угловой точкой }
procedure CollideBallPoint(BI:PBall; P:PPoint);
var A,VI:real;
begin
	A := ArcTan2(P^.Y - BI^.Y, P^.X - BI^.X); { угол }
	VI := SpeedComponent(BI, A);
	AddSpeedComponent(BI, A, -VI - VI);
end;

{ Определение ближайшего по времени столкновения
  РезультатЫ: время TC <= 1, индекс шара IC, тип столкновения K }
procedure FindCollision;
var I,J:integer; B,BJ:PBall; T:real; InHole:boolean;
begin
	{ Определяем наличие столкновения и время до ближайшего столкновения }
	IC := -1; { Индекс шара столкновения }
	K := -1; { Тип столкновения: -1 нет; -2..-5 стенка; 0..BallMax шар }
	TC := 1.0; { Время до столкновения }
	InHole := false;
	for I := 0 to BallMax do begin
		B := @Balls[I];
		if not B^.Active then continue;
		{ Условие снятия с доски - центр шара вышел за линию стенок}
		if (B^.X < 0) or (B^.X > BoardWidth) or (B^.Y < 0) or (B^.Y > BoardHeight) then begin
			B^.Active := false;
			continue;
		end;
		{ Если зашёл в центральную лузу - проверять условие столкновения с углами}
		if (B^.Y - BallRadius < Epsilon) or (B^.Y + BallRadius + Epsilon > BoardHeight) then begin
			if abs(BoardWidth / 2.0 - B^.X) < HoleRadius then begin
				InHole := true;
				if B^.Y < BoardHeight / 2.0 then begin { Верхняя центральная луза }
					T := CalcBallPointCollision(B, @PointCTopL);
					if T < TC then begin
						IC := I; TC := T; K := -8;
					end;
					T := CalcBallPointCollision(B, @PointCTopR);
					if T < TC then begin
						IC := I; TC := T; K := -9;
					end;
				end else begin { Нижняя центральная луза }
					T := CalcBallPointCollision(B, @PointCBotL);
					if T < TC then begin
						IC := I; TC := T; K := -14;
					end;
					T := CalcBallPointCollision(B, @PointCBotR);
					if T < TC then begin
						IC := I; TC := T; K := -15;
					end;
				end;
			end;
		end;
		{ Если зашёл в угловую лузу - проверять на столкновение с углами }
		if (B^.X - BallRadius < Epsilon) and (B^.Y <= CHoleRadius) or
		   (B^.Y - BallRadius < Epsilon) and (B^.X <= CHoleRadius) then begin { Левая верхняя луза }
			InHole := true;
			T := CalcBallPointCollision(B, @PointLTopL);
			if T < TC then begin
				IC := I; TC := T; K := -6;
			end;
			T := CalcBallPointCollision(B, @PointLTopR);
			if T < TC then begin
				IC := I; TC := T; K := -7;
			end;
		end;
		if (B^.X + BallRadius + Epsilon > BoardWidth) and (B^.Y <= CHoleRadius) or
		   (B^.Y - BallRadius < Epsilon) and (B^.X >= BoardWidth - CHoleRadius) then begin { Правая верхняя луза }
			InHole := true;
			T := CalcBallPointCollision(B, @PointRTopL);
			if T < TC then begin
				IC := I; TC := T; K := -10;
			end;
			T := CalcBallPointCollision(B, @PointRTopR);
			if T < TC then begin
				IC := I; TC := T; K := -11;
			end;
		end;
		if (B^.X - BallRadius < Epsilon) and (B^.Y >= BoardHeight - CHoleRadius) or
		   (B^.Y + BallRadius > BoardHeight - Epsilon) and (B^.X <= CHoleRadius) then begin { Левая нижняя луза }
			InHole := true;
			T := CalcBallPointCollision(B, @PointLBotL);
			if T < TC then begin
				IC := I; TC := T; K := -12;
			end;
			T := CalcBallPointCollision(B, @PointLBotR);
			if T < TC then begin
				IC := I; TC := T; K := -13;
			end;
		end;
		if (B^.X + BallRadius + Epsilon > BoardWidth) and (B^.Y >= BoardHeight - CHoleRadius) or
		   (B^.Y + BallRadius + Epsilon > BoardHeight) and (B^.X >= BoardWidth - CHoleRadius) then begin { Правая нижняя луза }
			InHole := true;
			T := CalcBallPointCollision(B, @PointRBotL);
			if T < TC then begin
				IC := I; TC := T; K := -16;
			end;
			T := CalcBallPointCollision(B, @PointRBotR);
			if T < TC then begin
				IC := I; TC := T; K := -17;
			end;
		end;

		if not InHole then begin
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
		end;
		{ Столкновения с другими шарами }
		for J := 0 to I - 1 do begin
			BJ := @Balls[J];
			if not BJ^.Active then continue;
			T := CalcBallCollision(B, BJ);
			if T < TC then begin
				IC := I; TC := T; K := J;
			end;
		end;
	end;
end;

{ Анализ результатов FindCollision и обработка столкновения }
procedure MoveAndCollide;
var I:integer; B,BJ:PBall;
begin
	if IC < 0 then begin { Столкновений нет, продвигаемся на время 1.0 }
		for I := 0 to BallMax do begin
			B := @Balls[I];
			B^.X := B^.X + B^.MX;
			B^.Y := B^.Y + B^.MY;
		end;
	end else begin { Есть столкновение, продвигаемся на время TC }
		if TC < 0 then TC := 0;
		for I := 0 to BallMax do begin
			B := @Balls[I];
			B^.X := B^.X + B^.MX * TC;
			B^.Y := B^.Y + B^.MY * TC;
		end;
		{ Обработка столкновения }
		B := @Balls[IC]; { Шар с которым произошло столкновение }
		case K of
			-2, -3: begin { Левая/правая стенка }
				{ Проверяем условие захода в угловую лузу}
				if (B^.Y > CHoleRadius) and (B^.Y < BoardHeight - CHoleRadius) then
					B^.MX := -B^.MX;
			end;
			-4, -5: begin { Верхняя/нижняя стенка }
				{ Проверяем условие захода центральную в лузу - по горизонтали центр внутри лузы
				  и условие захода в угловую лузу}
				if (abs(BoardWidth / 2.0 - B^.X) > HoleRadius) and
				   (B^.X > CHoleRadius) and (B^.X < BoardWidth - CHoleRadius) then
					B^.MY := -B^.MY;
			end;
			-6: CollideBallPoint(B, @PointLTopL);
			-7: CollideBallPoint(B, @PointLTopR);
			-8: CollideBallPoint(B, @PointCTopL);
			-9: CollideBallPoint(B, @PointCTopR);
			-10: CollideBallPoint(B, @PointRTopL);
			-11: CollideBallPoint(B, @PointRTopR);
			-12: CollideBallPoint(B, @PointLBotL);
			-13: CollideBallPoint(B, @PointLBotR);
			-14: CollideBallPoint(B, @PointCBotL);
			-15: CollideBallPoint(B, @PointCBotR);
			-16: CollideBallPoint(B, @PointRBotL);
			-17: CollideBallPoint(B, @PointRBotR);
			else begin { Столкновение с другим шаром }
				BJ := @Balls[K];
				CollideBalls(B, BJ);
			end;
		end;
	end;
end;

procedure DoMainLoop;
var X:char; TC:real;
begin
	TC := 1.0;
	repeat
		repeat
			DrawBoard;
			Delay(trunc(TC * 100.0));
			FindCollision;
			MoveAndCollide;
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

	{ Настраиваем угловые точки }
	PointLTopL.X := 0.0; PointLTopL.Y := CHoleRadius;
	PointLTopR.X := CHoleRadius; PointLTopR.Y := 0.0;
	PointCTopL.X := BoardWidth / 2.0 - HoleRadius; PointCTopL.Y := 0.0;
	PointCTopR.X := BoardWidth / 2.0 + HoleRadius; PointCTopR.Y := 0.0;
	PointRTopL.X := BoardWidth - CHoleRadius; PointRTopL.Y := 0.0;
	PointRTopR.X := BoardWidth; PointRTopR.Y := CHoleRadius;
	PointLBotL.X := 0.0; PointLBotL.Y := BoardHeight - CHoleRadius;
	PointLBotR.X := CHoleRadius; PointLBotR.Y := BoardHeight;
	PointCBotL.X := PointCTopL.X; PointCBotL.Y := BoardHeight;
	PointCBotR.X := PointCTopR.X; PointCBotR.Y := BoardHeight;
	PointRBotL.X := BoardWidth - CHoleRadius; PointRBotL.Y := BoardHeight;
	PointRBotR.X := BoardWidth; PointRBotR.Y := BoardHeight - CHoleRadius;

	for I := 0 to BallMax do begin
		B := @Balls[I];
		B^.Active := true;
		B^.X := Random(BoardWidth);
		B^.Y := Random(BoardHeight);
		B^.MX := Random(20) - 10;
		B^.MY := Random(20) - 10;
	end;	

	DoMainLoop;

	CloseGraph;
END.

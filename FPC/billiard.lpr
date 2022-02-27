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
	BallRadius = 24; { ������ ���� }
	BallRadiusSqr = BallRadius * BallRadius; { ������� �� ������� ���� }
	BallDiamSqr = BallRadius * BallRadius * 4.0; { ������� �� �������� ���� }
	BallMax = 6; { ����. ������ ���� }
	HoleRadius = 36; { ������ ����������� ��� }
	CHoleRadius = 52; { ������ ������� ��� }
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
	PointLBotL,PointLBotR, PointCBotL,PointCBotR, PointRBotL,PointRBotR: Point; { ������� ����� ��� }
	IC:integer; { ������ ���� ������������; -1 ���� ������������ ��� }
	TC:real; { ����� �� ������������; 1.0 ���� ������������ ��� }
	K:integer; { ��� ������������: -1 ���; -2..-5 ������; 0..BallMax ��� }

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

{ �������� ���� ����� ��������� ���� A }
function SpeedComponent(B:PBall; A:real): real;
begin
	SpeedComponent := Cos(A) * B^.MX + Sin(A) * B^.MY;
end;

{ �������� �������� ���� ����� ���� A �� ����������� S }
procedure AddSpeedComponent(B:PBall; A,S:real);
begin
	B^.MX := B^.MX + Cos(A) * S;
	B^.MY := B^.MY + Sin(A) * S;
end;

{ ��������� ����� �� ������������ ����� ������, �� ����� 1.0 }
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

{ ��������� ������������ ���� ����� }
procedure CollideBalls(BI,BJ:PBall);
var A,VI,VJ:real;
begin
	A := ArcTan2(BJ^.Y - BI^.Y, BJ^.X - BI^.X); { ���� }
	VI := SpeedComponent(BI, A);
	VJ := SpeedComponent(BJ, A);
	AddSpeedComponent(BI, A, -VI + VJ);
	AddSpeedComponent(BJ, A, -VJ + VI);
end;

{ ��������� ����� �� ������������ ���� � ������� ������, �� ����� 1.0 }
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

{ ��������� ������������ ���� � ������� ������ }
procedure CollideBallPoint(BI:PBall; P:PPoint);
var A,VI:real;
begin
	A := ArcTan2(P^.Y - BI^.Y, P^.X - BI^.X); { ���� }
	VI := SpeedComponent(BI, A);
	AddSpeedComponent(BI, A, -VI - VI);
end;

{ ����������� ���������� �� ������� ������������
  ����������: ����� TC <= 1, ������ ���� IC, ��� ������������ K }
procedure FindCollision;
var I,J:integer; B,BJ:PBall; T:real; InHole:boolean;
begin
	{ ���������� ������� ������������ � ����� �� ���������� ������������ }
	IC := -1; { ������ ���� ������������ }
	K := -1; { ��� ������������: -1 ���; -2..-5 ������; 0..BallMax ��� }
	TC := 1.0; { ����� �� ������������ }
	InHole := false;
	for I := 0 to BallMax do begin
		B := @Balls[I];
		if not B^.Active then continue;
		{ ������� ������ � ����� - ����� ���� ����� �� ����� ������}
		if (B^.X < 0) or (B^.X > BoardWidth) or (B^.Y < 0) or (B^.Y > BoardHeight) then begin
			B^.Active := false;
			continue;
		end;
		{ ���� ��ۣ� � ����������� ���� - ��������� ������� ������������ � ������}
		if (B^.Y - BallRadius < Epsilon) or (B^.Y + BallRadius + Epsilon > BoardHeight) then begin
			if abs(BoardWidth / 2.0 - B^.X) < HoleRadius then begin
				InHole := true;
				if B^.Y < BoardHeight / 2.0 then begin { ������� ����������� ���� }
					T := CalcBallPointCollision(B, @PointCTopL);
					if T < TC then begin
						IC := I; TC := T; K := -8;
					end;
					T := CalcBallPointCollision(B, @PointCTopR);
					if T < TC then begin
						IC := I; TC := T; K := -9;
					end;
				end else begin { ������ ����������� ���� }
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
		{ ���� ��ۣ� � ������� ���� - ��������� �� ������������ � ������ }
		if (B^.X - BallRadius < Epsilon) and (B^.Y <= CHoleRadius) or
		   (B^.Y - BallRadius < Epsilon) and (B^.X <= CHoleRadius) then begin { ����� ������� ���� }
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
		   (B^.Y - BallRadius < Epsilon) and (B^.X >= BoardWidth - CHoleRadius) then begin { ������ ������� ���� }
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
		   (B^.Y + BallRadius > BoardHeight - Epsilon) and (B^.X <= CHoleRadius) then begin { ����� ������ ���� }
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
		   (B^.Y + BallRadius + Epsilon > BoardHeight) and (B^.X >= BoardWidth - CHoleRadius) then begin { ������ ������ ���� }
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
			{ ������������ �� �������� }
			if (B^.MX < -Epsilon) and (B^.X + B^.MX + Epsilon < BallRadius) then begin { ����� ������ }
				T := (BallRadius - B^.X) / B^.MX;
				if T < TC then begin
					IC := I; TC := T; K:= -2;
				end;
			end;
			if (B^.MX > Epsilon) and (B^.X + B^.MX + BallRadius > BoardWidth + Epsilon) then begin { ������ ������ }
				T := (BoardWidth - B^.X - BallRadius) / B^.MX;
				if T < TC then begin
					IC := I; TC := T; K := -3;
				end;
			end;
			if (B^.MY < -Epsilon) and (B^.Y + B^.MY + Epsilon < BallRadius) then begin { ������� ������ }
				T := (BallRadius - B^.Y) / B^.MY;
				if T < TC then begin
					IC := I; TC := T; K:= -4;
				end;
			end;
			if (B^.MY > Epsilon) and (B^.Y + B^.MY + BallRadius > BoardHeight + Epsilon) then begin { ������ ������ }
				T := (BoardHeight - B^.Y - BallRadius) / B^.MY;
				if T < TC then begin
					IC := I; TC := T; K := -5;
				end;
			end;
		end;
		{ ������������ � ������� ������ }
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

{ ������ ����������� FindCollision � ��������� ������������ }
procedure MoveAndCollide;
var I:integer; B,BJ:PBall;
begin
	if IC < 0 then begin { ������������ ���, ������������ �� ����� 1.0 }
		for I := 0 to BallMax do begin
			B := @Balls[I];
			B^.X := B^.X + B^.MX;
			B^.Y := B^.Y + B^.MY;
		end;
	end else begin { ���� ������������, ������������ �� ����� TC }
		if TC < 0 then TC := 0;
		for I := 0 to BallMax do begin
			B := @Balls[I];
			B^.X := B^.X + B^.MX * TC;
			B^.Y := B^.Y + B^.MY * TC;
		end;
		{ ��������� ������������ }
		B := @Balls[IC]; { ��� � ������� ��������� ������������ }
		case K of
			-2, -3: begin { �����/������ ������ }
				{ ��������� ������� ������ � ������� ����}
				if (B^.Y > CHoleRadius) and (B^.Y < BoardHeight - CHoleRadius) then
					B^.MX := -B^.MX;
			end;
			-4, -5: begin { �������/������ ������ }
				{ ��������� ������� ������ ����������� � ���� - �� ����������� ����� ������ ����
				  � ������� ������ � ������� ����}
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
			else begin { ������������ � ������ ����� }
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

	{ ����������� ������� ����� }
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

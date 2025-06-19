unit sgr_scale;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{ (c) S.P.Pod'yachev 1998 - 2025 } 

interface

uses
{$IFDEF FPC}
  LCLIntf, LCLType,
  SysUtils, Classes, Graphics,
{$ELSE}
  WinApi.Windows,
  System.SysUtils,  System.Classes,
  Vcl.Graphics,
{$ENDIF}
  sgr_line;

{***************************************************}
{ Auxiliary persistent object  for using            }
{ in components with scale or axis                  }
{***************************************************}
{:}

const
  dblDfltAxisMin = 0.0;
  dblDfltAxisMax = 10.0;

const
  MaxTicksCount = 21;
  fbposVertical = 0;
  fbposInversed = 1;
  fbposNegMetr = 2;
  fbposNoTicks = 3;
  fbposNoTicksLabel = 4;
  fbposRevertTicks = 5;
  fbposAutoMin = 6;
  fbposAutoMax = 7;
  fbposLabelAsDate = 8;
  fbposNotAjustedTicks = 9;
  sdfVertical = 1 shl fbposVertical;
  sdfInversed = 1 shl fbposInversed;
  sdfNegMetr = 1 shl fbposNegMetr;
  sdfNoTicks = 1 shl fbposNoTicks;
  sdfNoTicksLabel = 1 shl fbposNoTicksLabel;
  sdfRevertTicks = 1 shl fbposRevertTicks;
  sdfLabelAtTop = sdfRevertTicks;
  sdfLabelOnRight = sdfRevertTicks;
  sdfAutoMin = 1 shl fbposAutoMin;
  sdfAutoMax = 1 shl fbposAutoMax;
  sdfLabelAsDate = 1 shl fbposLabelAsDate;
  sdfNotAjustedTicks = 1 shl fbposNotAjustedTicks;

type
  Tsp_Scale = class(TPersistent)
  private
    IMin, IMax: double;
    IntFactor: double;
    IStep: integer;
    rTksCount: byte;
    fOPos: integer;  // scale origin position in pixels
    fOVal: double;   // Value at scale origin  see proc CalcMetr
    fM: double;      // Value to pixel multiplier
    procedure ReadFlags(Reader: TReader);
    procedure WriteFlags(Writer: TWriter);
    procedure ReadLinePos(Reader: TReader);
    procedure WriteLinePos(Writer: TWriter);
    procedure ReadMin(Reader: TReader);
    procedure WriteMin(Writer: TWriter);
    procedure ReadMax(Reader: TReader);
    procedure WriteMax(Writer: TWriter);
    function GetVisible: boolean;
    function GetOX: integer;  //2.4 add for C++
    function GetOY: integer;
  protected
    fFlags: integer;
    fO: TPoint;
    fLen: integer;
    fLabelFormat: string;
    fLineAttr: Tsp_LineAttr;
    fMin, fMax: double;
    fInterval: double;
    fTksPos: array [0..MaxTicksCount - 1] of integer; //2022 smallint;
    fTksDbl: array [0..MaxTicksCount - 1] of double;
    fTicksCount: byte;
    function TksDbl(i: integer): double;
    procedure DefineProperties(Filer: TFiler); override;
    procedure FixMinMax(Mi, Ma: double);
    procedure CalcMetr;
    procedure CalcTicksVal;
    procedure CalcTicksPos;
    procedure ShiftScaleBy(pixel: boolean; idelta: double; fdelta: double);
    function TickLabel(tickNum: integer): string; virtual;
    function GetTicksCount: byte;
    procedure SetFlagBit(const BN: integer; const OnOff: boolean);
    procedure ReSetFlagBit(const BN: integer; const Off: boolean);
    function GetFlagBit(const BN: integer): boolean;
    function NotFlagBit(const BN: integer): boolean;
    procedure FlagsChanged(const BN: integer; const OnOff: boolean); virtual;
  public
    constructor Create(Flags: integer);
    destructor Destroy; override;
    function BandWidth(FntWidth, FntHeight: integer): integer;
    function OrgIndent(FntWidth, FntHeight: integer): integer;
    function EndIndent(FntWidth, FntHeight: integer): integer;
    //function CalcDrawBounds(fCanvas: TCanvas): TRect;
    procedure DrawLine(fCanvas: TCanvas; odec, einc: word);
    procedure DrawTicks(fCanvas: TCanvas);
    procedure SetLine(oX, oY, lLen: integer);
    procedure ChangeMinMax(aMin, aMax: double);
    procedure ScrollBy(delta: integer);
    function V2P(const V: double): integer;
    function P2V(const V: integer): double;
    property OPos: integer read fOPos;
    property OVal: double read fOVal;
    property SM: double read fM;
    property Visible: boolean read GetVisible;
    property OX: integer read GetOX;
    property OY: integer read GetOY;
    property Len: integer read fLen;
    property NoTicks: boolean index fbposNoTicks
      read GetFlagBit write SetFlagBit stored False;
  published
    property Inversed: boolean index fbposInversed
      read GetFlagBit write SetFlagBit stored False;
    property NoTicksLabel: boolean index fbposNoTicksLabel
      read GetFlagBit write SetFlagBit stored False;
    property TicksAdjusted: boolean index fbposNotAjustedTicks
      read NotFlagBit write ReSetFlagBit stored False;
    property TicksLines: boolean index fbposNoTicks
      read NotFlagBit write ReSetFlagBit stored False;
  end;

implementation

{*** auxilary function ***}
const
  Ln10 = 2.30258509299405;
  sdfLineOnly = sdfNoTicks or sdfNoTicksLabel;

function Floor(x: double): double;
begin
  if Frac(x) < 0 then
    Result := Int(x) - 1
  else
    Result := Int(x);
end;

function Ceil(x: double): double;
begin
  if Frac(x) > 0 then
    Result := Int(x) + 1
  else
    Result := Int(x);
end;

{*** Tsp_Scale ***}
procedure Tsp_Scale.ReadFlags(Reader: TReader);
begin
  fFlags := Reader.ReadInteger;
end;

procedure Tsp_Scale.ReadLinePos(Reader: TReader);
begin
  with Reader do
  begin
    ReadListBegin;
    fO.x := ReadInteger;
    fO.y := ReadInteger;
    fLen := ReadInteger;
    ReadListEnd;
  end;
end;

procedure Tsp_Scale.ReadMin(Reader: TReader);
begin
  fMin := Reader.ReadFloat;
end;

procedure Tsp_Scale.ReadMax(Reader: TReader);
begin
  ChangeMinMax(fMin, Reader.ReadFloat);
end;

procedure Tsp_Scale.WriteFlags(Writer: TWriter);
begin
  Writer.WriteInteger(fFlags);
end;

procedure Tsp_Scale.WriteLinePos(writer: TWriter);
begin
  with Writer do
  begin
    WriteListBegin;
    WriteInteger(fO.x);
    WriteInteger(fO.y);
    WriteInteger(fLen);
    WriteListEnd;
  end;
end;

procedure Tsp_Scale.WriteMin(Writer: TWriter);
begin
  Writer.WriteFloat(fMin);
end;

procedure Tsp_Scale.WriteMax(Writer: TWriter);
begin
  Writer.WriteFloat(fMax);
end;

function Tsp_Scale.GetVisible: boolean;
begin
  Result := ((fFlags and sdfLineOnly) <> sdfLineOnly) or fLineAttr.Visible;
end;

function Tsp_Scale.GetOX: integer;
begin
  Result := fO.x;
end;

function Tsp_Scale.GetOY: integer;
begin
  Result := fO.y;
end;

function Tsp_Scale.TksDbl(i: integer): double;
begin
  if (fFlags and sdfNotAjustedTicks) = 0 then
    Result := fTksDbl[i]
  else if (fFlags and sdfInversed) = 0 then
    Result := fOVal + fInterval * fTksDbl[i]
  else
    Result := fOVal - fInterval * fTksDbl[i];
end;

procedure Tsp_Scale.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(filer);
  Filer.DefineProperty('SFlags', ReadFlags, WriteFlags, True);
  Filer.DefineProperty('SLinePos', ReadLinePos, WriteLinePos, True);
  Filer.DefineProperty('fMin', ReadMin, WriteMin, fMin <> dblDfltAxisMin);
  Filer.DefineProperty('fMax', ReadMax, WriteMax, True);
end;

procedure Tsp_Scale.FixMinMax(Mi, Ma: double);
var
  DecmlPos: integer;
begin
  if Mi > Ma then
  begin
    fMin := Ma;
    fMax := Mi;
  end
  else
  begin
    fMin := Mi;
    fMax := Ma;
  end;
  if fMin = fMax then
  begin
    if abs(fMax) < 10 then
    begin
      fMax := fMax + 1;
      fMin := fMax - 1;
    end
    else
    begin
      fMax := fMax + abs(fMax) / 10;
      fMin := fMax - abs(fMax) / 10;
    end;
  end;
  fInterval := fMax - fMin;
  DecmlPos := Trunc(Floor(Ln(fInterval) / Ln10));
  if DecmlPos > 0 then
    IntFactor := 1 / Int(exp((DecmlPos - 1) * Ln10))
  else
    IntFactor := Int(exp(-(DecmlPos - 1) * Ln10));
  IMin := Ceil(fMin * IntFactor);
  IMax := Floor(fMax * IntFactor);
end;

procedure Tsp_Scale.CalcMetr;
begin
  if (fFlags and sdfInversed) = 0 then
  begin
    fM := fLen / fInterval;
    fOVal := fMin;
  end
  else
  begin
    fM := -fLen / fInterval;
    fOVal := fMax;
  end;
  if (fFlags and sdfVertical) = 0 then
    fOPos := fO.x
  else
  begin
    fOPos := fO.y;
    fM := -fM;
  end;
end;

procedure Tsp_Scale.CalcTicksVal;

  procedure LbldTicksVal;
  var
    j, sstep: integer;
    oid: double;
  begin
    if fTicksCount > 1 then
    begin
      j := Round(IMax - IMin);
      IStep := j div (fTicksCount - 1);
      if IStep = 0 then
        Inc(IStep);
      rTksCount := (j div IStep) + 1;
      if rTksCount > MaxTicksCount then
        rTksCount := MaxTicksCount;
    end
    else
      IStep := Round(IMax - IMin);
    if (fFlags and sdfInversed) = 0 then
    begin
      oid := IMin;
      sstep := IStep;
    end
    else
    begin
      oid := IMax;
      sstep := -IStep;
    end;
    for j := 0 to rTksCount - 1 do
      fTksDbl[j] := Int(oid + sstep * j) / IntFactor;
  end;

  procedure TicksVal;
  var
    j: integer;
    step: double;
  begin
    if fTicksCount > 1 then
      step := 1 / (fTicksCount - 1)
    else
      step := 1;
    for j := 0 to fTicksCount - 1 do
      fTksDbl[j] := step * j;
  end;

begin
  rTksCount := fTicksCount;
  if fTicksCount > 0 then
    if (fFlags and (sdfNoTicksLabel or sdfNotAjustedTicks)) = 0 then
      LbldTicksVal
    else
      TicksVal;
end;

procedure Tsp_Scale.CalcTicksPos;

  procedure LbldTicks;
  var
    j: integer;
  begin
    for j := 0 to rTksCount - 1 do
      fTksPos[j] := V2P(fTksDbl[j]);
  end;

  procedure NoLbldTicks;
  var
    j: integer;
  begin
    if (fFlags and sdfVertical) = 0 then
      for j := 0 to rTksCount - 1 do
        fTksPos[j] := fOPos + round(fLen * fTksDbl[j])
    else
      for j := 0 to rTksCount - 1 do
        fTksPos[j] := fOPos - round(fLen * fTksDbl[j]);
  end;

begin
  if fTicksCount < 1 then
  begin
    rTksCount := fTicksCount;
    Exit;
  end;
  if (fFlags and (sdfNoTicksLabel or sdfNotAjustedTicks)) = 0 then
    LbldTicks
  else
    NoLbldTicks;
end;

procedure Tsp_Scale.ShiftScaleBy(pixel:boolean; idelta:double; fdelta:double);

  procedure ShiftMinMax(delta: double);
  begin
    fMin := fMin + delta;
    fMax := fMin + fInterval;
    if (fFlags and sdfInversed) = 0 then
      fOVal := fMin
    else
      fOVal := fMax;
    IMin := Ceil(fMin * IntFactor);
    IMax := Floor(fMax * IntFactor);
  end;

  procedure SLbldTicksVal(delta: double);     //??? delta is not used
  var
    id: extended;
    j: integer;
  begin
    id := Frac((fTksDbl[0] * IntFactor - fOVal * IntFactor) / IStep);
    if ((fFlags and sdfInversed) = 0) then
    begin
      if id < 0 then
        id := id + 1;
      id := fOVal * IntFactor + id * IStep;
      rTksCount := Trunc((fMax * IntFactor - id) / IStep) + 1;
      if rTksCount > MaxTicksCount then
        rTksCount := MaxTicksCount;
      for j := 0 to rTksCount do
        fTksDbl[j] := (id + IStep * j) / IntFactor;
    end
    else
    begin
      if id > 0 then
        id := id - 1;
      id := fOVal * IntFactor + id * IStep;
      rTksCount := Trunc((id - fMin * IntFactor) / IStep) + 1;
      if rTksCount > MaxTicksCount then
        rTksCount := MaxTicksCount;
      for j := 0 to rTksCount do
        fTksDbl[j] := (id - IStep * j) / IntFactor;
    end;
  end;

  procedure STicksVal(delta: double);
  var
    id, step: double;
    j: integer;
  begin
    if fTicksCount > 1 then
      step := 1 / (fTicksCount - 1)
    else
      step := 1;
    if (fFlags and sdfVertical) <> 0 then
      delta := -delta;
    id := Frac((fTksDbl[0] * fLen - delta) / (fLen * step));
    if id < 0 then
      id := id + 1;
    rTksCount := Trunc(1 / step - id) + 1;
    id := id * step;
    if rTksCount > MaxTicksCount then
      rTksCount := MaxTicksCount;
    for j := 0 to rTksCount - 1 do
      fTksDbl[j] := id + step * j;
  end;

begin            //Tsp_Scale.ShiftScaleBy
  if pixel then
    fdelta := idelta / fM
  else
    idelta := fdelta * fM;
  if fdelta = 0 then
    Exit;
  ShiftMinMax(fdelta);
  if abs(fdelta) > fInterval then
    CalcTicksVal
  else
  begin
    if (fFlags and (sdfNoTicksLabel or sdfNotAjustedTicks)) = 0 then
      SLbldTicksVal(fdelta)
    else
      STicksVal(idelta);
  end;
  CalcTicksPos;
end;

function Tsp_Scale.TickLabel(tickNum: integer): string;
begin
  if ((fFlags and sdfLabelAsDate) <> 0) then
    Result := FormatDateTime(fLabelFormat, TksDbl(tickNum))
  else
    Result := FormatFloat(fLabelFormat, TksDbl(tickNum));
end;

function Tsp_Scale.GetTicksCount: byte;
begin
  Result := rTksCount;
end;

procedure Tsp_Scale.SetFlagBit(const BN: integer; const OnOff: boolean);
var
  Mask: integer;
begin
  Mask := 1 shl BN;
  if OnOff then
  begin
    if ((fFlags and Mask) = 0) then
    begin
      fFlags := fFlags or Mask;
      FlagsChanged(BN, OnOff);
    end;
  end
  else
  if ((fFlags and Mask) <> 0) then
  begin
    fFlags := fFlags and not Mask;
    FlagsChanged(BN, OnOff);
  end;
end;

procedure Tsp_Scale.ReSetFlagBit(const BN: integer; const Off: boolean);
begin
  SetFlagBit(BN, not (Off));
end;

function Tsp_Scale.NotFlagBit(const BN: integer): boolean;
begin
  Result := (fFlags and (1 shl BN)) = 0;
end;

function Tsp_Scale.GetFlagBit(const BN: integer): boolean;
begin
  Result := (fFlags and (1 shl BN)) <> 0;
end;

procedure Tsp_Scale.FlagsChanged(const BN: integer; const OnOff: boolean);
begin
end;

constructor Tsp_Scale.Create(Flags: integer);
begin
  inherited Create;
  fLineAttr := Tsp_LineAttr.Create;
  fTicksCount := 5;
  fFlags := Flags;
  fLabelFormat := '###0.##';
  fO.x := 10;
  fO.y := 30;
  fLen := 25;
  ChangeMinMax(dblDfltAxisMin, dblDfltAxisMax);
end;

destructor Tsp_Scale.Destroy;
begin
  if Assigned(fLineAttr) then
    fLineAttr.Free;
  inherited Destroy;
end;

procedure Tsp_Scale.SetLine(oX, oY, lLen: integer);
begin
  if (fO.x <> oX) or (fO.y <> oY) or (lLen <> fLen) then
  begin
    fO.x := oX;
    fO.y := oY;
    if lLen = 0 then
      Inc(lLen)
    else if lLen < 0 then
      lLen := -lLen;
    fLen := lLen;
    CalcMetr;
    CalcTicksPos;
  end;
end;

procedure Tsp_Scale.ChangeMinMax(aMin, aMax: double);
begin
  FixMinMax(aMin, aMax);
  CalcMetr;
  CalcTicksVal;
  CalcTicksPos;
end;

procedure Tsp_Scale.ScrollBy(delta: integer);
begin
  ShiftScaleBy(True, delta, 0);
end;

function Tsp_Scale.V2P(const V: double): integer;
var
  rr: double;
begin
  rr := fOPos + (fM * (V - fOVal));
  if rr > 16383 then
    Result := 16383
  else if rr < -16383 then
    Result := -16383
  else
    Result := round(rr);
end;

function Tsp_Scale.P2V(const V: integer): double;
begin
  Result := fOVal + (V - fOPos) / fM;
end;

const
  TickOfs = 0;
  MnTick = 2;
  MjTick = 5;
  LblOfs = 1;

function Tsp_Scale.BandWidth(FntWidth, FntHeight: integer): integer;
var
  j, tw: integer;
begin
  Result := fLineAttr.Width;
  if (FFlags and sdfVertical) = 0 then
  begin
    if (rTksCount > 0) then
    begin
      if ((FFlags and sdfNoTicksLabel) = 0) then
        Inc(Result, TickOfs + MjTick + LblOfs + FntHeight)
      else if (FFlags and sdfNoTicks) = 0 then
        Inc(Result, TickOfs + MjTick);
    end;
  end
  else
  begin
    //Result := fLineAttr.Width;    2021
    if (rTksCount > 0) then
    begin
      if ((FFlags and sdfNoTicksLabel) = 0) then
      begin
        tw := Length(TickLabel(0));
        for j := 1 to rTksCount - 1 do
          if tw < Length(TickLabel(j)) then
            tw := Length(TickLabel(j));
        Inc(Result, TickOfs + MjTick + LblOfs + tw * FntWidth);
      end
      else if (FFlags and sdfNoTicks) = 0 then
        Inc(Result, TickOfs + MjTick);
    end;
  end;
end;

function Tsp_Scale.OrgIndent(FntWidth, FntHeight: integer): integer;
var
  tp: integer;
begin
  if (rTksCount > 0) and ((FFlags and sdfNoTicksLabel) = 0) then
  begin
    tp := abs(round((fOVal - TksDbl(0)) * fM));
    if (FFlags and sdfVertical) = 0 then
      Result := FntWidth * Length(TickLabel(0)) div 2 - tp
    else
      Result := FntHeight div 2 - tp;
    if Result < 0 then
      Result := 0;
  end
  else
    Result := 0;
end;

function Tsp_Scale.EndIndent(FntWidth, FntHeight: integer): integer;
var
  tp: integer;
begin
  if (rTksCount > 0) and ((FFlags and sdfNoTicksLabel) = 0) then
  begin
    if (fFlags and sdfInversed) = 0 then
      tp := abs(round((fMax - TksDbl(rTksCount - 1)) * fM))
    else
      tp := abs(round((fMin - TksDbl(rTksCount - 1)) * fM));
    if (FFlags and sdfVertical) = 0 then
      Result := FntWidth * Length(TickLabel(rTksCount - 1)) div 2 - tp
    else
      Result := FntHeight div 2 - tp;
    if Result < 0 then
      Result := 0;
  end
  else
    Result := 0;
end;
{
function Tsp_Scale.CalcDrawBounds(fCanvas: TCanvas): TRect;
var
  j, ti: integer;
begin
  with Result do
    with fCanvas do
    begin
      if (FFlags and sdfVertical) = 0 then
      begin
        ti := fLineAttr.Width;
        if (rTksCount > 0) and ((FFlags and sdfNoTicksLabel) = 0) then
        begin
          Inc(ti, TickOfs + MjTick + LblOfs + TextHeight('8'));
          Left := fTksPos[0] - TextWidth(TickLabel(0)) div 2;
          Right := fTksPos[rTksCount - 1] +
                     TextWidth(TickLabel(rTksCount - 1)) div 2;
        end
        else if (FFlags and sdfNoTicks) = 0 then
          Inc(ti, TickOfs + MjTick);
        if (FFlags and sdfLabelAtTop) = 0 then
          Top := fO.y
        else
          Top := fO.y - ti + 1;
        Bottom := Top + ti;
        if Left > fO.x then
          Left := fO.x;
        if Right < fO.x + fLen then
          Right := fO.x + fLen + 1;
      end
      else
      begin
        ti := fLineAttr.Width;
        if (rTksCount > 0) and ((FFlags and sdfNoTicksLabel) = 0) then
        begin
          ti := TextWidth(TickLabel(0));
          for j := 1 to rTksCount - 1 do
            if ti < TextWidth(TickLabel(j)) then
              ti := TextWidth(TickLabel(j));
          Inc(ti, TickOfs + MjTick + LblOfs);
          Top := fTksPos[rTksCount - 1] - TextHeight('8') div 2;
          Bottom := fTksPos[0] + TextHeight('8') div 2;
        end
        else if (FFlags and sdfNoTicks) = 0 then
          Inc(ti, TickOfs + MjTick);
        if (FFlags and sdfLabelOnRight) = 0 then
          Left := fO.x - ti + 1
        else
          Left := fO.x;
        Right := Left + ti;
        if Top > (fO.y - fLen) then
          Top := fO.y - fLen;
        if Bottom < fO.y then
          Bottom := fO.y + 1;
      end;
    end;
end;
}
procedure Tsp_Scale.DrawLine(fCanvas: TCanvas; odec, einc: word);
var
  j, st, w, b, e: integer;
begin
  with fLineAttr do
    if Visible then
      with fCanvas do
      begin
        Pen.Color := fLineAttr.Color;
        Pen.Style := Style;
        Pen.Width := 1;
        Pen.Mode := pmCopy;
        if (fFlags and sdfRevertTicks) = 0 then
          st := 1
        else
          st := -1;
        if (FFlags and sdfVertical) = 0 then
        begin
          w := fO.y;
          b := fO.x - odec;
          e := fO.x + fLen + 1 + einc;
          for j := 1 to fLineAttr.Width do
          begin
            MoveTo(b, w);
            LineTo(e, w);
            Inc(w, st);
          end;
        end
        else
        begin
          w := fO.x;
          e := fO.y + 1 + odec;
          b := fO.y - fLen - einc;
          for j := 1 to fLineAttr.Width do
          begin
            MoveTo(w, b);
            LineTo(w, e);
            Dec(w, st);
          end;
        end;
      end;
end;

procedure Tsp_Scale.DrawTicks;

  procedure DrawVert;
  var
    j: word;
    x, l: integer;
    LS: string;
    LW: integer;
  begin
    with fCanvas do
    begin
      if ((FFlags and sdfNoTicks) = 0) and (rTksCount > 0) then
      begin
        if (FFlags and sdfLabelOnRight) = 0 then
        begin
          x := fO.x - TickOfs - fLineAttr.Width;
          l := x - MjTick;
        end
        else
        begin
          x := fO.x + TickOfs + fLineAttr.Width;
          l := x + MjTick;
        end;
        for j := 0 to rTksCount - 1 do
        begin
          MoveTo(x, fTksPos[j]);
          LineTo(l, fTksPos[j]);
        end;
      end;
      if ((FFlags and sdfNoTicksLabel) = 0) and (rTksCount > 0) then
      begin
        l := TextHeight('8') div 2;
        if (FFlags and sdfLabelOnRight) = 0 then
        begin
          x := fO.x - TickOfs - fLineAttr.Width - MjTick - LblOfs;
          for j := 0 to rTksCount - 1 do
          begin
            LS := TickLabel(j);
            LW := TextWidth(LS);
            TextOut(x - LW, fTksPos[j] - l, LS);
          end;
        end
        else
        begin
          x := fO.x + TickOfs + fLineAttr.Width + MjTick + LblOfs;
          for j := 0 to rTksCount - 1 do
          begin
            TextOut(x, fTksPos[j] - l, TickLabel(j));
          end;
        end;
      end;
    end;
  end;

  procedure DrawHoriz;
  var
    j: word;
    y, l: integer;
    LS: string;
    LW: integer;
  begin
    with fCanvas do
    begin
      if ((FFlags and sdfNoTicks) = 0) and (rTksCount > 0) then
      begin
        if (FFlags and sdfLabelAtTop) = 0 then
        begin
          y := fO.y + TickOfs + fLineAttr.Width;
          l := y + MjTick;
        end
        else
        begin
          y := fO.y - TickOfs - fLineAttr.Width;
          l := y - MjTick;
        end;
        for j := 0 to rTksCount - 1 do
        begin
          MoveTo(fTksPos[j], y);
          LineTo(fTksPos[j], l);
        end;
      end;
      if ((FFlags and sdfNoTicksLabel) = 0) and (rTksCount > 0) then
      begin
        if (FFlags and sdfLabelAtTop) = 0 then
          y := fO.y +TickOfs +fLineAttr.Width +MjTick + LblOfs
        else
          y := fO.y -TickOfs -fLineAttr.Width -MjTick - LblOfs-TextHeight('8');
        for j := 0 to rTksCount - 1 do
        begin
          LS := TickLabel(j);
          LW := TextWidth(LS);
          TextOut(fTksPos[j] - LW div 2, y, LS);
        end;
      end;
    end;
  end;

begin
  if (fFlags and sdfLineOnly) = sdfLineOnly then
    Exit;
  if (FFlags and sdfVertical) = 0 then
    DrawHoriz
  else
    DrawVert;
end;

END.

unit sgr_point;

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

{***************************************************
 TPointKind, TDrawPointProc, Tsp_PointAttr
 for series points drawing
***************************************************}
{:}

type
  // ptCustom has will has special meaning
  TPointKind = (ptCustom, ptRectangle, ptEllipse, ptDiamond, ptCross,
                ptTriangle, ptDownTriangle{, ptBra, ptKet});

  // Type of draw point procedure
  TDrawPointProc = procedure(const x, y: integer) of object;

  { Tsp_PointAttr }

  Tsp_PointAttr = class(TBrush)
  private
    fPtCanvas: TCanvas;  // Canvas where points are drawn
    fBorderColor: TColor;
    fBorderWidth: integer;
    fHSize, fVSize: integer;  //even half of horiz. & vert. point size
    fHSize1, fVSize1: integer;  //odd half of horiz. & vert. point size
    fPointType: TPointKind;
    fVisible: boolean;
  protected
    procedure SetType(const V: TPointKind);
    procedure SetVisible(const V: boolean);
    procedure SetHSize(V: integer);
    procedure SetVSize(V: integer);
    function GetHSize: integer;
    function GetVSize: integer;
    procedure SetBorderWidth(V: integer);
    procedure SetBorderColor(const V: TColor);
  public
   {$IFDEF FPC}
    constructor Create; override; // Lz = Lazarus
   {$ELSE}
    constructor Create;
   {$ENDIF}
    procedure SetCanvas(aCanvas: TCanvas);

    procedure DrawX(const x, y: integer);
    procedure DrawRect(const x, y: integer);
    procedure DrawEllipse(const x, y: integer);
    procedure DrawDiamond(const x, y: integer);
    procedure DrawCross(const x, y: integer);
    procedure DrawTriangle(const x, y: integer);
    procedure DrawDownTriangle(const x, y: integer);

    function  GetDrawPointProc(PtKind: TPointKind): TDrawPointProc;

    procedure Assign(Source: TPersistent); override;
    procedure Rescale(ScaleFactor: double); //2021
    property eHSize: integer read fHSize;
    property oHSize: integer read fHSize1;
    property eVSize: integer read fVSize;
    property oVSize: integer read fVSize1;
    //is points are drawn
  published
    //kind of point
    property Kind: TPointKind read fPointType write SetType default ptRectangle;
    //horizontal size of Point
    property HSize: integer read GetHSize write SetHSize default 5;
    //vertical size of Point
    property VSize: integer read GetVSize write SetVSize default 5;
    //is points are drawn
    property Visible: boolean read fVisible write SetVisible;
    //points border width (pen)
    property BorderWidth: integer read fBorderWidth write SetBorderWidth default 1;
    //points border color (pen)
    property BorderColor: TColor read fBorderColor write SetBorderColor default clBlack;
  end;


implementation

{*** Tsp_PointAttr ***}

constructor Tsp_PointAttr.Create;
begin
  inherited;
  fPointType:= ptRectangle;
  fVSize := 2;
  fVSize1 := 3;
  fHSize := 2;
  fHSize1 := 3;
  fBorderColor := clBlack;
  fBorderWidth := 1;
end;

{procedure Tsp_PointAttr.SetPenAttr(const APen: TPen);
begin
  with APen do
  begin
    Color := fBorderColor;
    Width := fBorderWidth;
    Style := psSolid;
    Mode := pmCopy;
  end;
end; }

procedure Tsp_PointAttr.SetCanvas(aCanvas: TCanvas);
begin
  fPtCanvas:= aCanvas;
  with fPtCanvas.Pen do
  begin
    Color := fBorderColor;
    Width := fBorderWidth;
    Style := psSolid;
    Mode := pmCopy;
  end;
  fPtCanvas.Brush.Assign(Self);
end;

procedure Tsp_PointAttr.SetType(const V: TPointKind);
begin
  if fPointType <> V then
  begin
    fPointType := V;
    Changed;
  end;
end;

procedure Tsp_PointAttr.SetVisible(const V: boolean);
begin
  if fVisible <> V then
  begin
    fVisible := V;
    Changed;
  end;
end;

procedure Tsp_PointAttr.Assign(Source: TPersistent);
var
  ss: Tsp_PointAttr;
begin
  if Source is Tsp_PointAttr then
  begin
    ss := Source as Tsp_PointAttr;
    Kind := ss.Kind;
    Visible := ss.Visible;
    HSize := ss.HSize;
    VSize := ss.VSize;
    SetBorderColor(ss.BorderColor);
    SetBorderWidth(ss.BorderWidth);
  end;
  inherited Assign(Source);
end;

procedure Tsp_PointAttr.Rescale(ScaleFactor: double);
var
  lw: integer;
begin
  lw:=sp_ReScaleInt(HSize, ScaleFactor);
  SetHSize(lw);
  lw:=sp_ReScaleInt(VSize, ScaleFactor);
  SetVSize(lw);
end;

procedure Tsp_PointAttr.SetHSize(V: integer);
begin
  if V < 0 then
    V := 1;
  V := V div 2;
  if eHSize <> V then
  begin
    fHSize := V;
    fHSize1 := V + 1;
    Changed;
  end;
end;

procedure Tsp_PointAttr.SetVSize(V: integer);
begin
  if V < 0 then
    V := 1;
  V := V div 2;
  if eVSize <> V then
  begin
    fVSize := V;
    fVSize1 := V + 1;
    Changed;
  end;
end;

function Tsp_PointAttr.GetHSize: integer;
begin
  Result := fHSize + fHSize1;
end;

function Tsp_PointAttr.GetVSize: integer;
begin
  Result := fVSize + fVSize1;
end;

procedure Tsp_PointAttr.SetBorderWidth(V: integer);
begin
  if V < 0 then
    V := 1;
  if V > fHSize then
    V := fHSize;
  if V > fVSize then
    V := fVSize;
  if fBorderWidth <> V then
  begin
    fBorderWidth := V;
    Changed;
  end;
end;

procedure Tsp_PointAttr.SetBorderColor(const V: TColor);
begin
  if fBorderColor <> V then
  begin
    fBorderColor := V;
    Changed;
  end;
end;

procedure Tsp_PointAttr.DrawRect(const x, y: integer);
//var B: TBrush;
begin
  //if fPtCanvas.Brush.Style = bsClear then
    fPtCanvas.Rectangle(x - eHSize, y - eVSize, x + oHSize, y + eVSize + 1);
end;

procedure Tsp_PointAttr.DrawEllipse(const x, y: integer);
begin
    fPtCanvas.Ellipse(x - eHSize, y - eVSize, x + oHSize, y + oVSize);
end;

procedure Tsp_PointAttr.DrawDiamond(const x, y: integer);
begin
    fPtCanvas.Polygon([Point(x, y - eVSize), Point(x + eHSize, y),
      Point(x, y + eVSize), Point(x - eHSize, y)]);
end;

procedure Tsp_PointAttr.DrawCross(const x, y: integer);
begin
  with fPtCanvas do
  begin
    MoveTo(x - eHSize, y);
    LineTo(x + oHSize, y);
    MoveTo(x, y - eVSize);
    LineTo(x, y + oVSize);
  end;
end;

procedure Tsp_PointAttr.DrawX(const x, y: integer);
begin
  with fPtCanvas do
  begin
    MoveTo(x - eHSize, y - eVSize);
    LineTo(x + oHSize, y + oVSize);
    MoveTo(x - eHSize, y + oVSize);
    LineTo(x + oHSize, y - eVSize);
  end;
end;

procedure Tsp_PointAttr.DrawTriangle(const x, y: integer);
begin
    fPtCanvas.Polygon([Point(x, y - eVSize), Point(x + eHSize, y + eVSize),
      Point(x - eHSize, y + eVSize)]);
end;

procedure Tsp_PointAttr.DrawDownTriangle(const x, y: integer);
begin
    fPtCanvas.Polygon([Point(x - eHSize, y - eVSize), Point(x + eHSize, y - eVSize),
      Point(x, y + eVSize)]);
end;


function Tsp_PointAttr.GetDrawPointProc(PtKind: TPointKind): TDrawPointProc;
begin
  case PtKind of
    ptCustom: Result := DrawX;
    ptRectangle: Result := DrawRect;
    ptEllipse: Result := DrawEllipse;
    ptDiamond: Result := DrawDiamond;
    ptCross: Result := DrawCross;
    ptTriangle: Result := DrawTriangle;
    ptDownTriangle: Result := DrawDownTriangle;
    else
      Result := DrawX;
  end;
end;


end.


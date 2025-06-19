unit sgr_line;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{ (c) S.P.Pod'yachev 1998 - 2025 } 

interface

uses
{$IFDEF FPC}
  LCLIntf, LCLType,
  SysUtils, Classes, Graphics;
{$ELSE}
  WinApi.Windows,
  System.SysUtils,  System.Classes,
  Vcl.Graphics;
{$ENDIF}

{*************************************************************
 unit created 10.2022 by separation line attribute.

 Tsp_CustomLineAttr - auxiliary persistent object for using in
     components with scale and axis and series line.

 function sp_ReScaleInt(W:integer; ScaleFctr:double): integer;
     Introduce auxiliary sacling for HDPI support
**************************************************************}
{:}

function sp_ReScaleInt(W:integer; ScaleFctr:double): integer;
//do not permit decrease W>0 to less than 1

type

  { Tsp_CustomLineAttr }

  Tsp_CustomLineAttr = class(TPersistent)
  private
    fColor: TColor;
    fStyle: TPenStyle;
    fWidth: word;
    fMode: TPenMode;
    fVisible: boolean;
    fOnChange: TNotifyEvent;
    procedure SetColor(const V: TColor);
    procedure SetStyle(const V: TPenStyle);
    procedure SetWidth(const V: word);
    procedure SetMode(const V: TPenMode);
    procedure SetVisible(const V: boolean);
  protected
    procedure Changed; virtual;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;
    procedure SetPenAttr(const APen: TPen); //set line attr to pen
    procedure Rescale(ScaleFactor: double); //2021
    property Color: TColor read fColor write SetColor;
    property Style: TPenStyle read fStyle write SetStyle;
    property Width: word read fWidth write SetWidth;
    property Mode: TPenMode read fMode write SetMode;
    property Visible: boolean read fVisible write SetVisible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  Tsp_LineAttr = class(Tsp_CustomLineAttr)
  public
    function IsSame(const LA: Tsp_CustomLineAttr): boolean;
  published
    property Color;
    property Style default psSolid;
    property Width default 1;
    property Visible;
  end;


implementation

//do not permit decrease w>0 to less than 1
  function sp_ReScaleInt(W:integer; ScaleFctr:double): integer;
  begin
    Result := round(w*ScaleFctr);
    if Result=0 then
      if w>0 then
         Result:=1
      else if w<0 then
        Result:= -1
  end;

{*** Tsp_CustomLineAttr ***}
procedure Tsp_CustomLineAttr.Changed;
begin
  if Assigned(fOnChange) then
    fOnChange(Self);
end;

procedure Tsp_CustomLineAttr.SetColor(const V: TColor);
begin
  if V <> fColor then begin
    fColor := V;
    Changed;
  end;
end;

procedure Tsp_CustomLineAttr.SetStyle(const V: TPenStyle);
begin
  if V <> fStyle then begin
    fStyle := V;
    Changed;
  end;
end;

procedure Tsp_CustomLineAttr.SetWidth(const V: word);
begin
  if V <> fWidth then begin
    fWidth := V;
    Changed;
  end;
end;

procedure Tsp_CustomLineAttr.SetVisible(const V: boolean);
begin
  if V <> fVisible then begin
    fVisible := V;
    Changed;
  end;
end;

procedure Tsp_CustomLineAttr.SetMode(const V: TPenMode);
begin
  if V <> fMode then begin
    fMode := V;
    Changed;
  end;
end;

constructor Tsp_CustomLineAttr.Create;
begin
  inherited Create;
  fOnChange := nil;
  fColor := clBlack;
  fStyle := psSolid;
  fWidth := 1;
  fVisible := True;
end;

procedure Tsp_CustomLineAttr.Assign(Source: TPersistent);
var
  ss: Tsp_CustomLineAttr;
begin
  if Source is Tsp_CustomLineAttr then
  begin
    ss := Tsp_CustomLineAttr(Source);
    fColor := ss.fColor;
    fStyle := ss.fStyle;
    fWidth := ss.fWidth;
    fVisible := ss.fVisible;
  end
  else
    inherited Assign(Source);
end;

procedure Tsp_CustomLineAttr.AssignTo(Dest: TPersistent);
begin
  if Dest is Tsp_CustomLineAttr then
    Dest.Assign(Self)
  else
    inherited AssignTo(Dest);
end;

procedure Tsp_CustomLineAttr.SetPenAttr(const APen: TPen);
begin
  with APen do
  begin
    Color := fColor;
    Style := fStyle;
    Width := fWidth;
    Mode := pmCopy;
  end;
end;


procedure Tsp_CustomLineAttr.Rescale(ScaleFactor: double); //2021
var lw: integer;
begin
  lw:= sp_ReScaleInt(fWidth, ScaleFactor);
  SetWidth(lw);
end;

function Tsp_LineAttr.IsSame(const LA: Tsp_CustomLineAttr): boolean;
begin
  with LA do
    Result := (fColor = Color) and (fStyle = Style) and (fWidth = Width) and
      (fVisible = Visible);
end;

end.


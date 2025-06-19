unit sgr_mark;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{ (c) S.P.Pod'yachev 1998 - 2025 }

interface
uses
{$IFnDEF FPC}
  WinApi.Windows,
  VCL.Graphics,
{$ELSE}
  LCLIntf, LCLType, Graphics,
{$ENDIF}
  SysUtils,  Classes,
  sgr_line, sgr_def;

{***************************************************}
{ Example of marker for Tsp_xyPlot                  }
{ Tsp_LineMarker - infinite vertical or horizontal  }
{                  line on the plot field           }
{ Tsp_ImageMarker - image on the plot field,        }
{                   can be used as background map   }
{***************************************************}
{:}

Type

{*** Tsp_LineMarker ***}

//line oreintation
Tsp_LMOrientation=(loVertical, loHorizontal);

//infinite vertical or horizontal line on the plot field

{ Tsp_LineMarker }

Tsp_LineMarker=class(Tsp_PlotMarker)
protected
  fPen:TPen;
  fBrush:TBrush;
  fOX :double; //position
  fLO:Tsp_LMOrientation;
  procedure SetBrush(const V:TBrush);
  procedure SetPen(const V:TPen);
  procedure AttrChanged(V:TObject);
  procedure SetOX(const V:double);
  procedure SetLO(const V:Tsp_LMOrientation);
public
  constructor Create(AOwner:TComponent);override;
  destructor Destroy;override;
  procedure Rescale(ScaleFactor: double); override;
  procedure Draw; override;
published
  property Pen:TPen read fPen write SetPen;
  property Brush:TBrush read fBrush write SetBrush;
  property Position:double read fOX write SetOX;
  property Orientation :Tsp_LMOrientation read fLO write SetLO default loVertical;
  property Visible default True;
end;


{*** Tsp_ImageMarker ***}

//image on the plot field, can be used as map

{ Tsp_ImageMarker }

Tsp_ImageMarker=class(Tsp_PlotMarker)
protected
  fOX, fOY,        //fist corner position
  fRX, fRY:double; //opposite corner position
  fStretch:boolean;
  fPicture:TPicture;
  procedure SetPicture(Value: TPicture);
  procedure AttrChanged(V:TObject);
  procedure SetStretch(V:boolean);
  procedure SetX(const V:double);
  procedure SetXR(const V:double);
  procedure SetY(const V:double);
  procedure SetYR(const V:double);
public
  constructor Create(AOwner:TComponent);override;
  destructor Destroy;override;
  procedure Rescale(ScaleFactor: double); override;
  procedure Draw; override;
published
  property Picture:TPicture read fPicture write SetPicture;
  property X:double read fOX write SetX;
  property Y:double read fOY write SetY;
  property Stretch:boolean read fStretch write SetStretch default False;
  property StretchX:double read fRX write SetXR;
  property StretchY:double read fRY write SetYR;
  property Visible default True;
end;


IMPLEMENTATION


{*** Tsp_LineMarker ***}

procedure Tsp_LineMarker.SetOX(const V:double);
begin
 if fOX<>V then begin
   fOX:=V; mInvalidatePlot;
 end;
end;

procedure Tsp_LineMarker.SetLO(const V:Tsp_LMOrientation);
begin
 if fLO<>V then begin
   fLO:=V; mInvalidatePlot;
 end;
end;

procedure Tsp_LineMarker.SetBrush(const V:TBrush);
begin
   fBrush.Assign(V);
end;

procedure Tsp_LineMarker.SetPen(const V:TPen);
begin
   fPen.Assign(V);
end;

procedure Tsp_LineMarker.AttrChanged(V:TObject);
begin
  mInvalidatePlot;
end;

constructor Tsp_LineMarker.Create(AOwner:TComponent);
begin
 inherited Create(AOwner);
 fOX:=0;
 fPen:=TPen.Create;
 fBrush:=TBrush.Create;
 fPen.OnChange:=AttrChanged;
 fBrush.OnChange:=AttrChanged;
 fVisible:=True;
end;

destructor Tsp_LineMarker.Destroy;
begin
 if Assigned(fPen) then begin
  fPen.OnChange:=nil;
  fPen.Free;
 end;
 if Assigned(fBrush) then begin
  fBrush.OnChange:=nil;
  fBrush.Free;
 end;
 inherited;
end;

procedure Tsp_LineMarker.Rescale(ScaleFactor: double);
var lw: integer;
begin
  lw:= sp_ReScaleInt(fPen.Width, ScaleFactor);
  fPen.Width:= lw;
end;

procedure Tsp_LineMarker.Draw;

  procedure dVertLine;
  var p:integer;
  begin
    p:=XAxisObj.V2P(fOX);
    with Plot.DCanvas, Plot.FieldRect do begin
      if (p>Right+fPen.Width-1) or (p<Left-fPen.Width) then Exit;
      Pen.Assign(fPen);
      Brush.Assign(fBrush);
      MoveTo(p,Top);
      LineTo(p,Bottom);
   end;
  end;

  procedure dHorizLine;
  var p:integer;
  begin
    p:=YAxisObj.V2P(fOX);
    with Plot.DCanvas, Plot.FieldRect do begin
      if (p>Bottom+fPen.Width-1) or (p<Top-fPen.Width+1) then Exit;
      Pen.Assign(fPen);
      Brush.Assign(fBrush);
      MoveTo(Left,p);
      LineTo(Right,p);
   end;
  end;

begin   //Tsp_LineMarker.Draw;
 if Not(Assigned(Plot)) then Exit;
 if fLO=loVertical then dVertLine else dHorizLine;
end;


{*** Tsp_ImageMarker ***}

procedure Tsp_ImageMarker.SetPicture(Value: TPicture);
begin
 fPicture.Assign(Value);
end;

procedure Tsp_ImageMarker.AttrChanged(V:TObject);
begin
  mInvalidatePlot;
end;

procedure Tsp_ImageMarker.SetStretch(V:boolean);
begin
 if fStretch<>V then begin
   fStretch:=V; mInvalidatePlot;
 end;
end;

procedure Tsp_ImageMarker.SetX(const V:double);
begin
 if fOX<>V then begin
   fOX:=V; mInvalidatePlot;
 end;
end;

procedure Tsp_ImageMarker.SetXR(const V:double);
begin
 if fRX<>V then begin
   fRX:=V; mInvalidatePlot;
 end;
end;

procedure Tsp_ImageMarker.SetY(const V:double);
begin
 if fOY<>V then begin
   fOY:=V; mInvalidatePlot;
 end;
end;

procedure Tsp_ImageMarker.SetYR(const V:double);
begin
 if fRY<>V then begin
   fRY:=V; mInvalidatePlot;
 end;
end;

constructor Tsp_ImageMarker.Create(AOwner:TComponent);
begin
 inherited Create(AOwner);
 fOX:=0; fOY:=0;
 fRX:=1; fRY:=1;
 fPicture := TPicture.Create;
 fPicture.OnChange:=AttrChanged;
 fVisible:=True;
end;

destructor Tsp_ImageMarker.Destroy;
begin
 fPicture.Free;
 inherited;
end;

procedure Tsp_ImageMarker.Rescale(ScaleFactor: double);
begin
  //Nothing to do
end;

procedure Tsp_ImageMarker.Draw;
  procedure AlignInt(var t,b:integer); //swap if need
  var i:integer;
  begin
    if t>b then begin i:=t; t:=b; b:=i; end
  end;
  function GetDrawRect:TRect; //calc draw rect posion
  begin
   with Result do begin
     Top:=YAxisObj.V2P(fOY);
     Bottom:=YAxisObj.V2P(fRY);
     Left:=XAxisObj.V2P(fOX);
     Right:=XAxisObj.V2P(fRX);
     AlignInt(Top,Bottom);
     AlignInt(Left,Right);
   end;
  end;
  procedure dImage;
  var R,DR:TRect;
  begin
   with R do begin
     Top:=YAxisObj.V2P(fOY);
     Left:=XAxisObj.V2P(fOX);
     Bottom:=Top+fPicture.Height;
     Bottom:=Top+fPicture.Width;
   end;
   DR:=Plot.FieldRect;    //to do
   if IntersectRect(DR,R,DR) then with R do begin
      Plot.DCanvas.Draw(Left, Top, fPicture.Graphic);
   end;
  end;
  procedure dImageInRect;
  var R,DR:TRect;
  begin
   R:=GetDrawRect;
   DR:=Plot.FieldRect;    //to do
   if IntersectRect(DR,R,DR) then with DR do begin
      Plot.DCanvas.StretchDraw(R, fPicture.Graphic);
   end;
  end;
begin //Tsp_ImageMarker.Draw;
 if Not(Assigned(Plot)) then Exit;
 if fStretch then dImageInRect else dImage;
end;

END.

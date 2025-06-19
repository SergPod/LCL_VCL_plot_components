unit xyplot_form_d12;

{ (c) S.P.Pod'yachev 1998 - 2025 }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  sgr_point, sgr_def, sgr_xydata_series, sgr_mark, set_axis_dlg_d12;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    ckbDoOnFieldDraw: TCheckBox;
    BGImage: TImage;
    Button1: TButton;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ckbDoOnFieldDrawClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    tcnt: integer;
  protected
    procedure XYPlotFieldDraw(Sender: TObject);
    procedure XYPlotMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CreateXYPlot;
    procedure CreateXYSeries;
  public
    plt: Tsp_XYPlot;
    xyL: Tsp_XYLine;
    vLM, hLM: Tsp_LineMarker;
    const n=50;
  end;
var
  Form1: TForm1;

implementation

{$R *.dfm}


procedure TForm1.CreateXYPlot;
begin
  plt:= Tsp_XYPlot.Create(Self);
  plt.DoubleBuffered:= True;
  plt.Parent := Self;
  plt.Align:= alClient;
  plt.FieldColor:= $00EECCCC; //clCream clMoneyGreen
  plt.LeftAxis.Caption:='Left Axis';
  plt.BottomAxis.Caption:='Bottom Axis';
  plt.BottomAxis.Margin:=0;
  plt.TopAxis.Caption:='Top Axis';
  plt.TopAxis.Margin:= -5;
  plt.RightAxis.Caption:='Right Axis';
  plt.RightAxis.FixedBandWidth:= 32;
  if ckbDoOnFieldDraw.Checked then
    plt.OnFieldDraw := XYPlotFieldDraw;
  plt.OnMouseUp := XYPlotMouseUp;
end;

procedure TForm1.CreateXYSeries;
begin
  xyL:= Tsp_XYLine.Create(Self);
  xyL.LineAttr.Color:= clMaroon;
  xyL.LineAttr.Width:=2;
  xyL.PointAttr.VSize:= 11;
  xyL.PointAttr.HSize:= 11;
  xyL.PointAttr.Kind:= ptDiamond;
  xyL.PointAttr.Color:=clYellow;
  xyL.PointAttr.Visible := True;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  CreateXYPlot;
  CreateXYSeries;
  xyL.Plot:= plt;
  vLM:= Tsp_LineMarker.Create(Self);
  hLM:= Tsp_LineMarker.Create(Self);
  vLM.Orientation:= loVertical;
  hLM.Orientation:= loHorizontal;
  vlM.WhenDraw:= dmAfterSeries;
  hlM.WhenDraw:= dmBeforeSeries;
  vlM.Pen.Color:= clRed;
  vlM.Pen.Style:= psDash;
  hlM.Pen.Color:= clBlue;
  hlM.Pen.Style:= psDash;
  vLM.Plot:= plt;
  hLM.Plot:= plt;
  if (Screen.PixelsPerInch <> PixelsPerInch) then
    plt.Rescale(Screen.PixelsPerInch / PixelsPerInch);
end;


procedure TForm1.FormShow(Sender: TObject);
var i: integer; x, y: double;
const d = 3*3.14159/n;
begin
  if xyL.Count<1 then
  begin
    xyL.LockInvalidate:= True;
    for i:=0 to n do
    begin
      x:= d*i;
      y:= 5+5*sin(x);
      xyL.AddXY(x, y);
    end;
    xyL.LockInvalidate:= False;
    vLM.Position:= x;
    hLM.Position:= y;
  end;
end;


procedure TForm1.Button1Click(Sender: TObject);
begin
  SetAxisProperties(plt);
end;

procedure TForm1.ckbDoOnFieldDrawClick(Sender: TObject);
begin
  if ckbDoOnFieldDraw.Checked then
    plt.OnFieldDraw := XYPlotFieldDraw
  else
    plt.OnFieldDraw := nil;
  plt.Invalidate;
end;


procedure TForm1.XYPlotFieldDraw(Sender: TObject);
//OnFieldDraw handler draws bitmap texture
var BGBMP:TBitmap; w,h:integer;
begin
  BGBMP:=BGImage.Picture.Bitmap;
  with Sender as Tsp_xyPlot do
  with DCanvas, FieldRect do
  begin
      h:=Top;
      repeat
        w:=Left;
        repeat
          Draw(w,h, BGBMP);
          inc(w, BGBMP.Width);
        until w>Right;
        inc(h, BGBMP.Height);
      until h>Bottom
  end
end;
procedure TForm1.XYPlotMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
// set cros of the LineMarkers mouse click position
begin
  if (Shift = []) and (Button = mbLeft) then
     if PtInRect(plt.FieldRect, Point(X, Y)) then
     begin
       vLM.Position:= plt.BottomAxis.P2V(X);
       hLM.Position:= plt.LeftAxis.P2V(Y);
     end;
end;

end.

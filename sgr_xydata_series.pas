unit sgr_xydata_series; // previously named as "sgr_data"

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
  SysUtils, Classes,
  sgr_def,
  sgr_line, sgr_point, sgr_xydata;

  {***************************************************}
  { Examples of series for Tsp_xyPlot                 }
  {  Tsp_XYDataSeries ancestor of data series         }
  {  Tsp_XYLine, Tsp_SpectrLines                      }
  {***************************************************}
  {:}

type

  //ancestor of my data series
  //has storage for x, y data and maintains main method & properties for it

  { Tsp_XYDataSeries }

  Tsp_XYDataSeries = class(Tsp_PlotSeries)
  protected
    fXYDataPtr: Tsp_XYData;
    fInnerXYData: Tsp_XYData;
    //Draw attributes
    fLineAttr: Tsp_LineAttr; //line attribute
    //control service
    fLockInvalidate: boolean; //lock invalidate plot while data are changing

    //if can invalidate Plot then return True
    function CanPlot: boolean;
    //if it is possible then immediately redraw plot to reflect changes
    procedure TryUpdatePlotOnDataChange;
    procedure SetLockInvalidate(const V: boolean);
    //attributes change
    procedure SetLineAttr(const V: Tsp_LineAttr);
    procedure AtrributeChanged(V: TObject); virtual;
  public //Tsp_XYDataSeries
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //see Tsp_XYPlot.Rescale(ScaleFactor 2021
    procedure Rescale(ScaleFactor: double); override;
    //next 4 functions must be implemented for any series
    //**********************************************
    function GetXMin(var V: double): boolean; override;
    function GetXMax(var V: double): boolean; override;
    function GetYMin(var V: double): boolean; override;
    function GetYMax(var V: double): boolean; override;
    //**********************************************

  {this one does not free allocated memory, only set Count=0 and update Plot,
   AdjustCapacity after Clear, or SetCapacity(0) instead of Clear free memory}
    procedure Clear;
    //set minimum Capacity for current Count
    procedure AdjustCapacity;

  {use it if you know how many elements data will have and don't want to loose
   time on auto expand when add data. If series is not empty and C less then
   Count of data elements they will be truncated to fit capacity }
    procedure SetCapacity(C: integer);
    //add values at the end of series data and update Plot
    procedure AddXY(aX, aY: double);
    //used to add many values at the end of series data and update Plot
    //pX, pY must points to array of double, n - number of elements in arrays
    procedure AddXYArrays(pX, pY: pointer; n: integer);
    //insert values at index i, shift rest to end
    procedure InsertXY(i: integer; aX, aY: double);
    //replace values at index i
    procedure ReplaceXY(i: integer; aX, aY: double);
    //Delete values at index i
    procedure Delete(i: integer);
    //Delete values with indexes from fromi up to toi
    procedure DeleteRange(fromi, toi: integer);
    //current memory allocation for data elements (for example number of points)
    function Capacity: integer;
    //current number of valid data elements (for example number of points)
    function Count: integer;

    procedure UseExternalData(ExtData: Tsp_XYData);
    procedure UseInternalData();

    //lock invalidate plot while data are changing and then unlock it
    property LockInvalidate: boolean read fLockInvalidate write setLockInvalidate;

    //property Canvas: TCanvas read fCanvas write fCanvas;
  published
    //if True then series is visible and taken into account in AutoMin & AutoMax
    property Active default True;
  end;


  {*** Tsp_XYLine ***}

  // Draw custom point on Plot Canvas with postion at x, y for data #n
  TOnDrawPoint = procedure(aCanvas: TCanvas; n, x, y: integer) of object;
  // Draw custom point on Legend Canvas with central postion at x, y
  TOnDrawLegend = procedure(aCanvas: TCanvas; x, y: integer) of object;

  //draw data as points and/or chain of line segments

  { Tsp_XYLine }

  Tsp_XYLine = class(Tsp_XYDataSeries)
  protected
    fPtAttr: Tsp_PointAttr;
    fDrawPointProc: TDrawPointProc;
    fOnDrawPoint: TOnDrawPoint;
    fOnDrawLegend: TOnDrawLegend;
    procedure SetPointAttr(const V: Tsp_PointAttr);
    procedure AtrributeChanged(V: TObject); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Rescale(ScaleFactor: double); override;
    //implements series draw procedure
    procedure Draw; override;
    //implements series draw marker procedure
    procedure DrawLegendMarker(const LCanvas: TCanvas; MR: TRect); override;
    //add values at end like AddXY, but don't spend time to update Plot, instead
    //simply draw next line segment, therefore AutoMin and AutoMax are ignored
    procedure QuickAddXY(aX, aY: double); virtual;
    //to access to data
    function GetX(i: integer): double;
    function GetY(i: integer): double;
  published
    //defines is draw & how lines segments between points
    property LineAttr: Tsp_LineAttr read fLineAttr write SetLineAttr;
    //defines is draw & how lines points marker
    property PointAttr: Tsp_PointAttr read fPtAttr write SetPointAttr;
    //if assigned caled to draw point with Kind=ptCustom
    property OnDrawPoint: TOnDrawPoint read fOnDrawPoint write fOnDrawPoint;
    property OnDrawLegend: TOnDrawLegend read fOnDrawLegend write fOnDrawLegend;
  end;

  {*** Tsp_SpectrLines ***}

  Tsp_SpectrLines = class;

  Tsp_YOrigin = (yoBaseLine, yoXAxises);

  Tsp_WhatValues = (wvXValues, wvYValues);

  Tsp_GetLabelEvent = procedure(Sender: Tsp_SpectrLines; Num: integer;  //point number
    X, Y: double; //points values
    var LS: string) of object;   //label string

  //draw data as bar with center at XV pos. and height from Bottom
  //axis to YV or from BaseLine to YV;
  Tsp_SpectrLines = class(Tsp_XYDataSeries)
  private
    fBaseValue: double;
    fYOrigin: Tsp_YOrigin;
    fOnGetLabel: Tsp_GetLabelEvent; //customize label format handler
    fLabelFormat: string;       //format string for line label
    fLFont: TFont;               //label font
    fLVisible: boolean;          //is label visible
    fWhatValues: Tsp_WhatValues; //what values x or y use for label
    fBLVisible: boolean;         //is base line visible
    procedure SetBaseValue(V: double);
    procedure SetYOrigin(V: Tsp_YOrigin);
    procedure SetWhatValues(V: Tsp_WhatValues);
    procedure SetLabelFormat(const V: string);
    procedure SetLFont(V: TFont);
    procedure SetLVisible(const V: boolean);
    procedure SetBLVisible(const V: boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Draw; override;
    function GetYMin(var V: double): boolean; override;
    function GetYMax(var V: double): boolean; override;
  published
    //if YOrigin=yoBaseLine then lines begin from BaseValue
    property BaseYValue: double read fBaseValue write SetBaseValue;
    //define how lines are drawn
    property LineAttr: Tsp_LineAttr read fLineAttr write SetLineAttr;
    //if YOrigin=yoBaseLine then lines begin from BaseValue else from X Axis
    property YOrigin: Tsp_YOrigin read fYOrigin write SetYOrigin;
    //define X or Y values used in labels near spectral line
    property LabelValues: Tsp_WhatValues read fWhatValues write SetWhatValues;
    //format string to convert values to label text (template for FloatToStrF)
    property LabelFormat: string read fLabelFormat write SetLabelFormat;
    property LabelFont: TFont read fLFont write SetLFont;
    //show or not value label near line
    property ShowLabel: boolean read fLVisible write SetLVisible;
    //draw horizontal line at BaseYValue
    property ShowBaseLine: boolean read fBLVisible write SetBLVisible default True;
    //customize label format handler
    property OnGetLabel: Tsp_GetLabelEvent read fOnGetLabel write fOnGetLabel;
  end;


implementation

type
  TDbls = array [0..MaxInt div 16] of double;
  pDbls = ^TDbls;
  TLP = array[0..MaxInt div 16] of TPoint;
  pLP = ^TLP;

  {*** Tsp_XYDataSeries ***}

constructor Tsp_XYDataSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fActive := True;
  fInnerXYData := Tsp_XYData.Create;
  fXYDataPtr := fInnerXYData;
  if csDesigning in ComponentState then
    while fXYDataPtr.Count < 10 do
      fXYDataPtr.AddXY(fXYDataPtr.Count, 1 + 2 * (fXYDataPtr.Count mod 5) + Random(2));
  fLineAttr := Tsp_LineAttr.Create;
  fLockInvalidate := False;
  fLineAttr.OnChange := AtrributeChanged;
end;

destructor Tsp_XYDataSeries.Destroy;
begin
  if Assigned(fLineAttr) then
  begin
    fLineAttr.OnChange := nil;
    fLineAttr.Free;
  end;
  fInnerXYData.Free;
  inherited;
end;

procedure Tsp_XYDataSeries.Rescale(ScaleFactor: double);
begin
  fLineAttr.Rescale(ScaleFactor);
end;

function Tsp_XYDataSeries.CanPlot: boolean;
begin
  Result := not (fLockInvalidate) and Assigned(Plot);
end;

procedure Tsp_XYDataSeries.TryUpdatePlotOnDataChange;
begin
  if not (fLockInvalidate) and Assigned(Plot) then
  begin
    InvalidatePlot(rsDataChanged);
    //Plot.Update;                //call to redraw immediately
  end;
end;


procedure Tsp_XYDataSeries.SetLockInvalidate(const V: boolean);
begin
  if fLockInvalidate <> V then
  begin
    fLockInvalidate := V;
    TryUpdatePlotOnDataChange;
  end;
end;

procedure Tsp_XYDataSeries.SetLineAttr(const V: Tsp_LineAttr);
begin
  if not fLineAttr.IsSame(V) then
  begin
    fLineAttr.Assign(V);
  end;
end;

procedure Tsp_XYDataSeries.AtrributeChanged(V: TObject);
begin
  if CanPlot then
    InvalidatePlot(rsAttrChanged);
end;

//*******

function Tsp_XYDataSeries.GetXMin(var V: double): boolean;
begin
  Result := fXYDataPtr.GetXMin(V);
end;

function Tsp_XYDataSeries.GetXMax(var V: double): boolean;
begin
  Result := fXYDataPtr.GetXMax(V);
end;

function Tsp_XYDataSeries.GetYMin(var V: double): boolean;
begin
  Result := fXYDataPtr.GetYMin(V);
end;

function Tsp_XYDataSeries.GetYMax(var V: double): boolean;
begin
  Result := fXYDataPtr.GetYMax(V);
end;

procedure Tsp_XYDataSeries.Clear;
begin
  fXYDataPtr.Clear;
  TryUpdatePlotOnDataChange;
end;

procedure Tsp_XYDataSeries.AdjustCapacity;
begin
  fXYDataPtr.AdjustCapacity;
end;

procedure Tsp_XYDataSeries.SetCapacity(C: integer);
begin
  fXYDataPtr.SetCapacity(C);
end;

procedure Tsp_XYDataSeries.AddXY(aX, aY: double);
begin
  fXYDataPtr.AddXY(aX, aY);
  TryUpdatePlotOnDataChange;
end;

procedure Tsp_XYDataSeries.AddXYArrays(pX, pY: pointer; n: integer);
begin
  fXYDataPtr.AddXYArrays(pX, pY, n);
  TryUpdatePlotOnDataChange;
end;

procedure Tsp_XYDataSeries.InsertXY(i: integer; aX, aY: double);
begin
  fXYDataPtr.InsertXY(i, aX, aY);
  TryUpdatePlotOnDataChange;
end;

procedure Tsp_XYDataSeries.ReplaceXY(i: integer; aX, aY: double);
begin
  fXYDataPtr.ReplaceXY(i, aX, aY);
  TryUpdatePlotOnDataChange;
end;

procedure Tsp_XYDataSeries.Delete(i: integer);
begin
  fXYDataPtr.Delete(i);
  TryUpdatePlotOnDataChange;
end;

procedure Tsp_XYDataSeries.DeleteRange(fromi, toi: integer);
begin
  fXYDataPtr.DeleteRange(fromi, toi);
  TryUpdatePlotOnDataChange;      //try to redraw changes immediately
end;

function Tsp_XYDataSeries.Capacity: integer;
begin
  Result := fXYDataPtr.Capacity;
end;

function Tsp_XYDataSeries.Count: integer;
begin
  Result := fXYDataPtr.Count;
end;

procedure Tsp_XYDataSeries.UseExternalData(ExtData: Tsp_XYData);
begin
  Active := False;
  LockInvalidate := True;
  fXYDataPtr := ExtData;
  LockInvalidate := False;
  Active := True;
end;

procedure Tsp_XYDataSeries.UseInternalData;
begin
  LockInvalidate := True;
  fXYDataPtr := fInnerXYData;
  LockInvalidate := False;
  TryUpdatePlotOnDataChange;
end;


{*** Tsp_XYLine ***}

constructor Tsp_XYLine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fOnDrawPoint := nil;
  fPtAttr := Tsp_PointAttr.Create;
  fPtAttr.OnChange := AtrributeChanged;
  fDrawPointProc := fPtAttr.DrawRect;
end;

destructor Tsp_XYLine.Destroy;
begin
  if Assigned(fPtAttr) then
  begin
    fPtAttr.OnChange := nil;
    fPtAttr.Free;
  end;
  inherited;
end;

procedure Tsp_XYLine.Rescale(ScaleFactor: double);
begin
  fLineAttr.Rescale(ScaleFactor);
  fPtAttr.Rescale(ScaleFactor);  //Tsp_PointAttr;
end;

procedure Tsp_XYLine.SetPointAttr(const V: Tsp_PointAttr);
begin
  fPtAttr.Assign(V);
end;

procedure Tsp_XYLine.AtrributeChanged(V: TObject);
begin
  if V = fPtAttr then    // todo
    fDrawPointProc := fPtAttr.GetDrawPointProc(fPtAttr.Kind);
  inherited AtrributeChanged(V);
end;


procedure Tsp_XYLine.Draw;
const
  ep_Out = 1;
  op_Out = 2;
  Both_Out = op_Out or ep_Out;
var
  //pdx, pdy: Tsp_ArrayOfDouble;
  i, a: double;
  XA, YA: Tsp_Axis;

  procedure DrawLines();
  var
    j: integer;
    pa: array [0..1] of TPoint;
    is_out: word;
  begin
    with fXYDataPtr do
    begin
      fLineAttr.SetPenAttr(fPlot.DCanvas.Pen);
      fPlot.DCanvas.Brush.Style := bsClear;
      with pa[0] do
      begin
        x := XA.V2P(XV[0]);
        y := YA.V2P(YV[0]);
        if (x < -16000) or (y < -16000) or (x > 16000) or (y > 16000) then
          is_out := op_out
        else
          is_out := 0;
      end;
      for j := 1 to Count - 1 do
      begin
        with pa[1] do
        begin
          x := XA.V2P(XV[j]);
          y := YA.V2P(YV[j]);
          if (x < -16000) or (y < -16000) or (x > 16000) or (y > 16000) then
            is_out := is_out or ep_out;
        end;
        //draw line if at least one point inside
        if (is_out and both_out) <> both_out then
          fPlot.DCanvas.PolyLine(pa);
        is_out := (is_out shl 1) and both_out; //ver 2.31 AND operation added to mask
        pa[0] := pa[1];
      end;
    end;
  end; //DrawLines

  procedure CallDrawPointProc();
  var
    j: integer;
    p: TPoint;
  begin
    fPtAttr.SetCanvas(fPlot.DCanvas);
    for j := 0 to Count - 1 do with p do
      begin
        x := XA.V2P(fXYDataPtr.XV[j]);
        y := YA.V2P(fXYDataPtr.YV[j]);
        if PtInRect(fPlot.FieldRect, p) then
          fDrawPointProc(x, y);
      end;
  end;

  procedure CallOnDrawPoint();
  var
    j: integer;
    p: TPoint;
  begin
    fPtAttr.SetCanvas(fPlot.DCanvas);
    with fXYDataPtr do
      for j := 0 to Count - 1 do with p do
        begin
          x := XA.V2P(XV[j]);
          y := YA.V2P(YV[j]);
          if PtInRect(fPlot.FieldRect, p) then
            fOnDrawPoint(fPlot.DCanvas, j, x, y); //12.2023
        end;
  end; //CallOnDrawPoint

  procedure DrawPoints();
  begin
    if Assigned(fOnDrawPoint) and (fPtAttr.Kind = ptCustom) then
      CallOnDrawPoint()
    else
      CallDrawPointProc();
  end; //DrawPoints

begin  //Draw
  if (fXYDataPtr.Count < 1) or not Assigned(fPlot) or not
    (fPtAttr.Visible or ((fLineAttr.Visible) and (fXYDataPtr.Count > 1))) then
    Exit;
  with Plot do
  begin
    if XAxis = dsxBottom then
      XA := BottomAxis
    else
      XA := TopAxis;
    GetXMin(i);
    GetXMax(a);
    if (i > XA.Max) or (a < XA.Min) then
      Exit;
    GetYMin(i);
    GetYMax(a);
    if YAxis = dsyLeft then
      YA := LeftAxis
    else
      YA := RightAxis;
    if (i > YA.Max) or (a < YA.Min) then
      Exit;
  end;
  if (fXYDataPtr.Count > 1) and fLineAttr.Visible and (fLineAttr.Style <> psClear) then
    DrawLines;//(XA, YA);
  if fPtAttr.Visible then
    DrawPoints;//(XA, YA);
end;

procedure Tsp_XYLine.DrawLegendMarker(const LCanvas: TCanvas; MR: TRect);
var
  OP: TPen;
  OB: TBrush;
  x, y: integer;
begin
  if (fLineAttr.Visible or fPtAttr.Visible) then
  begin
    OP := TPen.Create;
    OP.Assign(LCanvas.Pen); //save pen
    OB := TBrush.Create;
    OB.Assign(LCanvas.Brush); //save brush
    try
      with MR do
        y := (Bottom + Top) div 2;
      if fLineAttr.Visible then
        with LCanvas do
        begin
          fLineAttr.SetPenAttr(LCanvas.Pen);
          Brush.Style := bsClear;
          with MR do
            PolyLine([Point(Left + 1, y), Point(Right, y)]);
        end;
      if fPtAttr.Visible then
      begin
        fPtAttr.SetCanvas(LCanvas);
        with MR do
          x := (Left + Right) div 2;
        if Assigned(fOnDrawLegend) then
        begin
          if (fPtAttr.Kind = ptCustom) then
            fOnDrawLegend(LCanvas, x, y)
          else
          begin
            fDrawPointProc(x, y);
            fOnDrawLegend(LCanvas, x, y);
          end;
        end
        else
          fDrawPointProc(x, y);
      end;
    finally
      LCanvas.Brush.Assign(OB);
      OB.Free;  //restore brush
      LCanvas.Pen.Assign(OP);
      OP.Free; //restore pen
    end;
  end;
end;

function Tsp_XYLine.GetX(i: integer): double;
begin
  Result := fXYDataPtr.XV[i];
end;

function Tsp_XYLine.GetY(i: integer): double;
begin
  Result := fXYDataPtr.YV[i];
end;

procedure Tsp_XYLine.QuickAddXY(aX, aY: double);
// don't spends time to update Plot, instead simply draw next segment,
// therefore AutoMin and AutoMax are ignored
var
  l, e: TPoint;
  A: Tsp_Axis;
  inside: boolean;
begin
  fXYDataPtr.AddXY(aX, aY);
  // instead InvalidatePlot(rsDataChanged) we simply draw line segment;
  // but first check if we can draw
  if not (Assigned(fPlot) and Active) then exit;
  // has parent plot & series is active
  with Plot do
  begin
    // if plot painted through draw buffer, then mark buffer as invalid
    if BufferedDisplay then
      BufferIsInvalid; //draw buffer will be freshed on next Paint
    with FieldRect do
      IntersectClipRect(DCanvas.Handle, Left, Top, Right, Bottom);
    if fLineAttr.Visible and (fXYDataPtr.Count > 1) then
    begin
      if XAxis = dsxBottom then
        A := BottomAxis
      else
        A := TopAxis;
      with A, fXYDataPtr do
      begin       // ask horiz. axis for the scaling
        l.x := V2P(XV[Count - 2]);
        e.x := V2P(XV[Count - 1]);    //find x pos new line segment
      end;
      if YAxis = dsyLeft then
        A := LeftAxis
      else
        A := RightAxis;
      with A, fXYDataPtr do
      begin      //ask vert. axis for the scaling
        l.y := V2P(YV[Count - 2]);
        e.y := V2P(YV[Count - 1]);       //find y pos new line segment
      end;
      inside := PtInRect(FieldRect, e);
      if (PtInRect(FieldRect, l) or inside) then
        with DCanvas do
        begin
          fLineAttr.SetPenAttr(DCanvas.Pen); //set line draw attributes
          if DCanvas.Brush.Style <> bsClear then
            DCanvas.Brush.Style := bsClear;
          MoveTo(l.x, l.y);
          LineTo(e.x, e.y);           //draw line
        end;
    end
    else
    begin
      if XAxis = dsxBottom then
        A := BottomAxis
      else
        A := TopAxis;
      with A, fXYDataPtr do
        e.x := V2P(XV[Count - 1]);       //find x pos new line segment
      if YAxis = dsyLeft then
        A := LeftAxis
      else
        A := RightAxis;
      with A, fXYDataPtr do
        e.y := V2P(YV[Count - 1]);       //find y pos new line segment
      inside := PtInRect(FieldRect, e);
    end;
    if fPtAttr.Visible and inside then
    begin
      if (fPtAttr.Kind = ptCustom) and Assigned(fOnDrawPoint) then
        with fXYDataPtr do
          fOnDrawPoint(DCanvas, Count - 1, e.x, e.y)
      else
      begin
        fPtAttr.SetCanvas(DCanvas);
        fDrawPointProc(e.x, e.y);
      end;
    end;
  end;
end;



{*** Tsp_SpectrLines ***}

constructor Tsp_SpectrLines.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fBLVisible := True;
  fLabelFormat := '###0.##';
  fLFont := TFont.Create;
  fLFont.OnChange := AtrributeChanged;
end;

destructor Tsp_SpectrLines.Destroy;
begin
  if Assigned(fLFont) then
    fLFont.Free;
  inherited;
end;

procedure Tsp_SpectrLines.SetBaseValue(V: double);
begin
  if fBaseValue <> V then
  begin
    fBaseValue := V;
    AtrributeChanged(Self);
  end;
end;

procedure Tsp_SpectrLines.SetYOrigin(V: Tsp_YOrigin);
begin
  if fYOrigin <> V then
  begin
    fYOrigin := V;
    AtrributeChanged(Self);
  end;
end;

procedure Tsp_SpectrLines.SetWhatValues(V: Tsp_WhatValues);
begin
  if fWhatValues <> V then
  begin
    fWhatValues := V;
    AtrributeChanged(Self);//if CanPlot then PLot.Invalidate;
  end;
end;

procedure Tsp_SpectrLines.SetLabelFormat(const V: string);
begin
  if fLabelFormat <> V then
  begin
    fLabelFormat := V;
    AtrributeChanged(Self);//if CanPlot then PLot.Invalidate;
  end;
end;

procedure Tsp_SpectrLines.SetLFont(V: TFont);
begin
  fLFont.Assign(V);
end;

procedure Tsp_SpectrLines.SetLVisible(const V: boolean);
begin
  if fLVisible <> V then
  begin
    fLVisible := V;
    AtrributeChanged(Self);//if CanPlot then PLot.Invalidate;
  end;
end;

procedure Tsp_SpectrLines.SetBLVisible(const V: boolean);
begin
  if fBLVisible <> V then
  begin
    fBLVisible := V;
    AtrributeChanged(Self);//if CanPlot then PLot.Invalidate;
  end;
end;

procedure Tsp_SpectrLines.Draw;
var
  ps: pLP;
  XA, YA: Tsp_Axis;
  i, a: double;
  by: integer;
  j: integer;

  procedure DrawBars(ps: pLP; by: integer);
  var
    j, lx, rx: integer;
  begin
    with Plot do
    begin
      lx := fLineAttr.Width div 2;
      rx := fLineAttr.Width - lx;
      //begin darw
      if fLineAttr.Width = 1 then
      begin   //draw line if BarWidth=1
        fLineAttr.SetPenAttr(DCanvas.Pen);
        for j := 0 to Count - 1 do
          with DCanvas, ps^[j] do
          begin
            if y < by then
            begin
              MoveTo(x, by);
              LineTo(x, y);
            end
            else
            begin
              MoveTo(x, y);
              LineTo(x, by);
            end;
          end;
      end
      else
      begin                      //draw rectangle if BarWidth=1
        with DCanvas do
        begin
          Brush.Color := fLineAttr.Color;
          Brush.Style := bsSolid;
          Pen.Style := psClear;
        end;
        Inc(rx);
        for j := 0 to Count - 1 do
          with DCanvas, ps^[j] do
          begin
            if y < by then
              Rectangle(x - lx, y - 1, x + rx, by + 1)
            else
              Rectangle(x - lx, by, x + rx, y + 1);
          end;
      end;
    end; //with
  end; //DrawBars

  procedure DrawLabels(pdx, pdy: Tsp_ArrayOfDouble; ps: pLP);
  var
    j, lx, ly, tw: integer;
    LS: string;
  begin
    lx := fLineAttr.Width - fLineAttr.Width div 2;
    with Plot.DCanvas do
    begin
      Brush.Style := bsClear;
      Font := fLFont;
      ly := TextHeight('8');// div 2;
    end;
    if fWhatValues = wvYValues then
      for j := 0 to Count - 1 do
        with Plot.DCanvas, ps^[j] do
        begin
          LS := FormatFloat(fLabelFormat, pdy[j]);
          if Assigned(fOnGetLabel) then
            fOnGetLabel(Self, j, pdx[j], pdy[j], LS);
          TextOut(x + lx, y - ly, LS);
        end
    else
    begin
      for j := 0 to Count - 1 do
        with Plot.DCanvas, ps^[j] do
        begin
          LS := FormatFloat(fLabelFormat, pdx[j]);
          if Assigned(fOnGetLabel) then
            fOnGetLabel(Self, j, pdx[j], pdy[j], LS);
          //22.09.2001
          tw := TextWidth(LS);
          if (j < Count - 1) and ((y < (ps^[j + 1].y)) or
            ((x + lx + tw) < ps^[j + 1].x)) then
            TextOut(x - lx, y - ly, LS);
        end;
    end;
  end;    //DrawLabels(pdx,pdy,ps);

begin
  if (Count < 1) or not Assigned(Plot) then
    Exit;
  with Plot do
  begin
    if XAxis = dsxBottom then
      XA := BottomAxis
    else
      XA := TopAxis;
    GetXMin(i);
    GetXMax(a);
    if (i > XA.Max) or (a < XA.Min) then
      Exit;
  end;
  GetMem(ps, Count * SizeOf(TPoint));
  //pdx := VarArrayLock(XV);
  //pdy := VarArrayLock(YV);
  try
    with Plot do
    begin
      //find where begin draw bar
      if YAxis = dsyLeft then
        YA := LeftAxis
      else
        YA := RightAxis;
      if YOrigin = yoBaseLine then
      begin
        with YA do
          by := V2P(fBaseValue);
        if by > BottomAxis.OY then
          by := BottomAxis.OY + 2
        else if by < TopAxis.OY then
          by := TopAxis.OY - 2;
      end
      else
      begin //if YAxis min at top then from top and vice versa
        if YA.Inversed then
          by := TopAxis.OY - 2
        else
          by := BottomAxis.OY + 2;
      end;
      //calc coordinate
      for j := 0 to Count - 1 do
        with ps^[j], XA do
        begin
          x := V2P(fXYDataPtr.XV[j]);
        end;
      for j := 0 to Count - 1 do
        with ps^[j], YA do
        begin
          y := V2P(fXYDataPtr.YV[j]);
        end;
      if fLineAttr.Visible then
        DrawBars(ps, by);
      //draw base line
      if fBLVisible and (YOrigin = yoBaseLine) then
      begin
        with DCanvas, FieldRect do
        begin
          fLineAttr.SetPenAttr(Pen);
          Pen.Width := 1;
          MoveTo(Left, by);
          LineTo(Right + 1, by);
        end;
      end;
      //draw value label
      if fLVisible then
        DrawLabels(fXYDataPtr.XV, fXYDataPtr.YV, ps);
    end;
  finally
    FreeMem(ps, Count * SizeOf(TPoint));
  end;
end;

function Tsp_SpectrLines.GetYMin;
begin
  Result := inherited GetYMin(V);
  if not (Result) then
    Exit;
  if YOrigin = yoBaseLine then
  begin
    if V > fBaseValue then
      V := fBaseValue;
  end
  else
  begin
    if V > 0 then
      V := 0;
  end;
end;

function Tsp_SpectrLines.GetYMax;
begin
  Result := inherited GetYMax(V); //was error
  if not (Result) then
    Exit;
  if YOrigin = yoBaseLine then
  begin
    if V < fBaseValue then
      V := fBaseValue;
  end
  else
  begin
    if V < 0 then
      V := 0;
  end;
end;


end.

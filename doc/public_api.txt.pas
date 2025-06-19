 (***** SGraph lazarus/delphi classes public interface *****)


(***) unit sgr_line.pas
//===============================================================================
Tsp_CustomLineAttr = class(TPersistent)
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

Tsp_LineAttr =  = class(Tsp_CustomLineAttr)
public
  function IsSame(const LA: Tsp_CustomLineAttr): boolean;    
published
  property Color rw  // 
  property Style rw default psSolid
  property Width rw default 1
  property Visible rw

(***) unit sgr_point.pas
//===============================================================================
TPointKind = (ptCustom, ptRectangle, ptEllipse, ptDiamond,
              ptCross, ptTriangle, ptDownTriangle);
              
TDrawPointProc = procedure(const x, y: integer) of object;

Tsp_PointAttr = class(TBrush)
public
  procedure SetCanvas(aCanvas: TCanvas);
  function  GetDrawPointProc(PtKind: TPointKind): TDrawPointProc;
published
  //kind of point
  property Kind: TPointKind rw default ptRectangle;
  //horizontal size of Point
  property HSize: integer rw default 5;
  //vertical size of Point
  property VSize: integer rw default 5;
  //is points are drawn
  property Visible: boolean rw  SetVisible;
  //points border width (pen)
  property BorderWidth: integer rw default 1;
  //points border color (pen)
  property BorderColor: TColor rw  default clBlack;

(***) unit sgr_scale
//===============================================================================
Tsp_Scale = class(TPersistent)
public
  function V2P(const V: double): integer;
  function P2V(const V: integer): double;
published
  property Inversed: boolean rw  // true -> min on the right/top
  property NoTicksLabel: boolean  rw
  property TicksAdjusted: boolean  rw
  property TicksLines: boolean  rw

(***) unit sgr_def
//===============================================================================
Tsp_Axis = class(Tsp_Scale)
public
  procedure SetMinMax(aMin, aMax: double);
  procedure MoveMinMax(aDelta: double);
published
  property Margin: integer rw
  property FixedBandWidth: integer rw
  property Caption: string rw
  property Min: double rw
  property Max: double rw
  property TicksCount: byte rw default 5;
  property LineAttr: Tsp_LineAttr rw
  property GridAttr: Tsp_LineAttr rw
  property AutoMin: boolean rw
  property AutoMax: boolean rw
  property LabelAsDataTime: boolean rw
  property LabelFormat: string rw

//===============================================================================
Tsp_PlotMarker = class(TComponent)
published
  property Plot: Tsp_XYPlot rw
  property XAxis: Tsp_WhatXAxis rw default dsxBottom;
  property YAxis: Tsp_WhatYAxis rw default dsyLeft;
  property WhenDraw: Tsp_WhenDrawMarker rw //before or after series
  property Visible: boolean rw

//===============================================================================
Tsp_PlotSeries  = class(TComponent)
public
  procedure Draw; virtual; abstract;
  function GetXMin(var V: double): boolean; virtual; abstract;//var as out 2017
  function GetXMax(var V: double): boolean; virtual; abstract;
  function GetYMin(var V: double): boolean; virtual; abstract;
  function GetYMax(var V: double): boolean; virtual; abstract;
  procedure DrawLegendMarker(const LCanvas: TCanvas; MR: TRect); virtual; abstract;
  procedure BringToFront;
  procedure SendToBack;
  property Active: boolean read fActive write SetActive;
published
  property Plot: Tsp_XYPlot rw
  property XAxis: Tsp_WhatXAxis rw
  property YAxis: Tsp_WhatYAxis rw
  property Legend: string rw
  property OnLegendChange: TNotifyEvent rw

//===============================================================================
Tsp_zpDirections = (zpdNone, zpdHorizontal, zpdVertical, zpdBoth);

TGetTickLabelEvent = procedure(Sender: Tsp_Axis; LabelNum: integer;
    LabelVal: double; var LS: string) of object;

TZoomAxisEvent = procedure(Sender: Tsp_Axis; var min, max: double;
    var CanZoom: boolean) of object;

//===============================================================================
Tsp_XYPlot = class(TCustomControl)
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Rescale(ScaleFactor: double);
    procedure Invalidate; override;
    procedure BufferIsInvalid;
    procedure DrawPlot(DC: TCanvas; W, H: integer);
    procedure Paint; override;
    {$IFnDEF FPC}
    procedure CopyToClipboardMetafile;
    //Lazarus do not support Metafile by default use DrawPlot instead
    {$ENDIF}
    procedure CopyToClipboardBitmap;
    function CreatePlotBitmap(BmpWidth, BmpHeight: integer): TBitmap;
    property DCanvas: TCanvas read fDCanvas;
    property DWidth: integer read fDWidth;
    property DHeight: integer read fDHeight;
    property FieldRect: TRect read FR;
    property Series[i: integer]: Tsp_PlotSeries read GetSeriesPtr;
    property SeriesCount: integer read GetSeriesCount;
    property ScaleFactor: double read fScaleFactor;                 f
  published
    property Align;
    ... standard control properties
    // added propert
    property Zoom: Tsp_zpDirections rw default zpdBoth;
    property Pan: Tsp_zpDirections rw  default zpdBoth;
    property ZoomShiftKeys: Tsp_ShiftKeys rw default [ssShift];
    property PanShiftKeys: Tsp_ShiftKeys rw [ssCtrl];
    property PanCursor: TCursor rw default crDefault;
    property LeftAxis: Tsp_Axis read LA write SetLA;
    property RightAxis: Tsp_Axis read RA write SetRA;
    property BottomAxis: Tsp_Axis read BA write SetBA;
    property TopAxis: Tsp_Axis read TA write SetTA;
    property BorderStyle: Tsp_BorderStyle rw ;
    property FieldColor: TColor rw
    property BufferedDisplay: boolean rw default False;
    property XCursorOn: boolean rw default False;
    property XCursorVal: double rw
    property OnAxisZoom: TZoomAxisEvent rw
    property OnGetTickLabel: TGetTickLabelEvent rw
    property OnFieldDraw: TNotifyEvent rw
    property OnDrawEnd: TNotifyEvent rw

 
(***) unit sgr_xydata
//===============================================================================
  //store for x, y data and maintains main methods & properties for it
Tsp_XYData = class
  public
    constructor Create();
    destructor Destroy; override;

    // does not free allocated memory, only set Count=0 and update Plot,
    // use AdjustCapacity to free excessive memory}
    procedure Clear;
    //set minimum Capacity for current Count
    procedure AdjustCapacity;
    //use it if you know how many elements data will have
    procedure SetCapacity(C: integer);

    //return MinMax if not ValidMinMax then first find MinMax
    function GetXMin(var V: double): boolean;
    function GetXMax(var V: double): boolean;
    function GetYMin(var V: double): boolean;
    function GetYMax(var V: double): boolean;
    //used by external host, f.e. plot series when is drawing data
    procedure Lock;
    procedure UnLock;
    // use to lock invalidate plot while data are changing
    procedure StopCallOnChange();
    // use to restore CallOnChange after data has been changed
    procedure CallOnChange();
    //(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)//
    // use it if you know how many elements data will have and don't want to loose
    // time on auto expand when add data. If series is not empty it cannot set
    // Capacity less than Count
    procedure LetCapacityAtLeast(C: integer);

    //(***) change data set and call update(***) //
    //add values at the end of series data
    procedure AddXY(aX, aY: double);
    //add many values at the end of series
    //pX, pY must points to array of double, n - number of elements in arrays
    procedure AddXYArrays(pX, pY: pointer; n: integer);
    procedure InsertXY(i: integer; aX, aY: double);
    //replace values at index i
    procedure ReplaceXY(i: integer; aX, aY: double);
    //Delete Last
    procedure DeleteLast();
    procedure DeleteRange(fromi, toi: integer);
    procedure Delete(i: integer);
    //current memory allocation for data elements (for example number of points)
    property Capacity: cardinal read fCapacity;
    //current number of valid data elements (for example number of points)
    property Count: integer read fPN;

    //used to for fast read data (do not modify w/o strong reasons)
    property XV: Tsp_ArrayOfDouble read fXV;
    property YV: Tsp_ArrayOfDouble read fYV;
  end;

(***) unit sgr_xydata
//===============================================================================
Tsp_XYDataSeries = class(Tsp_PlotSeries)
  public //Tsp_XYDataSeries
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //see Tsp_XYPlot.Rescale(ScaleFactor 2021
    procedure Rescale(ScaleFactor: double); override;
    //next 4 functions must be implemented for any series
    //(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)
    function GetXMin(var V: double): boolean; override;
    function GetXMax(var V: double): boolean; override;
    function GetYMin(var V: double): boolean; override;
    function GetYMax(var V: double): boolean; override;
    //(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)(***)

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

//===============================================================================
// Draw custom point on Plot Canvas with postion at x, y for data #n
TOnDrawPoint = procedure(aCanvas: TCanvas; n, x, y: integer) of object;

// Draw custom point on Legend Canvas with central postion at x, y
TOnDrawLegend = procedure(aCanvas: TCanvas; x, y: integer) of object;

Tsp_XYLine = class(Tsp_XYDataSeries)
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

//===============================================================================
Tsp_YOrigin = (yoBaseLine, yoXAxises);

Tsp_WhatValues = (wvXValues, wvYValues);

Tsp_GetLabelEvent = procedure(Sender: Tsp_SpectrLines;
    Num: integer;  //point number
    X, Y: double;  //points values
    var LS: string) of object;   //label string

//draw data as bar with center at XV pos. and height from Bottom
//axis to YV or from BaseLine to YV;
Tsp_SpectrLines = class(Tsp_XYDataSeries)
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
unit sgr_xydata;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{ (c) S.P.Pod'yachev 2021-2025 }

//? TODO add save/load to/from TStringList

interface

uses
{$IFDEF FPC}
  LCLIntf, LCLType,
  SysUtils, Classes, Graphics
{$ELSE}
  WinApi.Windows,
  System.SysUtils,  System.Classes,
  Vcl.Graphics
{$ENDIF}
;

{ *************************************************************************
{ note
  Tsp_XYLine and Tsp_SpectrLines were derived from Tsp_XYDataSeries and have
  been used for many years in programs we still support.
  Original (1999) Tsp_XYDataSeries stores X, Y in protected variables
  type of variant(VarArrayCreate([], varDouble)
  So with new separated data storage Tsp_XYDataSeries has same interface,
  but most of his data manipulation methods now are actually are implemented
  by fData: Tsp_XYData. For instance
  procedure Tsp_XYDataSeries.AddXY(aX, aY: double);
  begin
    fData.AddXY(aX, aY);
    TryUpdatePlotOnDataChange;
  end;
  Also read-only properties Tsp_XYDataSeries.Count и Tsp_XYDataSeries.Capacity
  were replaced by functions:
  function Tsp_XYDataSeries.Capacity: integer;
  begin Result := fData.Capacity; end;

  And as result Tsp_XYLine и Tsp_SpectrLines virtual procedures Draw and
  DrawLegendMarker were corrected for the new data array (fData.XV/YV). }
{:}

type

  Tsp_ArrayOfDouble = array of double;  // to do

  //store for x, y data and maintains main methods & properties for it
 Tsp_XYData = class
  protected
    //capacity & points number service
    fPN: integer;         //number of valid data elements (x,y points)
    fCapacity: cardinal;   //reserved memory in number of data elements
    fInc: integer;        //step of expand increment of allocated memory
    fXV: Tsp_ArrayOfDouble; //storage for X values
    fYV: Tsp_ArrayOfDouble; //storage for Y values
    {$IFDEF F3ARRAY}
    F3: array of byte;   //rezerv   to do
    {$ENDIF}
    //increase allocated memory size by fInc XY pairs
    procedure Expand;
    //increase allocated memory size by IncSize XY pairs
    procedure ExpandBy(IncSize: cardinal);
  protected
    //Max Min service
    fXMin, fXMax,            //Min & Max of data
    fYMin, fYMax: double;
    fValidMinMax: boolean;  //used to minimise MinMax calculating
    //find Min & Max of data of series;
    procedure FindMinMax();  //see also GetXMin(var V...
    //used in several procedures when data are added
    procedure TryUpdateMinMax(aX, aY: double);
    { protected todo if needed
   //unused control service
    fLockOnChange: boolean; //lock OnChange notifies while data are changing
    fLockedChange: boolean; // call OnChange while fLockOnChange trues
    //if not lock then call OnChage (if it is assigned) used automatically
    OnChange: TNotifyEvent;
    procedure Lock;
    procedure UnLock; }
    procedure CheckAndCallOnChange();
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
    // use it if you know how many elements data will have and don't want to loose
    // time on auto expand when add data. If series is not empty it cannot set
    // Capacity less than Count
    procedure LetCapacityAtLeast(C: integer);

    //** change data set and call update** //
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

implementation

//*** Tsp_XYData ***//

constructor Tsp_XYData.Create();
begin
  inherited Create();
  fInc := 32;         // Minimal capacity
  {$IFDEF F3ARRAY}
    SetLength(F3, fInc);
  {$ENDIF}
  SetLength(fXV, fInc);
  SetLength(fYV, fInc);
  fCapacity := High(fYV);  //??? to do S.P.P.
  {fXMin := 5.0E-324;
  fXMax := 1.7E308;
  fYMin := 5.0E-324;
  fYMax := 1.7E308;}
  fPN := 0;
  fValidMinMax := False;
end;

destructor Tsp_XYData.Destroy;
begin
  SetLength(fYV, 0);
  SetLength(fXV, 0);
  {$IFDEF F3ARRAY}
    SetLength(F3, 0);
  {$ENDIF}
  inherited;
end;


procedure Tsp_XYData.TryUpdateMinMax(aX, aY: double);
begin
  if fPN = 0 then
  begin
    fXMin := aX;
    fXMax := aX;
    fYMin := aY;
    fYMax := aY;
    fValidMinMax := True;
  end
  else if fValidMinMax then
  begin
    if aX < fXMin then
      fXMin := aX
    else if aX > fXMax then
      fXMax := aX;
    if aY < fYMin then
      fYMin := aY
    else if aY > fYMax then
      fYMax := aY;
  end;
end;


procedure Tsp_XYData.Expand;
begin
  ExpandBy(fInc);
end;


procedure Tsp_XYData.ExpandBy(IncSize: cardinal);
begin
  if IncSize < 1 then Exit;
  {$IFDEF F3ARRAY}
    SetLength( F3, fCapacity + IncSize);
  {$ENDIF}
  SetLength(fXV, fCapacity + IncSize);
  SetLength(fYV, fCapacity + IncSize);
  fCapacity := High(fYV);
end;

procedure Tsp_XYData.CheckAndCallOnChange();
begin
  // todo if needed
end;

procedure Tsp_XYData.SetCapacity(C: integer);
var
  n: integer;
begin
  if C < fInc then
    C := fInc;
  if C < fPN then   //truncate data if Capacity less then Count
  begin
    fPN := C;
    AdjustCapacity;
    fValidMinMax := False;
    CheckAndCallOnChange();
  end
  else
  begin
    n := ((C div fInc) + 1) * fInc;
    if n <> fCapacity then
    begin
      SetLength(fXV, n);
      SetLength(fYV, n);
      fCapacity := High(fYV);
    end;
  end;
end;

procedure Tsp_XYData.LetCapacityAtLeast(C: integer);
// cannot set Capacity less than Count
var
  n: cardinal;
begin
  n := ((C div fInc) + 1) * fInc;
  if (n <> fCapacity) and (n > fPN) then
  begin
    {$IFDEF F3ARRAY}
      SetLength( F3, n);
    {$ENDIF}
    SetLength(fXV, n);
    SetLength(fYV, n);
    fCapacity := High(fYV);
  end;
end;

procedure Tsp_XYData.Clear;
begin
  if (fPN > 0) then
  begin
    fPN := 0;
    CheckAndCallOnChange();
  end;
end;

procedure Tsp_XYData.AdjustCapacity;
var
  n: cardinal;
begin
  n := ((fPN div fInc) + 1) * fInc;
  if (n <> fCapacity) then
  begin
    {$IFDEF F3ARRAY}
      SetLength( F3, n);
    {$ENDIF}
    SetLength(fXV, n);
    SetLength(fYV, n);
    fCapacity := High(fYV);
  end;
end;

procedure Tsp_XYData.FindMinMax;
var
  j: integer;
begin
  if fPN < 1 then
  begin
    fValidMinMax := False;
    Exit;
  end;
  fXMin := fXV[0];
  fXMax := fXMin;
  fYMin := fYV[0];
  fYMax := fYMin;
  for j := 1 to fPN - 1 do
  begin
    if fXV[j] < fXMin then
      fXMin := fXV[j]
    else if fXV[j] > fXMax then
      fXMax := fXV[j];
    if fYV[j] < fYMin then
      fYMin := fYV[j]
    else if fYV[j] > fYMax then
      fYMax := fYV[j];
  end;
  fValidMinMax := True;
end;

{
procedure Tsp_XYData.CheckAndCallOnChange;
begin
  if Assigned(OnChange) then
  begin
    if fLockOnChange then
      fLockedChange:=True
    else
    begin
      fLockedChange:= False;
      OnChange(Self);
    end
  end
end;

procedure Tsp_XYData.Lock;
begin
  fLockOnChange := True;
end;

procedure Tsp_XYData.UnLock;
begin
  fLockOnChange := False;
  if fLockedChange then
    CheckAndCallOnChange;
end;
}

function Tsp_XYData.GetXMin(var V: double): boolean;
begin
  Result := Count > 0;
  if Result then
  begin
    if not (fValidMinMax) then
      FindMinMax;
    V := fXMin;
  end;
end;

function Tsp_XYData.GetXMax(var V: double): boolean;
begin
  Result := Count > 0;
  if Result then
  begin
    if not (fValidMinMax) then
      FindMinMax;
    V := fXMax;
  end;
end;

function Tsp_XYData.GetYMin(var V: double): boolean;
begin
  Result := Count > 0;
  if Result then
  begin
    if not (fValidMinMax) then
      FindMinMax;
    V := fYMin;
  end;
end;

function Tsp_XYData.GetYMax(var V: double): boolean;
begin
  Result := Count > 0;
  if Result then
  begin
    if not (fValidMinMax) then
      FindMinMax;
    V := fYMax;
  end;
end;


procedure Tsp_XYData.AddXY(aX, aY: double);
begin
  if fPN >= fCapacity then
    Expand;
  fXV[fPN] := aX;
  fYV[fPN] := aY;
  TryUpdateMinMax(aX, aY);
 {$IFDEF F3ARRAY}
    F3[fPN]=DfltF3;
  {$ENDIF}
  Inc(fPN);     //increment must be after if fPN was 0
  CheckAndCallOnChange();
end;

procedure Tsp_XYData.AddXYArrays(pX, pY: pointer; n: integer);
var
  j: integer;
begin
  if n <= 0 then
    Exit;
  if (fPN + n) >= fCapacity then
    ExpandBy(n);
  j := n * SizeOf(double);
  System.Move(pX^, fXV[fPN], j);
  System.Move(pY^, fYV[fPN], j);
  {$IFDEF F3ARRAY}
    System.FillChar(F3[fPN],n, DfltF3);
    //j := n * SizeOf(byte);
    //System.Fill(pF3^, F[fPN], j);
  {$ENDIF}
  j := fPN;
  Inc(fPN, n);        //do not win essential time if n>old_fPN
  if fValidMinMax and (n < 2 * j) then //rewrite at 27.10.1999
    for j := j to fPN - 1 do
    begin
      if fXV[j] < fXMin then
        fXMin := fXV[j]
      else if fXV[j] > fXMax then
        fXMax := fXV[j];
      if fYV[j] < fYMin then
        fYMin := fYV[j]
      else if fYV[j] > fYMax then
        fYMax := fYV[j];
    end
  else
    fValidMinMax := False;
  CheckAndCallOnChange();
end;

procedure Tsp_XYData.InsertXY(i: integer; aX, aY: double);
var
  j: integer;
begin
  if (i > fPN) or (i < 0) then
    Exit;  //Exception
  if i = fPN then
    AddXY(ax, ay)
  else
  begin
    j := (fPN - i) * SizeOf(double);
    if fPN >= fCapacity then
      Expand;
    System.Move(fXV[i], fXV[i + 1], j);
    System.Move(fYV[i], fYV[i + 1], j);
    fXV[i] := aX;
    fYV[i] := aY;
    TryUpdateMinMax(aX, aY);
    Inc(fPN);
  end;
  CheckAndCallOnChange();
end;

procedure Tsp_XYData.ReplaceXY(i: integer; aX, aY: double);
begin
  if (i >= fPN) or (i < 0) then
    Exit; //Exception //? may be raise Exception
  fXV[i] := aX;
  fYV[i] := aY;
  {$IFDEF F3ARRAY}
    F3[i] := DfltF3;
  {$ENDIF}
  fValidMinMax := False;
  CheckAndCallOnChange();
end;

procedure Tsp_XYData.DeleteLast;
begin
  if fPN > 0 then Dec(fPN);
  fValidMinMax := False;
  CheckAndCallOnChange();
end;

procedure Tsp_XYData.Delete(i: integer);
var
  j: integer;
begin
  if (i >= fPN) or (i < 0) then
    Exit;  //Exception
  fValidMinMax := False;
  if i = fPN - 1 then
    Dec(fPN)
  else
  begin
    j := (fPN - i - 1) * SizeOf(double);
    System.Move(fXV[i + 1], fXV[i], j);
    System.Move(fYV[i + 1], fYV[i], j);
    Dec(fPN);
  end;
  CheckAndCallOnChange();
end;

procedure Tsp_XYData.DeleteRange(fromi, toi: integer);
var
  j: integer;
begin
  if fromi > toi then
  begin       //swap if need
    j := fromi;
    fromi := toi;
    toi := j;
  end;
  if (fromi >= fPN) or (fromi < 0) then
    Exit;  //Exception
  fValidMinMax := False;
  if toi >= fPN - 1 then
  begin
    fPN := fromi;
    Exit;
  end;
  j := (fPN - toi) * SizeOf(double);
  Dec(fPN, (toi - fromi + 1));
  System.Move(fXV[toi + 1], fXV[fromi], j);
  System.Move(fYV[toi + 1], fYV[fromi], j);
  CheckAndCallOnChange();
end;

end.

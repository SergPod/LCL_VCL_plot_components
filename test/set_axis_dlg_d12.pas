unit set_axis_dlg_d12;
{(c) S.P.Pod'yachev 1999}
{**********************************************}
{   instant set some axis properties dialog    }
{**********************************************}
interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, 
  Buttons, ExtCtrls, Spin, sgr_def, Dialogs;

type
  TFAxisPrptsDlg = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    BGCBtn: TButton;
    CloseBtn: TButton;
    TCount: TSpinEdit;
    TLShow: TCheckBox;
    GShow: TCheckBox;
    ACaption: TEdit;
    Invrs: TCheckBox;
    FontBtn: TButton;
    Mrgn: TSpinEdit;
    Label4: TLabel;
    TShow: TCheckBox;
    AIndex: TComboBox;
    Bevel1: TBevel;
    ColorDialog1: TColorDialog;
    FontDialog1: TFontDialog;
    procedure FormCreate(Sender: TObject);
    procedure AIndexChange(Sender: TObject);
    procedure ACaptionChange(Sender: TObject);
    procedure TCountChange(Sender: TObject);
    procedure MrgnChange(Sender: TObject);
    procedure TLShowClick(Sender: TObject);
    procedure TShowClick(Sender: TObject);
    procedure GShowClick(Sender: TObject);
    procedure InvrsClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure BGCBtnClick(Sender: TObject);
    procedure FontBtnClick(Sender: TObject);
  private
    { Private declarations }
    Plot:Tsp_XYPlot;
    Axis: Tsp_Axis;
  public
    { Public declarations }
    procedure GetAProp;
  end;

var
  FAxisPrptsDlg: TFAxisPrptsDlg;

procedure SetAxisProperties(P:Tsp_XYPlot);

implementation

{$R *.DFM}

procedure TFAxisPrptsDlg.GetAProp;
begin
 with Axis do begin
   if FixedBandWidth >0 then
   begin
     Mrgn.Value:=FixedBandWidth;
     Label4.Caption:= 'Fixed';
     Mrgn.Enabled:= False;
   end
   else
    begin
     Mrgn.Value:=Margin;
     Label4.Caption:= 'Margin';
     Mrgn.Enabled:= True;
   end;
   ACaption.Text:=Caption;
   TCount.Value:=TicksCount;
   Invrs.Checked:=Inversed;
   TLShow.Checked:=not NoTicksLabel;
   TShow.Checked:=not NoTicks;
   GShow.Checked:=GridAttr.Visible;
 end;
end;

procedure SetAxisProperties(P:Tsp_XYPlot);
begin
 with FAxisPrptsDlg do
 begin
   Plot:=P;
   AIndexChange(nil);
   Show;
 end;
end;

procedure TFAxisPrptsDlg.FormCreate(Sender: TObject);
begin
 AIndex.ItemIndex:=0;
end;

procedure TFAxisPrptsDlg.AIndexChange(Sender: TObject);
begin
 with Plot do
 case Aindex.ItemIndex of
  0: Axis:=BottomAxis;
  1: Axis:=LeftAxis;
  2: Axis:=TopAxis;
  3: Axis:=RightAxis;
 end;
 GetAProp;
end;

procedure TFAxisPrptsDlg.ACaptionChange(Sender: TObject);
begin
 with Axis do Caption:=ACaption.Text;
end;

procedure TFAxisPrptsDlg.TCountChange(Sender: TObject);
begin
 with Axis do TicksCount:=TCount.Value;
end;

procedure TFAxisPrptsDlg.MrgnChange(Sender: TObject);
begin
  with Axis do Margin:=Mrgn.Value;
end;

procedure TFAxisPrptsDlg.TLShowClick(Sender: TObject);
begin
 with Axis do NoTicksLabel:=not TLShow.Checked;
 with Axis do TCount.Value:=TicksCount;
end;

procedure TFAxisPrptsDlg.TShowClick(Sender: TObject);
begin
 with Axis do NoTicks:=not TShow.Checked;
end;

procedure TFAxisPrptsDlg.GShowClick(Sender: TObject);
begin
 with Axis do GridAttr.Visible:=GShow.Checked;
end;

procedure TFAxisPrptsDlg.InvrsClick(Sender: TObject);
begin
 with Axis do Inversed:=Invrs.Checked;
end;

procedure TFAxisPrptsDlg.BGCBtnClick(Sender: TObject);
begin
 if ColorDialog1.Execute then Plot.Color:=ColorDialog1.Color;
end;

procedure TFAxisPrptsDlg.FontBtnClick(Sender: TObject);
begin
 if FontDialog1.Execute then Plot.Font:=FontDialog1.Font;
end;

procedure TFAxisPrptsDlg.FormActivate(Sender: TObject);
begin
 with Axis do TCount.Value:=TicksCount;
end;

procedure TFAxisPrptsDlg.CloseBtnClick(Sender: TObject);
begin
 Close;
end;


end.

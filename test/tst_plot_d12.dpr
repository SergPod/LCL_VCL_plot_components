program tst_plot_d12;

uses
  Vcl.Forms,
  xyplot_form_d12 in 'xyplot_form_d12.pas' {Form1},
  set_axis_dlg_d12 in 'set_axis_dlg_d12.pas' {FAxisPrptsDlg};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFAxisPrptsDlg, FAxisPrptsDlg);
  Application.Run;
end.

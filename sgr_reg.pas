unit sgr_reg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{ (c) S.P.Pod'yachev 1998 - 2025 }

{ SGraph originally released for Delphi 5/6/7 (last ver. 2.4) was converted
to Lazarus components 10.10.2016 with practically the same object model.
It has been modified several times, while remaining largely backwards
compatible. The last pure Lazarus package ver 1.8 files were modified
6.2025 to support Lazarus and Delphi 12 packages which share the same
pascal units. Delphi forever;)}

interface

uses Classes,
{$IFDEF FPC}
  LResources,
{$ELSE}
  VCL.Imaging.pngimage,
{$ENDIF}
  sgr_def, sgr_xydata_series,  {sgr_eds,} sgr_mark;

{***************************************************}
{ Register Sgraph components                        }
{***************************************************}
{:}

procedure Register;

implementation

procedure Register;
begin
 RegisterComponents('Sgraph', [Tsp_XYPlot, Tsp_XYLine,
                               Tsp_SpectrLines, {Tsp_ndsXYLine,}
                               Tsp_LineMarker, Tsp_ImageMarker]);
 RegisterNonActiveX([Tsp_XYPlot, Tsp_XYLine,
                     Tsp_SpectrLines, {Tsp_ndsXYLine,}
                     Tsp_LineMarker, Tsp_ImageMarker], axrComponentOnly);
end;

{ Назначение RegisterNonActiveX: Эта процедура сообщает IDE Delphi, что
перечисленные компоненты НЕ должны быть доступны для использования
в технологии ActiveX
 Параметр axrComponentOnly: Это флаг, который уточняет, как именно компонент
должен быть исключён из поддержки ActiveX. Конкретно axrComponentOnly означает,
что компонент является чисто визуальным компонентом (потомком TComponent или
TGraphicControl), который не предоставляет и не требует ActiveX-интерфейсов.
} 

initialization

{$IFDEF FPC}
  {$I res_laz/sgr_icons.lrs}
{$ELSE}
  {$R 'res_d12/sgr_vcl_icons.res'}
{$ENDIF}


end.

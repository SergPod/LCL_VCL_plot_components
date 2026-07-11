{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit sgr_lz;

{$warn 5023 off : no warning about unused units}
interface

uses
  sgr_reg, sgr_misc, sgr_def, sgr_mark, sgr_scale, sgr_point, sgr_line, 
  sgr_xydata, sgr_xydata_series, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('sgr_reg', @sgr_reg.Register);
end;

initialization
  RegisterPackage('sgr_lz', @Register);
end.

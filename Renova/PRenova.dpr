program PRenova;

uses
  Vcl.Forms,
  URenova in 'URenova.pas' {FRenova},
  Udmod in 'Udmod.pas' {dmod: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFRenova, FRenova);
  Application.CreateForm(Tdmod, dmod);
  Application.Run;
end.

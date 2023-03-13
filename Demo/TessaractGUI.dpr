program TessaractGUI;

uses
  Vcl.Forms,
  UnitFormOCR in 'UnitFormOCR.pas' {FormOCR},
  tesseractocr.capi in '..\Source\tesseractocr.capi.pas',
  tesseractocr.consts in '..\Source\tesseractocr.consts.pas',
  tesseractocr.leptonica in '..\Source\tesseractocr.leptonica.pas',
  tesseractocr.pagelayout in '..\Source\tesseractocr.pagelayout.pas',
  tesseractocr in '..\Source\tesseractocr.pas',
  tesseractocr.utils in '..\Source\tesseractocr.utils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormOCR, FormOCR);
  Application.Run;
end.

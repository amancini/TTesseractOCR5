unit tesseractocr;


{ The MIT License (MIT)

 TTesseractOCR4
 Copyright (c) 2018 Damian Woroch, http://rime.ddns.net/

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE. }

interface
uses
  {$IFNDEF FPC}
  System.Classes,
  System.Types,
  System.SysUtils,
  System.IOUtils,
  System.Math,
  Vcl.Graphics,
  Vcl.Imaging.pngimage,
  {$ELSE}
  Classes,
  Types,
  SysUtils,
  Math,
  Graphics,
  {$ENDIF}
  tesseractocr.consts,
  tesseractocr.capi,
  tesseractocr.leptonica,
  tesseractocr.pagelayout;

type
  TOcrEngineMode = (oemTesseractOnly, oemLSTMOnly, oemTesseractLSTMCombined, oemDefault);

type
  TRecognizerProgressEvent = procedure(Sender: TObject; AProgress: Integer; var ACancel: Boolean) of object;
  TRecognizerEndEvent = procedure(Sender: TObject; ACanceled: Boolean) of object;

type
  TTesseractOCR5 = class(TObject)

    type
      TRecognizerThread = class(TThread)
      protected
        FOwner: TTesseractOCR5;
        procedure Execute; override;
      public
        constructor Create(AOwner: TTesseractOCR5);
      end;

  protected
    FTessBaseAPI: TessBaseAPI;
    FSourcePixImage: PPix;
    FProgressMonitor: ETEXT_DESC;
    FDataPath: String;
    FRecognizerThread: TRecognizerThread;
    procedure RecognizeInternal(ASilent: Boolean);
  private
    FUTF8Text: String;
    FHOCRText: String;
    FBusy: Boolean;
    FProgress: Integer;
    FLayoutAnalyse: Boolean;
    FPageLayout: TTesseractPageLayout;
    FOnRecognizeBegin: TNotifyEvent;
    FOnRecognizeProgress: TRecognizerProgressEvent;
    FOnRecognizeEnd: TRecognizerEndEvent;
    function GetPageSegMode: TessPageSegMode;
    procedure SetPageSegMode(APageSegMode: TessPageSegMode);
    procedure SynchronizeProgress;
    procedure SynchronizeBegin;
    procedure SynchronizeEnd;
  public
    /// <summary>
    /// Initializes Tesseract
    /// </summary>
    function Initialize(ADataPath, ALanguage: String): Boolean;
    /// <summary>
    /// Read configuration file
    /// </summary>
    procedure ReadConfigFile(AFileName: String);
    /// <summary>
    /// Read/write configuration variables
    /// </summary>
    function SetVariable(AName: String; AValue: String): Boolean;
    function GetIntVariable(AName: String): Integer;
    function GetBoolVariable(AName: String): Boolean;
    function GetFloatVariable(AName: String): Double;
    function GetStringVariable(AName: String): String;
    /// <summary>
    /// Returns True if language is loaded
    /// </summary>
    function IsLanguageLoaded(ALanguage: String): Boolean;
    /// <summary>
    /// Set source image from a stream (uses Leptonica library).
    /// </summary>
    function SetImage(AStream: TMemoryStream): Boolean; overload;
    /// <summary>
    /// Set source image from a file (uses Leptonica library)
    /// </summary>
    function SetImage(AFileName: String): Boolean; overload;
    /// <summary>
    /// Set source image from a TBitmap
    /// </summary>
    function SetImage(const ABitmap: {$IFNDEF FPC}Vcl.Graphics.{$ENDIF}TBitmap): Boolean; overload;
    /// <summary>
    /// Set source image from a memory buffer
    /// </summary>
    function SetImage(const ABuffer: Pointer; AImageWidth, AImageHeight: Integer;
      ABytesPerPixel: Integer; ABytesPerLine: Integer): Boolean; overload;
    /// <summary>
    /// Deskew source image
    /// </summary>
    procedure DeskewSourceImage;
    /// <summary>
    /// Limit recognition area
    /// </summary>
    procedure SetRectangle(ARectangle: TRect);
    /// <summary>
    /// Set source image PPI
    /// </summary>
    procedure SetSourceResolution(APPI: Integer);
    /// <summary>
    /// Get source image as TPNGImage
    /// </summary>
    function GetSourceImagePNG: {$IFNDEF FPC}Vcl.Imaging.pngimage.TPngImage{$ELSE}TPortableNetworkGraphic{$ENDIF};
    /// <summary>
    /// Get source image as TBitmap
    /// </summary>
    function GetSourceImageBMP: {$IFNDEF FPC}Vcl.Graphics.{$ENDIF}TBitmap;
    /// <summary>
    /// Perform OCR and layout analyse. Will create a separate thread if AInThread
    /// is set to True (default)
    /// </summary>
    procedure Recognize(AUseThread: Boolean = True; ASilent: Boolean = False);
    /// <summary>
    /// Perform OCR and return UTF-8 text (without layout analyse)
    /// </summary>
    function RecognizeAsText(ASilent: Boolean = False): String;
    /// <summary>
    /// Cancel current recognize operation
    /// </summary>
    procedure CancelRecognize;
    /// <summary>
    /// Creates PDF file (source image and searchable text)
    /// </summary>
    function CreatePDF(ASourceFileName: String; AOutputFileName: String): Boolean;
    /// <summary>
    /// Get/set page segmentation mode
    /// </summary>
    property PageSegMode: TessPageSegMode read GetPageSegMode write SetPageSegMode;
    /// <summary>
    /// True if OCR'ing
    /// </summary>
    property Busy: Boolean read FBusy;
    /// <summary>
    /// OCR progress (0-100)
    /// </summary>
    property Progress: Integer read FProgress write FProgress;
    /// <summary>
    /// Recognized text coded as UTF-8
    /// </summary>
    property UTF8Text: String read FUTF8Text write FUTF8Text;
    /// <summary>
    /// Recognized text in HTML format
    /// </summary>
    property HOCRText: String read FHOCRText write FHOCRText;
    /// <summary>
    /// Result of page layout analysis
    /// </summary>
    property PageLayout: TTesseractPageLayout read FPageLayout;
    /// <summary>
    /// Events
    /// </summary>
    property OnRecognizeBegin: TNotifyEvent read FOnRecognizeBegin write FOnRecognizeBegin;
    property OnRecognizeProgress: TRecognizerProgressEvent read FOnRecognizeProgress write FOnRecognizeProgress;
    property OnRecognizeEnd: TRecognizerEndEvent read FOnRecognizeEnd write FOnRecognizeEnd;
    constructor Create(const aDllPath:String);
    destructor Destroy; override;
  end;

var
  Tesseract: TTesseractOCR5 = nil;

implementation

uses tesseractocr.utils;

var
  CancelOCR: Boolean;

{ TTesseractOCR4 }

constructor TTesseractOCR5.Create(const aDllPath:String);
begin
  if (hTesseractLib = 0) then
  begin
    InitTesseractLib(aDllPath);
    if (hTesseractLib = 0)  then    
      raise Exception.Create('Tesseract library is not loaded');
  end;

  if hLeptonicaLib = 0 then
  begin
    InitLeptonicaLib(aDllPath);
    if (hLeptonicaLib = 0)  then    
      raise Exception.Create('Leptonica library is not loaded');
  end;
  
  FTessBaseAPI := TessBaseAPICreate();
  FPageLayout := TTesseractPageLayout.Create(FTessBaseAPI);
end;

destructor TTesseractOCR5.Destroy;
begin
  if FBusy then
  begin
    CancelRecognize;
    FRecognizerThread.WaitFor;
  end;
  if Assigned(FTessBaseAPI) then
  begin
    TessBaseAPIEnd(FTessBaseAPI);
    TessBaseAPIDelete(FTessBaseAPI);
  end;
  if Assigned(FSourcePixImage) then
  begin
    pixDestroy(FSourcePixImage);
    FSourcePixImage := nil;
  end;
  if Assigned(FPageLayout) then
    FPageLayout.Free;
  inherited Destroy;
end;

function TTesseractOCR5.Initialize(ADataPath, ALanguage: String): Boolean;
begin
  Result := False;
  if Assigned(FTessBaseAPI) then
  begin
    FDataPath := ADataPath;
    Result := TessBaseAPIInit3(FTessBaseAPI, PUTF8Char(UTF8Encode(FDataPath)),
      PUTF8Char(UTF8Encode(ALanguage))) = 0;
  end;
end;

procedure TTesseractOCR5.ReadConfigFile(AFileName: String);
begin
  TessBaseAPIReadConfigFile(FTessBaseAPI, PUTF8Char(UTF8Encode(AFileName)));
end;

function TTesseractOCR5.SetVariable(AName: String; AValue: String): Boolean;
begin
  Result := TessBaseAPISetVariable(FTessBaseAPI, PUTF8Char(UTF8Encode(AName)), PUTF8Char(UTF8Encode(AValue)));
end;

function TTesseractOCR5.GetIntVariable(AName: String): Integer;
begin
  Result := 0;                                                                           
  TessBaseAPIGetIntVariable(FTessBaseAPI, PUTF8Char(UTF8Encode(AName)), Result);
end;

function TTesseractOCR5.GetBoolVariable(AName: String): Boolean;
var
  val: LongBool;
begin
  Result := False;
  if TessBaseAPIGetBoolVariable(FTessBaseAPI, PUTF8Char(UTF8Encode(AName)), val) then
    Result := val;
end;

function TTesseractOCR5.GetFloatVariable(AName: String): Double;
begin
  Result := 0;
  TessBaseAPIGetDoubleVariable(FTessBaseAPI, PUTF8Char(UTF8Encode(AName)), Result);
end;

function TTesseractOCR5.GetStringVariable(AName: String): String;
begin
  Result := PUTF8CharToString(TessBaseAPIGetStringVariable(FTessBaseAPI,
    PUTF8Char(UTF8Encode(AName))));
end;

function TTesseractOCR5.IsLanguageLoaded(ALanguage: String): Boolean;
type
  TUTF8Arr = array[0..0] of PUTF8Char;
  PUTF8Arr = ^TUTF8Arr;
var
  arr: PUTF8Arr;
  lang: UTF8String;
  i: Integer;
begin
  Result := False;
  arr := PUTF8Arr(TessBaseAPIGetLoadedLanguagesAsVector(FTessBaseAPI));
  if not Assigned(arr) then Exit;
  i := 0;
  repeat
    SetString(lang, PUTF8Char(arr[i]), Length(arr[i]));
    if (lang = UTF8String(ALanguage)) then
    begin
      Result := True;
      Exit;
    end;
    Inc(i);
  until not Assigned(Pointer(arr[i]));
end;

procedure TTesseractOCR5.SetRectangle(ARectangle: TRect);
begin
  if FBusy then Exit;
  TessBaseAPISetRectangle(FTessBaseAPI, ARectangle.Left, ARectangle.Top,
    ARectangle.Right - ARectangle.Left, ARectangle.Bottom - ARectangle.Top);
end;

procedure TTesseractOCR5.SetSourceResolution(APPI: Integer);
begin
  if FBusy then Exit;
  TessBaseAPISetSourceResolution(FTessBaseAPI, APPI);
end;

function TTesseractOCR5.GetPageSegMode: TessPageSegMode;
begin
  Result := TessBaseAPIGetPageSegMode(FTessBaseAPI);
end;

procedure TTesseractOCR5.SetPageSegMode(APageSegMode: TessPageSegMode);
begin
  if FBusy then Exit;
  TessBaseAPISetPageSegMode(FTessBaseAPI, APageSegMode);
end;

function TTesseractOCR5.SetImage(AFileName: String): Boolean;
begin
  Result := False;
  if FBusy then Exit;
  if Assigned(FSourcePixImage) then
  begin
    pixDestroy(FSourcePixImage);
    FSourcePixImage := nil;
  end;
  FSourcePixImage := pixRead(PUTF8Char(UTF8Encode(AFileName)));
  if Assigned(FSourcePixImage) then
  begin
    TessBaseAPISetImage2(FTessBaseAPI, FSourcePixImage);
    Result := True;
  end;
end;

function TTesseractOCR5.SetImage(const ABitmap: {$IFNDEF FPC}Vcl.Graphics.{$ENDIF}TBitmap): Boolean;
var
  msSourceImage: TMemoryStream;
begin
  Result := False;
  if FBusy then Exit;
  if Assigned(FSourcePixImage) then
  begin
    pixDestroy(FSourcePixImage);
    FSourcePixImage := nil;
  end;
  msSourceImage := TMemoryStream.Create;
  try
    ABitmap.SaveToStream(msSourceImage);
    FSourcePixImage := pixReadMem(msSourceImage.Memory, msSourceImage.Size);
    if Assigned(FSourcePixImage) then
    begin
      TessBaseAPISetImage2(FTessBaseAPI, FSourcePixImage);
      Result := True;
    end;
  finally
    msSourceImage.Free;
  end;
end;

function TTesseractOCR5.SetImage(const ABuffer: Pointer; AImageWidth, AImageHeight: Integer;
  ABytesPerPixel: Integer; ABytesPerLine: Integer): Boolean;
begin
  Result := False;
  if FBusy then Exit;
  if Assigned(ABuffer) then
  begin
    TessBaseAPISetImage(FTessBaseAPI, ABuffer, AImageWidth, AImageHeight,
      ABytesPerPixel, ABytesPerLine);
    Result := True;
  end;
end;

function TTesseractOCR5.SetImage(AStream: TMemoryStream): Boolean;
begin
  Result := False;
  if FBusy then
    Exit;
  if Assigned(FSourcePixImage) then
  begin
    pixDestroy(FSourcePixImage);
    FSourcePixImage := nil;
  end;
  AStream.Position := 0;
  FSourcePixImage := pixReadMem(AStream.Memory, AStream.Size);
  if Assigned(FSourcePixImage) then
  begin
    TessBaseAPISetImage2(FTessBaseAPI, FSourcePixImage);
    Result := True;
  end;
end;

procedure TTesseractOCR5.DeskewSourceImage;
var
  deskewedImage: PPix;
begin
  if Assigned(FSourcePixImage) then
  begin
    deskewedImage := pixDeskew(FSourcePixImage, 0);
    if Assigned(deskewedImage) then
    begin
      pixDestroy(FSourcePixImage);
      FSourcePixImage := deskewedImage;
      TessBaseAPISetImage2(FTessBaseAPI, FSourcePixImage);
    end;
  end;
end;

function TTesseractOCR5.GetSourceImagePNG: {$IFNDEF FPC}Vcl.Imaging.pngimage.TPngImage{$ELSE}TPortableNetworkGraphic{$ENDIF};
var
  pSourceImg: PPix;
  pSourceImagePng: pl_uint8;
  ms: TMemoryStream;
  buffSize: NativeInt;
begin
  Result := {$IFNDEF FPC}Vcl.Imaging.pngimage.TPngImage{$ELSE}TPortableNetworkGraphic{$ENDIF}.Create;

  pSourceImg := TessBaseAPIGetInputImage(FTessBaseAPI);
  if Assigned(pSourceImg) then
  begin
    if pixWriteMemPng(@pSourceImagePng, buffSize, pSourceImg, 0) = 0 then
    begin
      ms := TMemoryStream.Create;
      try
        ms.WriteBuffer(pSourceImagePng^, buffSize);
        ms.Position := 0;
        Result.LoadFromStream(ms);
      finally
        ms.Free;
      end;
      lept_free(pSourceImagePng);
    end;
  end;
end;

function TTesseractOCR5.GetSourceImageBMP: {$IFNDEF FPC}Vcl.Graphics.{$ENDIF}TBitmap;
var
  pSourceImg: PPix;
  pSourceImageBmp: pl_uint8;
  ms: TMemoryStream;
  buffSize: NativeInt;
begin
  Result := {$IFNDEF FPC}Vcl.Graphics.{$ENDIF}TBitmap.Create;

  pSourceImg := TessBaseAPIGetInputImage(FTessBaseAPI);
  if Assigned(pSourceImg) then
  begin
    if pixWriteMemBmp(@pSourceImageBmp, buffSize, pSourceImg) = 0 then
    begin
      ms := TMemoryStream.Create;
      try
        ms.WriteBuffer(pSourceImageBmp^, buffSize);
        ms.Position := 0;
        Result.LoadFromStream(ms);
      finally
        ms.Free;
      end;
      lept_free(pSourceImageBmp);
    end;
  end;
end;

procedure TTesseractOCR5.CancelRecognize;
begin
  if FBusy then CancelOCR := True;
end;

function CancelCallback(cancel_this: Pointer; words: Integer): Boolean; cdecl;
begin
  Result := CancelOCR;
end;

function ProgressCallback(progress: Integer; left, right, top, bottom: Integer): Boolean; cdecl;
begin
  if Assigned(Tesseract) then
  begin
    if Assigned(Tesseract.OnRecognizeProgress) then
    begin
      Tesseract.Progress := progress;
      TThread.Synchronize(nil, {$IFDEF FPC}@{$ENDIF}Tesseract.SynchronizeProgress);
    end;
  end;
  Result := False;
end;

procedure TTesseractOCR5.SynchronizeProgress;
begin
  if Assigned(FOnRecognizeProgress) then
    OnRecognizeProgress(Self, FProgress, CancelOCR);
end;

procedure TTesseractOCR5.SynchronizeBegin;
begin
  if Assigned(FOnRecognizeBegin) then
    OnRecognizeBegin(Self);
end;

procedure TTesseractOCR5.SynchronizeEnd;
begin
  if Assigned(FOnRecognizeEnd) then
    OnRecognizeEnd(Self, CancelOCR);
end;

procedure TTesseractOCR5.RecognizeInternal(ASilent: Boolean);
begin
  FBusy := True;
  FillChar(FProgressMonitor, SizeOf(FProgressMonitor), #0);
  FProgressMonitor.cancel := @CancelCallback;
  FProgressMonitor.progress_callback := @ProgressCallback;
  CancelOCR := False;
  FUTF8Text := '';
  FHOCRText := '';
  if not ASilent then
    TThread.Synchronize(nil, {$IFDEF FPC}@{$ENDIF}Self.SynchronizeBegin);
  try
    if not (TessBaseAPIRecognize(FTessBaseAPI, FProgressMonitor) = 0) then
      Exit;
    FUTF8Text := PUTF8CharToString(TessBaseAPIGetUTF8Text(FTessBaseAPI));
    FUTF8Text := StringReplace(FUTF8Text, #10, #13#10, [rfReplaceAll]);
    FHOCRText := PUTF8CharToString(TessBaseAPIGetHOCRText(FTessBaseAPI, 0));
    FHOCRText := StringReplace(FHOCRText, #10, #13#10, [rfReplaceAll]);
    if FLayoutAnalyse then
      FPageLayout.AnalyseLayout;
  finally
    FBusy := False;
    if not ASilent then
      TThread.Synchronize(nil, {$IFDEF FPC}@{$ENDIF}Self.SynchronizeEnd);
  end;
end;

procedure TTesseractOCR5.Recognize(AUseThread, ASilent: Boolean);
begin
  if FBusy then
    Exit;
  FLayoutAnalyse := True;
  if AUseThread then
    FRecognizerThread := TRecognizerThread.Create(Self)
  else
    RecognizeInternal(ASilent);
end;

function TTesseractOCR5.RecognizeAsText(ASilent: Boolean): String;
begin
  Result := '';
  if FBusy then
    Exit;
  FLayoutAnalyse := False;
  RecognizeInternal(ASilent);
  Result := FUTF8Text;
end;

function TTesseractOCR5.CreatePDF(ASourceFileName: String; AOutputFileName: String): Boolean;
var
  pdfRenderer: TessPDFRenderer;
  outFileName: String;
  exceptionMask: TFPUExceptionMask;
begin
  Result := False;
  if FBusy then Exit;

  {$IFNDEF FPC}
  outFileName := TPath.Combine(TPath.GetDirectoryName(AOutputFileName),
    TPath.GetFileNameWithoutExtension(AOutputFileName));
  {$ELSE}
  outFileName := ConcatPaths([ExtractFileDir(AOutputFileName), ChangeFileExt(AOutputFileName, '')]);
  {$ENDIF}
  exceptionMask := GetExceptionMask;
  SetExceptionMask(exceptionMask + [exZeroDivide, exInvalidOp]);
  try
    pdfRenderer := TessPDFRendererCreate(PUTF8Char(UTF8Encode(outFileName)),
      PUTF8Char(UTF8Encode(FDataPath)), False);
    try
      Result := TessBaseAPIProcessPages(FTessBaseAPI,
        PUTF8Char(UTF8Encode(ASourceFileName)), nil, 0, pdfRenderer);
    finally
      TessDeleteResultRenderer(pdfRenderer);
    end;
  finally
    SetExceptionMask(exceptionMask);
  end;
end;

{ TTesseractOCR4.TRecognizerThread }

constructor TTesseractOCR5.TRecognizerThread.Create(AOwner: TTesseractOCR5);
begin
  inherited Create(False);
  FOwner := AOwner;
  FreeOnTerminate := True;
end;

procedure TTesseractOCR5.TRecognizerThread.Execute;
begin
  FOwner.RecognizeInternal(False);
end;

end.
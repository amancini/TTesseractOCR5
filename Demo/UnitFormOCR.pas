unit UnitFormOCR;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,tesseractocr,
   TreeList,System.Math, Vcl.ExtDlgs;

type
  TRGBColors = array of TRGBQuad;
  TFormOCR = class(TForm)
    pbLayout: TPaintBox;
    panLayoutLeft: TPanel;
    gbPage: TPanel;
    labMeanWordConf: TLabel;
    labOrientation: TLabel;
    labWritingDirect: TLabel;
    pbRecognizeProgress: TProgressBar;
    memText: TMemo;
    cxSplitter1: TSplitter;
    tvLayoutItems: TTreeList;
    Panel1: TPanel;
    Button1: TButton;
    OpenPictureDialog1: TOpenPictureDialog;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure pbLayoutMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pbLayoutMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure pbLayoutPaint(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tvLayoutItemsChange(Sender: TObject; Node: TTreeNode);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FSourceImage         : TBitmap;
    FSelectedLayoutItem  : TObject;
    FSourceImageFileName : String;
    FCurrentScale        : Extended;
    procedure OnRecognizeBegin(Sender: TObject);
    procedure OnRecognizeEnd(Sender: TObject; ACanceled: Boolean);
    procedure OnRecognizeProgress(Sender: TObject; AProgress: Integer;var ACancel: Boolean);
    function PDT2Text(const aFilename: string): boolean;
    procedure ConvertToGrayscale(Bitmap: TBitmap);
  protected
  public
    { Public declarations }
    Procedure LoadFile(Const aFilename:String);
  end;

  var FormOCR : TFormOCR;

implementation

uses
  tesseractocr.pagelayout,
  tesseractocr.utils,
  tesseractocr.capi;

{$R *.dfm}

procedure TFormOCR.FormDestroy(Sender: TObject);
begin
  FreeAndNil(Tesseract);
  if Assigned(FSourceImage) then
    FreeAndNil(FSourceImage)
end;

procedure TFormOCR.FormCreate(Sender: TObject);
begin  
  Tesseract                     := TTesseractOCR5.Create(ExtractFilePath(Application.ExeName)+'DLL\');
  Tesseract.OnRecognizeBegin    := OnRecognizeBegin;
  Tesseract.OnRecognizeProgress := OnRecognizeProgress;
  Tesseract.OnRecognizeEnd      := OnRecognizeEnd;
  if not Tesseract.Initialize( 'tessdata\', 'eng') then
  begin
    MessageDlg('Error loading Tesseract data', mtError, [mbOk], 0);
    Close;
  end;
end;

procedure TFormOCR.OnRecognizeBegin(Sender: TObject);
begin
//  memText.Clear;
  tvLayoutItems.Items.Clear;
  FSelectedLayoutItem := nil;
end;

procedure TFormOCR.OnRecognizeProgress(Sender: TObject;
  AProgress: Integer; var ACancel: Boolean);
begin
  pbRecognizeProgress.Position := AProgress;
end;

procedure TFormOCR.OnRecognizeEnd(Sender: TObject; ACanceled: Boolean);
var Lsymbol        : TTesseractSymbol;
    Lword          : TTesseractWord;
    LtextLine      : TTesseractTextLine;
    Lpara          : TTesseractParagraph;
    Lblock         : TTesseractBlock;
    LblockTree     : TTreeNode;  
    LparaTree      : TTreeNode;
    LtextLineTree  : TTreeNode; 
    LwordTree      : TTreeNode;
begin
  if not ACanceled then
  begin
    pbRecognizeProgress.Position := 100;
    labOrientation.Caption       := Format('Orientation: %s',[PageOrientationToString(Tesseract.PageLayout.Orientation)]);
    labWritingDirect.Caption     := Format('Writing direction: %s',[WritingDirectionToString(Tesseract.PageLayout.WritingDirection)]);
    labMeanWordConf.Caption      := Format('Mean word confidence: %d%%', [Tesseract.PageLayout.MeanWordConfidence]);
    pbLayout.Invalidate;
    tvLayoutItems.Items.BeginUpdate;
    Try
      tvLayoutItems.Items.Clear;
      
      for Lblock in Tesseract.PageLayout.Blocks do
      begin
        LblockTree := tvLayoutItems.Items.AddObject(nil,Format('Block (%s)',[ BlockTypeToString(Lblock.BlockType)]),Lblock);
        for Lpara in Lblock.Paragraphs do
        begin
          LparaTree  := tvLayoutItems.Items.AddChildObject(LblockTree, 'Paragraph',Lpara);
          for LtextLine in Lpara.TextLines do
          begin
            LtextLineTree  := tvLayoutItems.Items.AddChildObject(LparaTree, 'Text line',LtextLine);
            for Lword in LtextLine.Words do
            begin
              LwordTree  := tvLayoutItems.Items.AddChildObject(LtextLineTree, Lword.Text,Lword);
            
              for Lsymbol in Lword.Symbols do
                tvLayoutItems.Items.AddChildObject(LtextLineTree, Lsymbol.Character,Lsymbol);
            end;
          end;
        end;
      end;
      
    Finally
      tvLayoutItems.Items.EndUpdate;
    End;
    
  end 
  else
    pbRecognizeProgress.Position := 0;
end;

procedure TFormOCR.LoadFile(const aFilename: String);
var LBlackAndWhiteImage: String;
    LPDFFile           : String;
begin
  if Tesseract.Busy then Exit;
  
  if Assigned(FSourceImage) then
    FreeAndNil(FSourceImage);
      
  FSourceImageFileName := aFilename;      
  LBlackAndWhiteImage  := ChangeFileExt(FSourceImageFileName,'_BW.bmp');
  {Convert To Gray scale}
  FSourceImage         := TBitmap.Create;
  FSourceImage.LoadFromFile(FSourceImageFileName);
  ConvertToGrayscale(FSourceImage);

  FSourceImage.SaveToFile(LBlackAndWhiteImage);
  

  FSourceImage.LoadFromFile(FSourceImageFileName);  
  if not Assigned(FSourceImage) then Exit;
  
  LPDFFile := ChangeFileExt(LBlackAndWhiteImage,'.pdf');
  DeleteFile(LPDFFile);
  Tesseract.CreatePDF(LBlackAndWhiteImage,LPDFFile);  
  if PDT2Text(LPDFFile) then  
    memText.Lines.LoadFromFile(ChangeFileExt(LBlackAndWhiteImage,'.txt'));
  DeleteFile(LPDFFile);
  DeleteFile(ChangeFileExt(LBlackAndWhiteImage,'.txt'));
  if not Tesseract.SetImage(LBlackAndWhiteImage) then
    raise Exception.Create('SetImage invalid');

  Tesseract.Recognize();  
end;

procedure TFormOCR.pbLayoutMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var Lnode: TTreeNode;
begin
  Lnode := tvLayoutItems.Items[0];
  while Lnode <> nil do
  begin
    if Lnode.Data = FSelectedLayoutItem then
    begin
      tvLayoutItems.Select(Lnode);
      Lnode.MakeVisible;
      Break;
    end;
    Lnode := Lnode.GetNext;
  end;
end;

procedure TFormOCR.pbLayoutMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
var LScaleX   : Double; 
    LScaleY   : Double; 
    LScale    : Double;
    LimgRect  : TRect;
    LPara     : TTesseractParagraph;
    LTextLine : TTesseractTextLine;
    LWord     : TTesseractWord;
    lScaledX  : Integer; 
    LScaledY  : Integer;
begin
  if not Assigned(FSourceImage) then Exit;
  if not Tesseract.PageLayout.DataReady then Exit;
  
  // Calculate the scale factor
  LScaleX := pbLayout.ClientWidth / FSourceImage.Width;
  LScaleY := pbLayout.ClientHeight / FSourceImage.Height;
  LScale  := Min(LScaleX, LScaleY);

  // Calculate the new size of the image
  LimgRect := Rect(0, 0, Round(FSourceImage.Width * LScale), Round(FSourceImage.Height * LScale));

  // Calculate the scaled mouse coordinates
  lScaledX := Round(X / LScale);
  LScaledY := Round(Y / LScale);
  
  // Check if the mouse is over a layout item
  for LWord in Tesseract.PageLayout.Words do
  begin
    if LWord.BoundingRect.Contains(Point(lScaledX, LScaledY)) then
    begin
      if FSelectedLayoutItem <> LWord then
      begin
        FSelectedLayoutItem := LWord;
        InvalidateRect(pbLayout.Canvas.Handle, LWord.BoundingRect, True);
      end;
      Exit;
    end;
  end;

  for LTextLine in Tesseract.PageLayout.TextLines do
  begin
    if LTextLine.BoundingRect.Contains(Point(lScaledX, LScaledY)) then
    begin
      if FSelectedLayoutItem <> LTextLine then
      begin
        FSelectedLayoutItem := LTextLine;
        InvalidateRect(pbLayout.Canvas.Handle, LTextLine.BoundingRect, True);
      end;
      Exit;
    end;
  end;
  
  for LPara in Tesseract.PageLayout.Paragraphs do
  begin
    if LPara.BoundingRect.Contains(Point(lScaledX, LScaledY)) then
    begin
      if FSelectedLayoutItem <> LPara then
      begin
        FSelectedLayoutItem := LPara;
        InvalidateRect(pbLayout.Canvas.Handle, LPara.BoundingRect, True);
      end;    
      Exit;
    end;
  end;
  
end;

procedure TFormOCR.pbLayoutPaint(Sender: TObject);

  procedure DrawScaledImage(ACanvas: TCanvas);
  
    procedure DrawRectAndTextAbove(ACanvasBmp: TCanvas; AText: String; AColor: TColor; ARect: TRect; AScale: Single);
    var LTextSize  : TSize;
        LscaledRect: TRect;
    begin
      // Scale the rectangle coordinates based on the scaling factor
      LscaledRect := Rect(Round(ARect.Left * AScale), 
                          Round(ARect.Top * AScale),
                          Round(ARect.Right * AScale), 
                          Round(ARect.Bottom * AScale));

      ACanvasBmp.Brush.Style := bsClear;
      ACanvasBmp.Pen.Color   := AColor;
      ACanvasBmp.Rectangle(LscaledRect);
      ACanvasBmp.Brush.Color := clGray;
      ACanvasBmp.Pen.Color   := clGray;
      ACanvasBmp.Brush.Style := bsSolid;
      LTextSize              := ACanvasBmp.TextExtent(AText);
      ACanvasBmp.Rectangle( Rect(LscaledRect.Left,
                              LscaledRect.Top - Round(LTextSize.Height * 1.2),
                              LscaledRect.Left + Round(LTextSize.Width * 1.2), 
                              LscaledRect.Top) );
      ACanvasBmp.TextOut(LscaledRect.Left + Round(LTextSize.Width * 0.1), LscaledRect.Top - Round(LTextSize.Height * 1.1), AText);
    end; 
    
  var LBlock    : TTesseractBlock;
      LPara     : TTesseractParagraph;
      LTextLine : TTesseractTextLine;
      LWord     : TTesseractWord;
      LSymbol   : TTesseractSymbol;
      LText     : String;
      LScaleX   : Single;
      LScaleY   : Single;
      LScale    : Single;
      LImgRect  : TRect;
  begin

      ACanvas.FillRect(pbLayout.ClientRect);

      LScaleX := pbLayout.ClientWidth / FSourceImage.Width;
      LScaleY := pbLayout.ClientHeight / FSourceImage.Height;
      LScale  := Min(LScaleX, LScaleY);

      // Calculate the new size of the image
      LimgRect := Rect(0, 0, Round(FSourceImage.Width * LScale), Round(FSourceImage.Height * LScale));

      // Draw the image
      ACanvas.StretchDraw(LimgRect, FSourceImage);
  
      ACanvas.Pen.Style  := psSolid;
      ACanvas.Font.Size  := 10;
      ACanvas.Font.Name  := 'Verdana';
      ACanvas.Font.Color := clWhite;
  
      if Assigned(FSelectedLayoutItem) then
      begin
        if FSelectedLayoutItem is TTesseractBlock then
        begin
          LBlock := TTesseractBlock(FSelectedLayoutItem);
          LText  := Format('Block (%s)',[BlockTypeToString(LBlock.BlockType)]);
          DrawRectAndTextAbove(ACanvas, LText, clBlack, LBlock.BoundingRect,LScale);
        end 
        else if FSelectedLayoutItem is TTesseractParagraph then
        begin
          LPara  := TTesseractParagraph(FSelectedLayoutItem);
          LText  := Format('Paragraph (Justification: %s)',[ ParagraphJustificationToString(LPara.Justification)]);
          DrawRectAndTextAbove(ACanvas, LText, clGreen, LPara.BoundingRect,LScale);
        end 
        else if FSelectedLayoutItem is TTesseractTextLine then
        begin
          LTextLine := TTesseractTextLine(FSelectedLayoutItem);
          LText     := 'Text line';
          DrawRectAndTextAbove(ACanvas, LText, clBlue, LTextLine.BoundingRect,LScale);
        end 
        else if FSelectedLayoutItem is TTesseractWord then
        begin
          LWord := TTesseractWord(FSelectedLayoutItem);
          LText := Format('%s (Confidence: %.2f%%, Language: %s, In dictionary: %s)', [LWord.Text, LWord.Confidence, LWord.Language, BoolToStr(LWord.InDictionary, True)]);
          DrawRectAndTextAbove(ACanvas, LText, clRed, LWord.BoundingRect,LScale);
        end
        else if FSelectedLayoutItem is TTesseractSymbol then
        begin
          Lsymbol := TTesseractSymbol(FSelectedLayoutItem);
          LText := Format('%s (Confidence: %.2f%%)', [Lsymbol.Character, Lsymbol.Confidence]);
          DrawRectAndTextAbove(ACanvas, LText, clRed, Lsymbol.BoundingRect,LScale);
        end;
      end;  
  end;
  
var LBuffer: TBitmap;
begin
  if not Assigned(FSourceImage) then Exit;
  if not Tesseract.PageLayout.DataReady then Exit;

  LBuffer := TBitmap.Create;
  try
    pbLayout.Color := ClWhite;
    LBuffer.Width   := pbLayout.Width;
    LBuffer.Height  := pbLayout.Height;

    // Draw the image and layout onto the buffer
    DrawScaledImage(LBuffer.Canvas);

    // Copy the buffer to the PaintBox
    pbLayout.Canvas.Draw(0, 0, LBuffer);
  finally
    LBuffer.Free;
  end;    
end;

procedure ExecuteAndWait(const aCommando: string);
var tmpStartupInfo       : TStartupInfo;
    tmpProcessInformation: TProcessInformation;
    tmpProgram           : String;
    aIcount              : Integer;
begin
  tmpProgram := trim(aCommando);
  FillChar(tmpStartupInfo, SizeOf(tmpStartupInfo), 0);
  with tmpStartupInfo do
  begin
    cb          := SizeOf(TStartupInfo);
    wShowWindow := SW_HIDE;
  end;

  aIcount := 0;

  if CreateProcess(nil, pchar(WideString(tmpProgram)), nil, nil, true, CREATE_NO_WINDOW,nil, PChar(ExtractFilePath(Application.ExeName)), tmpStartupInfo, tmpProcessInformation)then
  begin
    Try
      while WaitForSingleObject(tmpProcessInformation.hProcess, 10) > 0 do
      begin
        if Application.Terminated then Exit;
        Inc(aIcount);
        if aIcount > 1024 then
        begin
          aIcount := 0;
          Application.ProcessMessages;
        end;
      end;
    Finally
      CloseHandle(tmpProcessInformation.hProcess);
      CloseHandle(tmpProcessInformation.hThread);
    End;
  end
  else
    RaiseLastOSError;
end;

Function TFormOCR.PDT2Text(const aFilename: string):boolean;
var LPDF2Text : string;
    LParams   : string;
begin
  Result := False;
  if not FileExists(aFilename) then
    raise Exception.CreateFmt('Error file not exists %s',[aFilename]);

  LPDF2Text := Format('%s\Utility\pdftotext.exe',[ExtractFilePath(Application.ExeName)]);

  if not FileExists(LPDF2Text) then 
    raise Exception.CreateFmt('Error pdftotext not exists %s',[LPDF2Text]);

  LParams := Format('%s -layout "%s" "%s"', [LPDF2Text,aFilename, ChangeFileExt(aFilename,'.txt')]);

  ExecuteAndWait(LParams);

  Result := FileExists(ChangeFileExt(aFilename,'.txt'));
end;

procedure TFormOCR.ConvertToGrayscale(Bitmap: TBitmap);
var
  x, y: Integer;
  GrayColor: Integer;
  Color: TColor;
begin
  Bitmap.PixelFormat := pf24bit; // Ensure 24-bit pixel format
  for y := 0 to Bitmap.Height - 1 do
  begin
    for x := 0 to Bitmap.Width - 1 do
    begin
      Color := Bitmap.Canvas.Pixels[x, y];
      GrayColor := Round(0.299 * GetRValue(Color) + 0.587 * GetGValue(Color) + 0.114 * GetBValue(Color));
      Bitmap.Canvas.Pixels[x, y] := RGB(GrayColor, GrayColor, GrayColor);
    end;
  end;
end;
  

procedure TFormOCR.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Tesseract.Busy then
    Tesseract.CancelRecognize;
end;

procedure TFormOCR.tvLayoutItemsChange(Sender: TObject; Node: TTreeNode);
begin
  if not Assigned(tvLayoutItems.Selected) then Exit;

  FSelectedLayoutItem := TObject(tvLayoutItems.Selected.Data);
  pbLayout.Invalidate;
end;

procedure TFormOCR.Button1Click(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
    LoadFile(OpenPictureDialog1.FileName);
end;


end.

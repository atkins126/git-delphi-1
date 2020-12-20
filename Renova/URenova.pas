unit URenova;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.StdCtrls, JvExControls,
  JvButton, JvTransparentButton, Vcl.ExtCtrls, XMLIntf, XMLDoc, Vcl.ComCtrls,
  REST.Authenticator.OAuth.WebForm.Win, System.StrUtils, System.Types,
  IPPeerClient, Data.Bind.Components, Data.Bind.ObjectScope, REST.Client,
  REST.Authenticator.OAuth, REST.Authenticator.Basic, REST.Authenticator.Simple,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, IdWebDAV,
  IdIntercept, IdLogBase, IdLogFile, System.Zip, httpsend, synacode, ssl_openssl, synautil,
   Generics.Collections;

const
  cWebDAVServer = 'https://webdav.yandex.ru/';

type
  TWDResource = class
  private
    FHref         : string;
    FStatusCode   : integer;
    FContentLength: int64;
    FCreationDate : TDateTime;
    FLastmodified : TDateTime;
    FDisplayName  : string;
    FContentType  : string;
    FCollection   : Boolean;
  public
    property StatusCode   : integer read FStatusCode;
    property ContentLength: int64 read FContentLength;
    property CreationDate : TDateTime read FCreationDate;
    property Lastmodified : TDateTime read FLastmodified;
    property DisplayName  : string read FDisplayName;
    property ContentType  : string read FContentType;
    property Href: string read FHref;
    property Collection   : Boolean read FCollection;
end;

TWDResourceList = class(TList<TWDResource>)
public
  constructor Create;
  destructor Destroy;override;
  procedure Clear;
end;

type
  TWebDAVSend = class
  private
    FHTTP: THTTPSend;
    FToken: AnsiString;
    FPassword: string;
    FLogin: string;
    procedure SetLogin(const Value: string);
    procedure SetPassword(const Value: string);
    procedure SetToken;
    function EncodeUTF8URI(const URI: string): string;
    function GetRequestURL(const Element: string; EncodePath:boolean=True):string;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    /// Получение свойств каталога или файла.
    /// </summary>
    /// <param name="Depth">
    /// 0 — запрашиваются свойства файла или каталога, непосредственно
    /// указанного в запросе. 1 — запрашиваются свойства каталога, а также
    /// всех элементов, находящихся на первом уровне каталога.
    /// </param>
    /// <param name="Element">
    /// Файл или каталог для которого необходимо получить свойства.
    /// </param>
    /// <returns>
    /// XML-документ, содержащий запрошенные свойства
    /// </returns>
    /// <remarks>
    /// Если Element не определен, то возвращаются свойства корневого каталога
    /// </remarks>
    function PROPFIND(Depth: integer; const Element: String): string;

    ///	<summary>
    ///	  Создание нового каталога на сервере
    ///	</summary>
    ///	<param name="ElementPath">
    ///	  путь к новому каталогу, включая его имя. Согласно протоколу, в
    ///	  результате одного запроса может быть создан только один каталог. Если
    ///	  приложение отправляет запрос о создании каталога a/b/c/, а в каталоге
    ///	  a/ нет каталога b/, то сервис не создает каталог b/, а отвечает c
    ///	  кодом 409 Conflict.
    ///	</param>
    ///	<returns>
    ///	  True - если каталог создан успешно
    ///	</returns>
    function MKCOL(const ElementPath: string):boolean;
    /// <summary>
    ///   Скачивание документа с сервера
    /// </summary>
    function Get(const ElementHref:string; var Response:TStream):boolean;

    property Login: string read FLogin write SetLogin;
    property Password: string read FPassword write SetPassword;
  end;

type
  TFRenova = class(TForm)
    SpeedButton1: TSpeedButton;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    JvTransparentButton1: TJvTransparentButton;
    EServerName: TEdit;
    EInitialCatalog: TEdit;
    eLoginName: TEdit;
    eLoginPass: TEdit;
    eLoginNameCloud: TEdit;
    eLoginPassCloud: TEdit;
    Memo1: TMemo;
    JvTransparentButton2: TJvTransparentButton;
    ListView1: TListView;
    Edit1: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure JvTransparentButton1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure JvTransparentButton2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure EServerNameChange(Sender: TObject);
    procedure EInitialCatalogChange(Sender: TObject);
    procedure eLoginNameChange(Sender: TObject);
    procedure eLoginPassChange(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure Memo1Change(Sender: TObject);
    //procedure JvTransparentButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
   procedure CreateManual_;
   //procedure TitleChanged(const ATitle: string; var DoCloseWebView: boolean);
   //procedure AfterRedirect(const AURL: string; var DoCloseWebView: boolean);
   function LoadSQLFiles:boolean;
   function ClearDir(const Path: string): Boolean;
   function ExtractTo(AArchive, ADestPath:string):boolean;
   Function CopyFilesExt(path:string; ext:string):boolean;
   Function ExecSQLFiles(path:string; ext:string):boolean;
   function ConnectManual_:boolean;
   function GetComputerNetName: string;
   Function RestoreBU(path:string; ext:string):boolean;
   function GetResurce(const Path: string): Boolean;
   Function LoadUpadeteFile(FileName:string):boolean;
  end;

var
  FRenova: TFRenova;
  th, bw, sbw:integer;
  WebDAV: TWebDAVSend;
  Resources: TWDResourceList;
  toolsize:boolean;
implementation
uses DateUtils, Udmod;

resourcestring
  rsPropfindError = 'Ошибка при выполнении запроса PROPFIND';

function TzSpecificLocalTimeToSystemTime(lpTimeZoneInformation: PTimeZoneInformation; var lpLocalTime, lpUniversalTime: TSystemTime): BOOL; stdcall;
  external kernel32 name 'TzSpecificLocalTimeToSystemTime';
{$EXTERNALSYM TzSpecificLocalTimeToSystemTime}

{$R *.dfm}

function SystemTimeToUTC(Sys: TDateTime): TDateTime;
var
  TimeZoneInf: _TIME_ZONE_INFORMATION;
  SysTime, LocalTime: TSystemTime;
begin
  if GetTimeZoneInformation(TimeZoneInf) < $FFFFFFFF then
  begin
    DatetimetoSystemTime(Sys, SysTime);
    if TzSpecificLocalTimeToSystemTime(@TimeZoneInf, SysTime, LocalTime) then
      Result := SystemTimeToDateTime(LocalTime)
    else
      Result := Sys;
  end
  else
    Result := Sys;
end;

function UTCToSystemTime(UTC: TDateTime): TDateTime;
var
  TimeZoneInf: _TIME_ZONE_INFORMATION;
  UTCTime, LocalTime: TSystemTime;
begin
  if GetTimeZoneInformation(TimeZoneInf) < $FFFFFFFF then
  begin
    DatetimetoSystemTime(UTC, UTCTime);
    if SystemTimeToTzSpecificLocalTime(@TimeZoneInf, UTCTime, LocalTime) then
    begin
      Result := SystemTimeToDateTime(LocalTime);
    end
    else
      Result := UTC;
  end
  else
    Result := UTC;
end;


function ISODateTime2UTC(const AValue: string; ADateOnly: Boolean = False): TDateTime;
// 2012-03-13
// 2012-03-13T15:58Z
// 20120313T1558Z
// 2012-03-13T00:00:00.000+07:00
// 20120417T100000
var
  I, Len: Integer;
  DD, MM, YY: Word;
  HH, MN, SS, ZZ: Word;
  HH1, MN1: Integer;
  TimeOffsetSign: Char;
begin
  Len := Length(AValue);
  YY := StrToIntDef(copy(AValue, 1, 4), 0);
  I := 5;
  if (I <= Len) and (AValue[I] = '-') then
    inc(I);
  MM := StrToIntDef(copy(AValue, I, 2), 0);
  inc(I, 2);
  if (I <= Len) and (AValue[I] = '-') then
    inc(I);
  DD := StrToIntDef(copy(AValue, I, 2), 0);
  inc(I, 2);
  HH := 0;
  MN := 0;
  SS := 0;
  ZZ := 0;
  if not ADateOnly and (I <= Len) and (AValue[I] = 'T') then
  begin
    inc(I);
    HH := StrToIntDef(copy(AValue, I, 2), 0);
    inc(I, 2);
    if (I <= Len) and CharInSet(AValue[I], [':', '0' .. '5']) then
    begin
      if AValue[I] = ':' then
        inc(I);
      MN := StrToIntDef(copy(AValue, I, 2), 0);
      inc(I, 2);
      if (I <= Len) and CharInSet(AValue[I], [':', '0' .. '5']) then
      begin
        if AValue[I] = ':' then
          inc(I);
        SS := StrToIntDef(copy(AValue, I, 2), 0);
        inc(I, 2);
        if (I <= Len) and (AValue[I] = '.') then
        begin
          inc(I);
          ZZ := StrToIntDef(copy(AValue, I, 3), 0);
          inc(I, 3);
        end;
      end;
    end;
  end;
  Result := EncodeDateTime(YY, MM, DD, HH, MN, SS, ZZ);
  if ADateOnly then
    Exit;
  if (I <= Len) and CharInSet(AValue[I], ['Z', '+', '-']) then
  begin
    if AValue[I] <> 'Z' then
    begin
      TimeOffsetSign := AValue[I];
      inc(I);
      HH1 := StrToIntDef(copy(AValue, I, 2), 0);
      inc(I, 2);
      if (I <= Len) and CharInSet(AValue[I], [':', '0' .. '5']) then
      begin
        if AValue[I] = ':' then
          inc(I);
        MN1 := StrToIntDef(copy(AValue, I, 2), 0);
      end
      else
        MN1 := 0;
      if TimeOffsetSign = '+' then
      begin
        HH1 := -HH1;
        MN1 := -MN1;
      end;
      Result := IncHour(Result, HH1);
      Result := IncMinute(Result, MN1);
    end;
  end
  else Result := SystemTimeToUTC(Result);
end;

procedure ParseResources(const AXMLStr: string);
var XMLDoc: IXMLDocument;
    ResponseNode,ChildNode,PropNodeChild, PropertyNode: IXMLNode;
     s, su,Value: string;
begin
  XMLDoc:=TXMLDocument.Create(nil);
  try
    XMLDoc.LoadFromXML(AXMLStr);
    if not XMLDoc.IsEmptyDoc then
      begin
        //выбираем первый узел d:response
        ResponseNode:=XMLDoc.DocumentElement.ChildNodes.First;
        while Assigned(ResponseNode) do
          begin
            //создаем запись нового ресурса в списке
            Resources.Add(TWDResource.Create);
            //проходим по дочерним узлам d:response
            ChildNode:=ResponseNode.ChildNodes.First;
            while Assigned(ChildNode) do
              begin
                if ChildNode.NodeName='d:href' then
                   Resources.Last.FHref:=ChildNode.Text
                else
                  //нашли узел со свойствами ресурса
                  if ChildNode.NodeName='d:propstat' then
                    begin
                      //выбираем первый дочерний узел, обычно - это d:status
                      PropNodeChild:=ChildNode.ChildNodes.First;
                      while Assigned(PropNodeChild) do
                        begin
                          //считываем код статуса
                          if PropNodeChild.NodeName='d:status' then
                            begin
                              Value:=PropNodeChild.Text;
                              s := Trim(SeparateRight(Value, ' '));
                              su := Trim(SeparateLeft(s, ' '));
                              Resources.Last.FStatusCode:=StrToIntDef(su, 0);
                            end
                          else
                            //нашли узел d:prop - проходимся по его дочерним узлам
                            if PropNodeChild.NodeName='d:prop' then
                              begin
                                PropertyNode:=PropNodeChild.ChildNodes.First;
                                while Assigned(PropertyNode) do
                                  begin
                                    if PropertyNode.NodeName='d:creationdate' then
                                      Resources.Last.FCreationDate:=UTCToSystemTime(ISODateTime2UTC(PropertyNode.Text))
                                    else
                                      if PropertyNode.NodeName='d:displayname' then
                                        Resources.Last.FDisplayName:=Utf8ToAnsi(PropertyNode.Text)
                                      else
                                        if PropertyNode.NodeName='d:getcontentlength' then
                                          Resources.Last.FContentLength:=PropertyNode.NodeValue
                                        else
                                          if PropertyNode.NodeName='d:getlastmodified' then
                                            Resources.Last.FLastmodified:=DecodeRfcDateTime(PropertyNode.Text)
                                          else
                                            if PropertyNode.NodeName='d:resourcetype' then
                                              Resources.Last.FCollection:=PropertyNode.ChildNodes.Count>0;
                                    //выбираем следующий дочерний узел у d:prop
                                    PropertyNode:=PropertyNode.NextSibling;
                                  end;
                              end;
                          //выбираем следующий дочерний узел у d:propstat
                          PropNodeChild:=PropNodeChild.NextSibling;
                        end;
                    end;
                //выбираем следующий дочерний узел у d:response
                ChildNode:=ChildNode.NextSibling;
              end;
            //выбираем следующий узел d:response
            ResponseNode:=ResponseNode.NextSibling;
          end;
      end;
  finally
    XMLDoc:=nil;
  end;
end;

function TFRenova.GetResurce(const Path: string): Boolean;
var Str: string;
  I: Integer;
  r:boolean;
begin
  r:=false;
  WebDAV.Login := eLoginNameCloud.Text;
  WebDAV.Password := eLoginPassCloud.Text;
  Resources.Clear;
  Str:=WebDAV.PROPFIND(1, Path);//WebDAV.PROPFIND(1, InputBox('Ресурс', 'Ресурс', ''));
  if Length(Trim(Str))>0 then
    begin
      ParseResources(Str);
      for I := 0 to Resources.Count-1 do
        begin
          with ListView1.Items.Add do
            begin
              Caption:=Resources[i].DisplayName;
              SubItems.Add(Resources[i].Href);
              SubItems.Add(DateTimeToStr(Resources[i].CreationDate));
              SubItems.Add(DateTimeToStr(Resources[i].Lastmodified));
              SubItems.Add(IntToStr(Resources[i].ContentLength));
              if Resources[i].Collection then
                SubItems.Add('yes')
              else
                SubItems.Add('no');
              SubItems.Add(IntToStr(Resources[i].StatusCode))
            end;
        end;

      r:=True;
    end else
    begin
      r:=false;
    end;
  Result:=r;
end;

{ TWebDAVSend }

constructor TWebDAVSend.Create;
begin
  inherited;
  FHTTP := THTTPSend.Create;
end;

destructor TWebDAVSend.Destroy;
begin
  FHTTP.Free;
  inherited;
end;

function TWebDAVSend.EncodeUTF8URI(const URI: string): string;
var
  i: integer;
  Char: AnsiChar;
begin
  result := '';
  for i := 1 to length(URI) do
  begin
    if not(URI[i] in URLFullSpecialChar) then
      begin
      for Char in UTF8String(URI[i]) do
        Result:=Result+'%'+IntToHex(Ord(Char), 2)
      end
    else
      Result:=Result+URI[i];
  end;
end;

function TWebDAVSend.Get(const ElementHref: string; var Response:TStream): boolean;
var URL: string;
begin
  if not Assigned(Response) then Exit;
  URL:=GetRequestURL(ElementHref,false);
  with FHTTP do
  begin
    Headers.Clear;
    Document.Clear;
    Headers.Add('Authorization: Basic ' + FToken);
    Headers.Add('Accept: */*');
    if HTTPMethod('GET', URL) then
      begin
        Result:=ResultCode=200;
        if not Result then
          raise Exception.Create(IntToStr(ResultCode)+' '+ResultString)
        else
          Document.SaveToStream(Response);
      end
    else
      raise Exception.Create(rsPropfindError+' '+ResultString);
  end;
end;

function TWebDAVSend.GetRequestURL(const Element: string; EncodePath:boolean): string;
var URI: string;
begin
  if Length(Element)>0 then
    begin
      URI:=Element;
      if URI[1]='/' then
        Delete(URI,1,1);
      if EncodePath then
        Result:=cWebDAVServer+EncodeUTF8URI(URI)
      else
        Result:=cWebDAVServer+URI
    end
  else
   Result:=cWebDAVServer;
end;

function TWebDAVSend.MKCOL(const ElementPath: string): boolean;
begin
  Result:=False;
  with FHTTP do
  begin
    Headers.Clear;
    Document.Clear;
    Headers.Add('Authorization: Basic ' + FToken);
    Headers.Add('Accept: */*');
    if HTTPMethod('MKCOL', GetRequestURL(ElementPath)) then
      begin
        Result:=ResultCode=201;
        if not Result then
          raise Exception.Create(IntToStr(ResultCode)+' '+ResultString);
      end
    else
      raise Exception.Create(rsPropfindError+' '+ResultString);
  end;
end;

function TWebDAVSend.PROPFIND(Depth: integer; const Element: String): string;
begin
  with FHTTP do
  begin
    Headers.Clear;
    Document.Clear;
    Headers.Add('Authorization: Basic ' + FToken);
    Headers.Add('Depth: ' + IntToStr(Depth));
    Headers.Add('Accept: */*');
    if HTTPMethod('PROPFIND', GetRequestURL(Element)) then
      result := ReadStrFromStream(Document, Document.Size)
    else
      raise Exception.Create(rsPropfindError+' '+ResultString);
  end;
end;

procedure TWebDAVSend.SetToken;
begin
  FToken := EncodeBase64(FLogin + ':' + FPassword);
end;

procedure TWebDAVSend.SetLogin(const Value: string);
begin
  FLogin := Value;
  SetToken;
end;

procedure TWebDAVSend.SetPassword(const Value: string);
begin
  FPassword := Value;
  SetToken;
end;


{ TWDResourceList }

procedure TWDResourceList.Clear;
var i:integer;
begin
  for I := Count-1 downto 0 do
    Extract(Items[0]).Free;
  inherited Clear;
end;

constructor TWDResourceList.Create;
begin
  inherited Create;
end;

destructor TWDResourceList.Destroy;
begin
  Clear;
  inherited;
end;


function TFRenova.ClearDir(const Path: string): Boolean;
const
    FileNotFound = 18;
var
    sr: TSearchRec;
  DosCode: Integer;
begin
    Result := DirectoryExists(Path);
    if not Result then Exit;
    DosCode := FindFirst(ExcludeTrailingBackslash(Path) + '\*.*', faAnyFile, sr);
  try
    while DosCode = 0 do begin
            if (sr.Name <> '.') and (sr.Name <> '..') and (sr.Attr <> faVolumeID) then
            begin
                if (sr.Attr and faDirectory = faDirectory) then
                    Result := ClearDir(ExcludeTrailingBackslash(Path) + '\'+sr.Name) and Result
                else if (sr.Attr and faVolumeID <> faVolumeID) then begin
                    if (sr.Attr and faReadOnly = faReadOnly) then
                        FileSetAttr(ExcludeTrailingBackslash(Path) + '\' + sr.Name, faArchive);
                    Result := DeleteFile(PChar(ExcludeTrailingBackslash(Path) + '\' + sr.Name)) and Result;
                end;
            end;
            DosCode := FindNext(sr);
        end;
    finally
        FindClose(sr);
    end;
    Result := (IOResult = 0) and Result;
end;

function TFRenova.ExtractTo(AArchive, ADestPath:string):boolean;
var fzip:TZipFile;
    b:boolean;
begin
  b:=false;
  fzip:=TZipFile.Create();
  try
      fzip.ExtractZipFile(AArchive,ADestPath);
      b:=true;
  except on E:Exception do
    begin
      ShowMessage(E.ClassName+' поднята ошибка, с сообщением : '+E.Message);
      memo1.Lines.Add('Ошибка: '+E.Message);
      b:=false;
    end;
  end;
  fzip.Free;
  ExtractTo:=b;
end;

Function TFRenova.CopyFilesExt(path:string; ext:string):boolean;
var b:boolean;
    SearchRec:TSearchRec;
begin
  b:=true;
  memo1.Lines.Add('Скопировать '+ext+' если есть...');
  if FindFirst(path+'*.'+ext, faAnyFile, SearchRec)=0 then
    repeat
      begin
        if (SearchRec.name <> '.') and (SearchRec.name <> '..') then
          begin
            memo1.Lines.Add('Скопировать '+ext+' '+SearchRec.name);
              if not CopyFile(PChar(path+SearchRec.name), PChar(ExtractFilePath(Application.ExeName)+SearchRec.name), False) then
                begin
                  MessageBox(FRenova.Handle, PChar('Неудалось скопировать файл '+PChar(path+SearchRec.name)), 'Ошибка', MB_OK);
                  memo1.Lines.Add('Ошибка: Неудалось скопировать файл '+PChar(path+SearchRec.name));
                  b:=false;
                end;
          end;
      end;
    until FindNext(SearchRec)<>0;
  FindClose(SearchRec);
  result:=b;
end;

Function TFRenova.RestoreBU(path:string; ext:string):boolean;
var b:boolean;
    SearchRec:TSearchRec;
    ds, s:string;
    sfilemdf, sfileldf:string;
    snamemdf, snameldf:string;
    sdbname:string;
begin
  b:=true;
  memo1.Lines.Add('Ищем БАКАП '+ext+'...');
  if FindFirst(path+'*.'+ext, faAnyFile, SearchRec)=0 then
    repeat
      begin
        if (SearchRec.name <> '.') and (SearchRec.name <> '..') then
          begin
            memo1.Lines.Add('Восстанавливаем из файла '+ext+' '+SearchRec.name);

            sdbname:=Leftstr(SearchRec.name, Pos('_', SearchRec.name)-1);

            dmod.FDQuery1.Cancel;
            dmod.FDQuery1.Close;
            s:='USE ['+EInitialCatalog.Text+']';
            dmod.FDQuery1.SQL.Text:=s;
            dmod.FDQuery1.Execute;

            dmod.FDQuery1.Cancel;
            dmod.FDQuery1.Close;
            dmod.FDQuery1.SQL.Text:='SELECT * FROM sys.database_files';
            dmod.FDQuery1.OpenOrExecute;
            dmod.FDQuery1.First;
            while not dmod.FDQuery1.Eof do
              begin
                if dmod.FDQuery1.FieldByName('type').AsInteger=0 then
                  begin
                    sfilemdf:=dmod.FDQuery1.FieldByName('physical_name').AsString;
                    snamemdf:=dmod.FDQuery1.FieldByName('name').AsString;
                  end;
                if dmod.FDQuery1.FieldByName('type').AsInteger=1 then
                  begin
                    sfileldf:=dmod.FDQuery1.FieldByName('physical_name').AsString;
                    snameldf:=dmod.FDQuery1.FieldByName('name').AsString;
                  end;
                dmod.FDQuery1.Next;
              end;

            try
              dmod.FDQuery1.Cancel;
              dmod.FDQuery1.Close;
              s:='USE master;';
              dmod.FDQuery1.SQL.Text:=s;
              dmod.FDQuery1.Execute;

              dmod.FDQuery1.Cancel;
              dmod.FDQuery1.Close;
              s:='alter database ['+EInitialCatalog.Text+'] set offline with rollback immediate;';
              dmod.FDQuery1.SQL.Text:=s;
              dmod.FDQuery1.Execute;

              dmod.FDQuery1.Cancel;
              dmod.FDQuery1.Close;
              ds:=path+SearchRec.name;
              s:='RESTORE DATABASE ['+EInitialCatalog.Text+'] FILE = N'+''''+sdbname+''''+' FROM  DISK = N'+''''+ds+''''+'  WITH  FILE = 1,'+chr(10)+chr(13);
              s:=s+'MOVE N'+''''+snamemdf+''''+' TO N'+''''+sfilemdf+''''+', '+chr(10)+chr(13);
              s:=s+'MOVE N'+''''+snameldf+''''+' TO N'+''''+sfileldf+''''+', '+chr(10)+chr(13);
              s:=s+'NOUNLOAD,  REPLACE,  STATS = 10;';
              dmod.FDQuery1.SQL.Text:=s;
              dmod.FDQuery1.Execute;
            except on E:Exception do
              begin
                MessageBox(FRenova.Handle, PChar(E.ClassName+' неудалось восстановить файл : '+E.Message),'Ошибка', MB_OK);
                memo1.Lines.Add('Ошибка: Неудалось восстановить файл( '+E.Message+')');
                b:=false;
              end;
            end;
          end;
      end;
    until FindNext(SearchRec)<>0;
  FindClose(SearchRec);
  result:=b;
end;


procedure TFRenova.EInitialCatalogChange(Sender: TObject);
begin
 dmod.FDCCompareBDM.Close;
 JvTransparentButton1.Font.Color:=clRed;
end;

procedure TFRenova.eLoginNameChange(Sender: TObject);
begin
 dmod.FDCCompareBDM.Close;
 JvTransparentButton1.Font.Color:=clRed;
end;

procedure TFRenova.eLoginPassChange(Sender: TObject);
begin
 dmod.FDCCompareBDM.Close;
 JvTransparentButton1.Font.Color:=clRed;
end;

procedure TFRenova.EServerNameChange(Sender: TObject);
begin
 dmod.FDCCompareBDM.Close;
 JvTransparentButton1.Font.Color:=clRed;
end;

Function TFRenova.ExecSQLFiles(path:string; ext:string):boolean;
var b:boolean;
    SearchRec:TSearchRec;
begin
  dmod.FDQuery1.Cancel;
  dmod.FDQuery1.Close;
  dmod.FDQuery1.SQL.Text:='USE '+EInitialCatalog.Text;
  dmod.FDQuery1.Execute;

  b:=true;
  //поиск файлов SQL в папке
  memo1.Lines.Add('поиск файлов SQL в папке...');
  if FindFirst(path+'*.sql', faAnyFile, SearchRec)=0 then
    repeat
      begin
        if (SearchRec.name <> '.') and (SearchRec.name <> '..') then
          begin
            //Выполнение SQL
            memo1.Lines.Add('Выполнение SQL файла '+SearchRec.name);
            try
              dmod.FDQuery1.Cancel;
              dmod.FDQuery1.Close;
              dmod.FDQuery1.SQL.LoadFromFile(path+SearchRec.name);
              dmod.FDQuery1.Execute;
            except on E:Exception do
              begin
                MessageBox(FRenova.Handle, PChar(E.ClassName+' поднята ошибка, с сообщением : '+E.Message),'Ошибка', MB_OK);
                memo1.Lines.Add('Ошибка: '+E.Message);
                b:=false;
              end;
            end;
          end;
      end;
    until FindNext(SearchRec)<>0;
  FindClose(SearchRec);
  result:=b;
end;


procedure TFRenova.ListView1DblClick(Sender: TObject);
var Res:TWDResource;
    Stream:TStream;
begin
  if ListView1.ItemIndex>-1 then
    Res:=Resources[ListView1.ItemIndex];
  Stream:=TMemoryStream.Create;
  try
    if WebDAV.Get(Res.Href,Stream) then
      TMemoryStream(Stream).SaveToFile(ExtractFilePath(Application.ExeName)+Res.DisplayName);
  finally
    Stream.Free;
  end;
end;

Function TFRenova.LoadUpadeteFile(FileName:string):boolean;
var Res:TWDResource;
    Stream:TStream;
    r:boolean;
    i:integer;
    lvItem: TListItem;
begin
  r:=false;

  lvItem:=ListView1.FindCaption(0, // StartIndex: Integer;
  FileName, // Search string: string;
  True, // Partial,
  True, // Inclusive
  False); // Wrap : boolean;
  if lvItem <> nil then
    begin
      ListView1.Selected:=lvItem;
      lvItem.MakeVisible(True);
      ListView1.SetFocus;
    end;
  i:=ListView1.ItemIndex;

  if (ListView1.Items.Count=0) or (i=-1) then
    begin
      r:=false;
    end else
  begin
    r:=true;
    Res:=Resources[i];//ListView1.ItemIndex
    Stream:=TMemoryStream.Create;
    try
      if WebDAV.Get(Res.Href,Stream) then
        TMemoryStream(Stream).SaveToFile(ExtractFilePath(Application.ExeName)+Res.DisplayName);
    finally
      Stream.Free;
    end;
  end;
  result:=r;
end;

procedure TFRenova.Memo1Change(Sender: TObject);
begin
  if Memo1.Lines[0]='Чита' then
    begin
     eLoginNameCloud.Visible:=true;
     eLoginPassCloud.Visible:=true;
     Edit1.Visible:=true;
     ListView1.Visible:=true;
     toolsize:=true;
     FRenova.Height:=ListView1.Top+ListView1.Height+th+10;
     toolsize:=false;
    end else
    begin
     eLoginNameCloud.Visible:=true;
     eLoginPassCloud.Visible:=true;
     Edit1.Visible:=true;
     ListView1.Visible:=true;
     toolsize:=true;
     FRenova.Height:=JvTransparentButton1.Top+JvTransparentButton1.Height+th+10;
     FRenova.Width:=JvTransparentButton1.Left+JvTransparentButton1.Width+bw+10;
     toolsize:=false;
    end;
end;

Function TFRenova.LoadSQLFiles:boolean;
var
  infiles:integer;
  SearchRec: TSearchRec;
  path:string;
  ds:string;
begin
     path:=ExtractFilePath(Application.ExeName)+'Recova\';
     memo1.clear;
     try
       //Создадим папку для бакапа
       memo1.Lines.Add('Создадим папку для бакапа...');
       if not DirectoryExists(ExtractFilePath(Application.ExeName)+'BUBD\') then
         begin
           if not ForceDirectories(ExtractFilePath(Application.ExeName)+'BUBD\') then
             begin
              MessageBox(FRenova.Handle, 'Неудалось создать папку для бакапа.', 'Ошибка', MB_OK);
              memo1.Lines.Add('Ошибка: Неудалось создать папку для бакапа...');
              exit;
             end;
         end;

       memo1.Lines.Add('Создадим папку для лога...');
       if not DirectoryExists(ExtractFilePath(Application.ExeName)+'LOGBD\') then
         begin
           if not ForceDirectories(ExtractFilePath(Application.ExeName)+'LOGBD\') then
             begin
              MessageBox(FRenova.Handle, 'Неудалось создать папку для бакапа.', 'Ошибка', MB_OK);
              memo1.Lines.Add('Ошибка: Неудалось создать папку для бакапа...');
              exit;
             end;
         end;

       //Проверка запущенной программы, если запущенна, то выходим
       memo1.Lines.Add('Проверка запущенной программы...');
       if (FindWindow('TFOrdersPlan', 'План') <> 0) then
         begin
          MessageBox(FRenova.Handle, 'Программа запущена, для обновления закройте программу и запустите обновление еще раз.', 'Ошибка', MB_OK);
          memo1.Lines.Add('Ошибка: Программа запущена...');
          exit;
         end;
       //---------------------------------------------------------

       //очистить папку
       memo1.Lines.Add('Очищаем папку обновления...');
       if DirectoryExists(Path) then
       if NOT ClearDir(path) then
         begin
          MessageBox(FRenova.Handle, PChar('Неудалось очистить папку '+path), 'Ошибка', MB_OK);
          memo1.Lines.Add('Ошибка: Неудалось очистить папку '+path);
          exit;
         end;
       //---------------------------------------------------------

       //Удаляем папку, если папка осталась, то выходим
       memo1.Lines.Add('Удаляем папку...');
       if not RemoveDirectory(PChar(path)) then
       if DirectoryExists(Path) then
         begin
          MessageBox(FRenova.Handle, PChar('Неудалось удалить папку '+path), 'Ошибка', MB_OK);
          memo1.Lines.Add('Ошибка: Неудалось удалить папку '+path);
          exit;
         end;
       //---------------------------------------------------------

       //Проверка наличия файла обновления, если его нет, то выходим
       memo1.Lines.Add('Проверка наличия файла обновления...');
       if not FileExists(ExtractFilePath(Application.ExeName)+'Update.zip') then
         begin
          MessageBox(FRenova.Handle, PChar('Ненайден файл '+ExtractFilePath(Application.ExeName)+'Update.zip'), 'Ошибка', MB_OK);
          memo1.Lines.Add('Ошибка: Ненайден файл '+ExtractFilePath(Application.ExeName)+'Update.zip');
          exit;
         end;

       //---------------------------------------------------------
       //Распаковка файлов обновления, если не получилось, то выходим
       memo1.Lines.Add('Распаковка файлов обновления...');
       if not ExtractTo(ExtractFilePath(Application.ExeName)+'\Update.zip', ExtractFilePath(Application.ExeName)) then
         begin
          MessageBox(FRenova.Handle, PChar('Нераспакован файл '+ExtractFilePath(Application.ExeName)+'\Update.zip'), 'Ошибка', MB_OK);
          memo1.Lines.Add('Ошибка: Нераспакован файл '+ExtractFilePath(Application.ExeName)+'\Update.zip');
          exit;
         end;
       //---------------------------------------------------------

       if not CopyFilesExt(path, 'exe') then exit;
       if not CopyFilesExt(path, 'ini') then exit;
       if not CopyFilesExt(path, 'doc') then exit;
       if not CopyFilesExt(path, 'docx') then exit;
       if not CopyFilesExt(path, 'xls') then exit;
       if not CopyFilesExt(path, 'xlsx') then exit;

       //бакап
       memo1.Lines.Add('Создадим БАКАП...');
       dmod.FDQuery1.Cancel;
       dmod.FDQuery1.Close;
       ds:=ExtractFilePath(Application.ExeName)+'BUBD\'+EInitialCatalog.Text+'_'+formatdatetime('dd_mm_yyyy_hh_nn', now)+'.bak';
       dmod.FDQuery1.SQL.Text:='USE master;'+chr(10)+chr(13)+
       'BACKUP DATABASE ['+EInitialCatalog.Text+'] TO  DISK = N'+''''+ds+''''+' WITH  INIT ,  NOUNLOAD ,  NAME = N'+''''+EInitialCatalog.Text+' backup'+''''+',  NOSKIP , STATS = 10,  NOFORMAT';
       dmod.FDQuery1.Execute;

       if not RestoreBU(path, 'bak') then exit;

       if not ExecSQLFiles(path, 'sql') then exit;

       //очистить папку
       memo1.Lines.Add('Очищаем папку обновления...');
       if DirectoryExists(Path) then
       if NOT ClearDir(path) then
         begin
          MessageBox(FRenova.Handle, PChar('Неудалось очистить папку '+path), 'Ошибка', MB_OK);
          memo1.Lines.Add('Ошибка: Неудалось очистить папку '+path);
         end;
       //---------------------------------------------------------

       //Удаляем папку, если папка осталась, то выходим
       memo1.Lines.Add('Удаляем папку...');
       if not RemoveDirectory(PChar(path)) then
       if DirectoryExists(Path) then
         begin
          MessageBox(FRenova.Handle, PChar('Неудалось удалить папку '+path), 'Ошибка', MB_OK);
          memo1.Lines.Add('Ошибка: Неудалось удалить папку '+path);
         end;
       //---------------------------------------------------------

       //Проверка наличия файла обновления, если есть, то удаляем
       memo1.Lines.Add('Проверка наличия файла обновления...');
       if FileExists(ExtractFilePath(Application.ExeName)+'Update.zip') then
         begin
          CopyFile(PChar(ExtractFilePath(Application.ExeName)+'Update.zip'), PChar(ExtractFilePath(Application.ExeName)+'Update_'+FormatDateTime('yyyymmdd_hhnnss', Now)+'.zip'), False);
          DeleteFile(ExtractFilePath(Application.ExeName)+'Update.zip');
         end;
     finally
       Memo1.Lines.SaveToFile(ExtractFilePath(Application.ExeName)+'LOGBD\'+'logbu_'+formatdatetime('dd_mm_yyyy_hh_nn_ss', now)+'.txt');
     end;

end;

function TFRenova.GetComputerNetName: string;
var
  buffer: array[0..255] of char;
  size: dword;
begin
  size := 256;
  if GetComputerName(buffer, size) then
    Result := buffer
  else
    Result := ''
end;

function TFRenova.ConnectManual_:boolean;
var i:byte;
    ss:widestring;
begin
  try
  with dmod do
    begin
      if dmod.FDCCompareBDM.Connected then dmod.FDCCompareBDM.Close;

      dmod.FDCCompareBDM.Params.Clear;
      dmod.FDCCompareBDM.Params.Values['Login Prompt']:='False';
      dmod.FDCCompareBDM.Params.Values['DriverID']:='MSSQL';
      dmod.FDCCompareBDM.Params.Values['DriverName']:='MSSQL';
      dmod.FDCCompareBDM.Params.Values['BusyTimeout']:='5000';
      dmod.FDCCompareBDM.Params.Values['OSAuthent']:='No';
      dmod.FDCCompareBDM.Params.Values['ApplicationName']:=EInitialCatalog.Text;
      dmod.FDCCompareBDM.Params.Values['Server']:=EServerName.Text;
      dmod.FDCCompareBDM.Params.Values['Workstation']:=GetComputerNetName;
      dmod.FDCCompareBDM.Params.Values['MARS']:='Yes';
      dmod.FDCCompareBDM.Params.Values['Database']:=EInitialCatalog.Text;
      dmod.FDCCompareBDM.Params.Values['User_Name']:=eLoginName.text;
      dmod.FDCCompareBDM.Params.Values['Password']:=eLoginPass.Text;
    try
      dmod.FDCCompareBDM.Open();
      ConnectManual_:=true;
      JvTransparentButton1.Font.Color:=clGreen;
    except
      MessageBox(FRenova.Handle, 'Не удалось соединиться с сервером.', 'Ошибка', MB_OK);
      ConnectManual_:=false;
      JvTransparentButton1.Font.Color:=clRed;
    end;

  end;
  finally

  end;
end;

procedure TFRenova.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if toolsize then Resize:=true else Resize:=false;


end;

procedure TFRenova.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  try
    Memo1.Lines.SaveToFile(ExtractFilePath(Application.ExeName)+'LOGBD\'+'logbu_'+formatdatetime('dd_mm_yyyy_hh_nn_ss', now)+'.txt');
  finally

  end;
end;

procedure TFRenova.FormCreate(Sender: TObject);
begin
  WebDAV := TWebDAVSend.Create;
  Resources:=TWDResourceList.Create;

  FRenova.Position:=poScreenCenter;
  FRenova.FormStyle:=fsStayOnTop;
  FRenova.HorzScrollBar.Visible:=false;
  FRenova.VertScrollBar.Visible:=true;
  FRenova.AutoScroll:=true;
  toolsize:=true;
  FRenova.Height:=JvTransparentButton1.Top+JvTransparentButton1.Height+10;
  FRenova.Width:=JvTransparentButton1.Left+JvTransparentButton1.Width+10;
  toolsize:=false;


end;

procedure TFRenova.FormDestroy(Sender: TObject);
begin
  Resources.Free;
  WebDAV.Free;
end;

procedure TFRenova.FormShow(Sender: TObject);
begin
  th:=GetSystemMetrics(SM_CYCAPTION)+GetSystemMetrics(SM_CXFRAME);
  bw:=GetSystemMetrics(SM_CXFRAME);
  sbw:=GetSystemMetrics(SM_CXHSCROLL);

  FRenova.AutoSize:=true;
  FRenova.AutoSize:=False;

  toolsize:=true;
  FRenova.Height:=JvTransparentButton1.Top+JvTransparentButton1.Height+bw*2+th+bw;
  FRenova.Width:=JvTransparentButton1.Left+JvTransparentButton1.Width+bw*2;
  toolsize:=false;

  Memo1.Lines.Clear;

  CreateManual_;
  if not ConnectManual_ then
    MessageBox(FRenova.Handle, 'Попробуйте поменть настройки подключения к серверу', 'Внимание', MB_OK);

end;

procedure TFRenova.JvTransparentButton1Click(Sender: TObject);
begin

  if JvTransparentButton1.Font.Color=clRed then exit;

  ListView1.Clear;
  //Поиск папки обновления, если папка осталась, то выходим
  memo1.Lines.Add('Поиск папки обновления...');
  if not GetResurce('BU') then
   begin
    MessageBox(FRenova.Handle, PChar('Неудалось найти папку обновления'), 'Ошибка', MB_OK);
    memo1.Lines.Add('Ошибка: Неудалось найти папку обновления');
    exit;
   end;
  //Поиск папки обновления, если папка осталась, то выходим
  memo1.Lines.Add('Поиск файл обновления...');
  if not LoadUpadeteFile('Update.zip') then
   begin
    MessageBox(FRenova.Handle, PChar('Неудалось найти файл обновления'), 'Ошибка', MB_OK);
    memo1.Lines.Add('Ошибка: Неудалось найти файл обновления');
    exit;
   end;

  LoadSQLFiles;
end;

procedure TFRenova.JvTransparentButton2Click(Sender: TObject);
var S:string;
    f:TextFile;
begin
  try
   system.assign(f,ExtractFilePath(application.exename)+'renova.ini');
   system.ReWrite(f);
   S:=EServerName.Text;
   writeln(f,S);
   S:=EInitialCatalog.Text;
   writeln(f,S);
   S:=eLoginName.Text;
   writeln(f,S);
   S:=eLoginPass.Text;
   writeln(f,S);
   system.Close(f);
  except
   MessageBox(FRenova.Handle, 'Не удалось записать данные в файл', 'Ошибка', MB_OK);
  end;
  if not ConnectManual_ then
    MessageBox(FRenova.Handle, 'Попробуйте поменть настройки подключения к серверу', 'Внимание', MB_OK);

end;

function SeparateLeft(const Value, Delimiter: string): string;
var
x: Integer;
begin
x := Pos(Delimiter, Value);
if x < 1 then
Result := Value
else
Result := Copy(Value, 1, x - 1);
end;

function SeparateRight(const Value, Delimiter: string): string;
var
x: Integer;
begin
x := Pos(Delimiter, Value);
if x > 0 then
x := x + Length(Delimiter) - 1;
Result := Copy(Value, x + 1, Length(Value) - x);
end;

procedure TFRenova.CreateManual_;
var S:string;
    f:TextFile;
    Lastselected:byte;
begin
   if not FileExists('renova.ini') then
     CopyFile(PChar(ExtractFilePath(application.exename)+'obf.ini'), PChar(ExtractFilePath(application.exename)+'renova.ini'), false);

   system.assign(f,ExtractFilePath(application.exename)+'renova.ini');
   if FileExists('renova.ini') then
     begin
       system.Reset(f);
       readln(f,S);
       EServerName.Text:=S;
       readln(f,S);
       EInitialCatalog.Text:=S;
       readln(f,S);
       //eLoginName.Text:=S;
       eLoginName.Text:='sa';
       readln(f,S);
       //eLoginPass.Text:=S;
       eLoginPass.Text:='rjnnbvrf';
       readln(f,S);
       system.Close(f);
     end;

   //ProgramIcon.Picture.Icon.Handle := LoadIcon(HInstance, 'MAINICON');

   eLoginNameCloud.Text:='OBFCompare';
   eLoginPassCloud.Text:='!OBFCompare5';
   S:=Application.ExeName;
end;
end.
{
procedure TFRenova.AfterRedirect(const AURL: string; var DoCloseWebView: boolean);
var Str:String;
StrArr:TStringDynArray;
begin
Memo1.Lines.Add('after redirect to '+AURL);
if StartsText('https://localhost',AURL) then begin
DoCloseWebView:=true;
//разбиваем строку
StrArr:=SplitString(AURL,'?=&');
Str:=StrArr[1];
if Str='code' then begin
// и делаем запрос на получение токена
// код подтверждения во втором элементе
OAuth2Authenticator1.AuthCode:=StrArr[2];
OAuth2Authenticator1.ChangeAuthCodeToAccesToken;
Memo1.Lines.Add(OAuth2Authenticator1.AccessToken);
Memo1.Lines.Add(OAuth2Authenticator1.RefreshToken);
Memo1.Lines.Add(DateTimeToStr(OAuth2Authenticator1.AccessTokenExpiry));
end;
if Str='error' then begin
// обрабатываем ошибку
if StrArr[2]='access_denied' then
ShowMessage('Отказ в предоставлении доступа');
if StrArr[2]='unauthorized_client' then
ShowMessage('Приложение заблокировано, либо ожидает модерации');
end;
end;
end;

procedure TFRenova.TitleChanged(const ATitle: string;
var DoCloseWebView: boolean);
begin
Memo1.Lines.Add('== '+ATitle);
end;
}
{
procedure TFRenova.JvTransparentButton1Click(Sender: TObject);

Var
 s, r: TStringStream;
 u: UTF8String;
begin
  u := '<propertyupdate xmlns="DAV:">' + sLineBreak +
  '<set>'  + sLineBreak +
    '<prop>'  + sLineBreak +
      '<public_url xmlns="urn:yandex:disk:meta">true</public_url>'  + sLineBreak +
    '</prop>'  + sLineBreak +
  '</set>'  + sLineBreak +
'</propertyupdate>';

  s := TStringStream.Create(u);

  s.Seek(0, 0);

  r := TStringStream.Create('');
  try
    IdWebDAV1.Request.Clear;
    IdWebDAV1.Request.CharSet := 'UTF-8';
    IdWebDAV1.Request.BasicAuthentication := False;
    IdWebDAV1.Request.Host := 'webdav.yandex.ru';
    IdWebDAV1.Request.CustomHeaders.Add('Authorization: OAuth 17ecaddc1edc4b83a5818c47e9b794b1');
    IdLogFile1.Active := True;
    IdWebDAV1.DAVPut('https://webdav.yandex.ru/tst/readme.txt', r, s);//DAVPropPatch
    r.Position := 0;
    Memo1.Lines.Text :=UTF8Decode(r.DataString);
  finally
    s.Free;
    r.Free;
  end;
end;
 }
{
procedure TFRenova.JvTransparentButton1Click(Sender: TObject);
var wf: Tfrm_OAuthWebForm;
begin
//создаем окно с браузером
//для перенаправления пользователя на страницу Яндекс
wf:=Tfrm_OAuthWebForm.Create(self);
try
//определяем обработчик события смены Title
wf.OnTitleChanged:=TitleChanged;
wf.OnAfterRedirect:=AfterRedirect;
//показываем окно и открываем
//в браузере URL с формой подтверждения доступа
wf.ShowModalWithURL(OAuth2Authenticator1.AuthorizationRequestURI);
finally
FreeAndNil(wf);
end;
end;
}
{
procedure TFRenova.JvTransparentButton1Click(Sender: TObject);
procedure ParseResources(const AXMLStr: string);
var XMLDoc: IXMLDocument;
    ResponseNode,ChildNode,PropNodeChild, PropertyNode: IXMLNode;
     s, su,Value: string;
begin
  XMLDoc:=TXMLDocument.Create(nil);
  try
    XMLDoc.LoadFromXML(AXMLStr);
    if not XMLDoc.IsEmptyDoc then
      begin
        ResponseNode:=XMLDoc.DocumentElement.ChildNodes.First;
        while Assigned(ResponseNode) do
          begin
            Resources.Add(TWDResource.Create);
            ChildNode:=ResponseNode.ChildNodes.First;
            while Assigned(ChildNode) do
              begin
                if ChildNode.NodeName='d:href' then
                   Resources.Last.FHref:=ChildNode.Text
                else
                  if ChildNode.NodeName='d:propstat' then
                    begin
                      PropNodeChild:=ChildNode.ChildNodes.First;
                      while Assigned(PropNodeChild) do
                        begin
                          if PropNodeChild.NodeName='d:status' then
                            begin
                              Value:=PropNodeChild.Text;
                              s := Trim(SeparateRight(Value, ' '));
                              su := Trim(SeparateLeft(s, ' '));
                              /Resources.Last.FStatusCode:=StrToIntDef(su, 0);
                            end
                          else
                            if PropNodeChild.NodeName='d:prop' then
                              begin
                                PropertyNode:=PropNodeChild.ChildNodes.First;
                                while Assigned(PropertyNode) do
                                  begin
                                    if PropertyNode.NodeName='d:creationdate' then
                                      Resources.Last.FCreationDate:=UTCToSystemTime(ISODateTime2UTC(PropertyNode.Text))
                                    else
                                      if PropertyNode.NodeName='d:displayname' then
                                        Resources.Last.FDisplayName:=Utf8ToAnsi(PropertyNode.Text)
                                      else
                                        if PropertyNode.NodeName='d:getcontentlength' then
                                          Resources.Last.FContentLength:=PropertyNode.NodeValue
                                        else
                                          if PropertyNode.NodeName='d:getlastmodified' then
                                            Resources.Last.FLastmodified:=DecodeRfcDateTime(PropertyNode.Text)
                                          else
                                            if PropertyNode.NodeName='d:resourcetype' then
                                              Resources.Last.FCollection:=PropertyNode.ChildNodes.Count&gt;0;
                                    PropertyNode:=PropertyNode.NextSibling;
                                  end;
                              end;
                          PropNodeChild:=PropNodeChild.NextSibling;
                        end;
                    end;
                ChildNode:=ChildNode.NextSibling;
              end;
            ResponseNode:=ResponseNode.NextSibling;
          end;
      end;
  finally
    XMLDoc:=nil;
  end;
end;

var Str: string;
  I: Integer;
begin
  WebDAV.Login := Edit1.Text;
  WebDAV.Password := Edit2.Text;
  Resources.Clear;
  Str:=WebDAV.PROPFIND(1, InputBox('Ресурс', 'Ресурс', ''));
  if Length(Trim(Str))&gt;0 then
    begin
      ParseResources(Str);
      for I := 0 to Resources.Count-1 do
        begin
          with ListView1.Items.Add do
            begin
              Caption:=Resources[i].DisplayName;
              SubItems.Add(Resources[i].Href);
              SubItems.Add(DateTimeToStr(Resources[i].CreationDate));
              SubItems.Add(DateTimeToStr(Resources[i].Lastmodified));
              SubItems.Add(IntToStr(Resources[i].ContentLength));
              if Resources[i].Collection then
                SubItems.Add('yes')
              else
                SubItems.Add('no');
              SubItems.Add(IntToStr(Resources[i].StatusCode))
            end;
        end;

    end;
end;
}


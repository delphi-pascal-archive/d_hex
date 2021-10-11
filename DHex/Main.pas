unit Main;

interface

{ Use XP Style     } {$DEFINE XPStyle}
{ Use OvTEdit unit } {$DEFINE TEditOverride}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Menus,
  ClipBrd,
  {$IFDEF TEditOverride} OvTEdit, {$ENDIF}
  MnTools;

type
  TFrmMain = class(TForm)

    PpmList     : TPopupMenu;
    PpmInterval : TMenuItem;
    PpmItvStart : TMenuItem;
    PpmItvEnd   : TMenuItem;
    PpmCopychar : TMenuItem;
    PpmCpyDec   : TMenuItem;
    PpmCpyHex   : TMenuItem;
    PpmCpyChr   : TMenuItem;
    PpmCpyBin   : TMenuItem;

    PnlLst      : TPanel;
    HdLstCtrl   : THeaderControl;
    LstBx       : TListBox;

    PnlCfg      : TPanel;
    EdtFrom     : TEdit;
    Label2      : TLabel;
    EdtTo       : TEdit;
    BtnSet      : TButton;
    BtnAll      : TButton;
    Label1: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure BtnSetClick(Sender: TObject);
    procedure DoEdtIntervalChange(Sender : TObject);
    procedure LstBxDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure PpmListPopup(Sender: TObject);
    procedure PpmItvStartClick(Sender: TObject);
    procedure PpmItvEndClick(Sender: TObject);
    procedure PpmCpyDecClick(Sender: TObject);
    procedure PpmCpyHexClick(Sender: TObject);
    procedure PpmCpyBinClick(Sender: TObject);
    procedure PpmCpyChrClick(Sender: TObject);
    procedure BtnAllClick(Sender: TObject);
  private
    fHCPD    : integer;
    fHCPH    : integer;
    fHCPB    : integer;
    fHCPSC   : integer;
    fHCPLC   : integer;
  public
    procedure GenerateTable(const IMin,IMax : byte);
    function GetCharSelection : integer;
  end;

var
  FrmMain: TFrmMain;

{$IFDEF XPStyle}
  {$R WindowsXP.res}
{$ENDIF}

implementation

{$R *.dfm}

{ TFrmMain }

{ FormCreate }
procedure TFrmMain.FormCreate(Sender: TObject);
var FileVersion : TFileVersion;
begin
  { Definition du titre de la fiche }
  if GetFileVersion(ParamStr(0), FileVersion) then
     Caption := 'DHex '+FileVersionToStr(FileVersion)
  else
     Caption := 'DHex';

  { Definition des offsets de text pour LstBx.OnDrawItem }
  with HdLstCtrl do
  begin
    fHCPD  := 2;
    fHCPH  := Sections[0].Width + fHCPD;
    fHCPB  := Sections[1].Width + fHCPH;
    fHCPSC := Sections[2].Width + fHCPB;
    fHCPLC := Sections[3].Width + fHCPSC;
  end;

  { Empeche le scintillement de la liste }
  LstBx.DoubleBuffered := true;

  { Definition des propriétés des TEdit grace a l'unité OvTEdit }
  {$IFDEF TEditOverride}
  EdtFrom.TextAlignment := taRightJustify;
  EdtFrom.TextFormat    := tfInteger;

  EdtTo.TextAlignment   := taRightJustify;
  EdtTo.TextFormat      := tfInteger;
  {$ENDIF}

  { Genere une table par defaut 0..255 (tout) }
  GenerateTable(0,255);
end;


{ GenerateTable

  Genere une table en partant de IMin jusqu'a IMax.
}
procedure TFrmMain.GenerateTable(const IMin,IMax : byte);
var N : byte;
begin
  with LstBx.Items do
  begin
    BeginUpdate;
    Clear;
    for N := IMin to IMax do
        Add(IntToStr(N));
    EndUpdate;
  end;
end;


{ GetCharSelection

  Renvois la valeur de l'item selectionné dans la liste
}
function TFrmMain.GetCharSelection : integer;
begin
  result := -1;
  with LstBx do
    if (Count <> 0) and (ItemIndex <> -1) then
       result := StrToIntDef(Items[ItemIndex],-1);
end;


{ [EdtFrom|EdtTo].OnChange

  Gestion evenement OnChange de EdtFrom et EdtTo, verification des valeurs
  saisie et correction si besoin.
}
procedure TFrmMain.DoEdtIntervalChange(Sender : TObject);
begin
  with (Sender as TEdit) do
  begin
    if Length(Text) = 0 then
       exit;
    {$IFDEF TEditOverride}
    if ValueInt < 0 then
       ValueInt := 0
    else
    if ValueInt > 255 then
       ValueInt := 255;
    {$ELSE}
    if StrToInt(Text) < 0 then
       Text := '0'
    else
    if StrToInt(Text) > 255 then
       Text := '255';
    {$ENDIF}
  end;
end;


{ BtnSet.OnClick

  Gestion evenement OnClick de BtnSet, prepare et appel la generation de Table.
}
procedure TFrmMain.BtnSetClick(Sender: TObject);
var IMN,IMX : integer;
begin
  {$IFDEF TEditOverride}
  IMN := EdtFrom.ValueInt;
  IMX := EdtTo.ValueInt;
  {$ELSE}
  IMN := StrToInt(EdtFrom.Text);
  IMX := StrToInt(EdtTo.Text);
  {$ENDIF}
  GenerateTable(IMN,IMX);
end;


{ BtnAll.OnClick

  Gestion evenement OnClick de BtnAll, remet les parametres par defaut et
  appel la generation de Table.
}
procedure TFrmMain.BtnAllClick(Sender: TObject);
begin
  EdtFrom.Text := '0';
  EdtTo.Text   := '255';
  GenerateTable(0,255);
end;


{ LstBx.OnDrawItem

  Gestion evenement OnDrawItem de LstBx, mets en forme la liste.
}
procedure TFrmMain.LstBxDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
var S,SD,SH,SB,SSC,SLC : string;
    N : integer;
begin
  { Recupere la valeur texte de l'item en cours }
  S := LstBx.Items[index];
  { Recupere la valeur entiere de l'item en cours }
  N := StrTointDef(S,0);

  { Preparation des informations affichées dans la liste }
  SD  := ByteDecStr(N);
  SH  := ByteHexStr(N);
  SB  := ByteBinStr(N);
  SSC := SpCharAscii(N);
  SLC := SpCharAscii(N,True);

  with LstBx.Canvas do
  begin
    { Change la couleur de fond selon l'appartenance du caractere a un groupe
      specifique }
    case N of
      { caracteres speciaux }
      0..32,127 : Brush.Color := $E0E0FF;

      { caracteres normaux (symboles) }
      33..47,
      58..64,
      91..96,
      123..126  : Brush.Color := $E0FFE0;

      { caracteres normaux (chiffres, lettres) }
      48..57,
      65..90,
      97..122   : Brush.Color := $FFE0E0;
      else
        { tout les autres caracteres (caracteres etendus) }
        Brush.Color := $E0F0FF;
    end;

    if OdSelected in State then
    begin
       { si l'item est selectionné }
       Font.Color  := Brush.Color;
       Font.Style  := Font.Style + [fsBold];
       Brush.Color := InvColor(Brush.Color);
    end else
    begin
       { sinon }
       Font.Color  := InvColor(Brush.Color);
       Font.Style  := Font.Style - [fsBold];
    end;
    { efface la zone de l'item }
    FillRect(Rect);

    { dessine les infos }
    TextOut(Rect.Left+fHCPD, Rect.Top, SD);
    TextOut(Rect.Left+fHCPH, Rect.Top, SH);
    TextOut(Rect.Left+fHCPB, Rect.Top, SB);
    TextOut(Rect.Left+fHCPSC, Rect.Top, SSC);
    TextOut(Rect.Left+fHCPLC, Rect.Top, SLC);
  end;
end;


{ PpmList.OnPopup

  Gestion evenement OnPopup de PpmList, active/desactive les menus selon
  l'etat de la selection dans la liste.
}
procedure TFrmMain.PpmListPopup(Sender: TObject);
begin
  PpmInterval.Enabled := GetCharSelection <> -1;
  PpmCopyChar.Enabled := GetCharSelection <> -1;
  PpmCpyChr.Enabled   := GetCharSelection > 31;
end;


{ PpmList.PpmInterval.PpmItvStart.OnClick

  Gestion evenement OnClick de PpmItvStart, definition de l'index de depart
  pour la generation de Table.
}
procedure TFrmMain.PpmItvStartClick(Sender: TObject);
begin
  {$IFDEF TEditOverride}
  EdtFrom.ValueInt := GetCharSelection;
  {$ELSE}
  EdtFrom.Text     := IntToStr( GetCharSelection );
  {$ENDIF}
  BtnSetClick(nil);
end;


{ PpmList.PpmInterval.PpmItvEnd.OnClick

  Gestion evenement OnClick de PpmItvEnd, definition de l'index de fin
  pour la generation de Table.
}
procedure TFrmMain.PpmItvEndClick(Sender: TObject);
begin
  {$IFDEF TEditOverride}
  EdtTo.ValueInt := GetCharSelection;
  {$ELSE}
  EdtTo.Text     := IntToStr( GetCharSelection );
  {$ENDIF}
  BtnSetClick(nil);
end;


{ PpmList.PpmCopyChar.PpmCpyDec.OnClick

  Gestion evenement OnClick de PpmCpyDec, envois dans le presse papier la
  representation decimale du caractere selectionné.
}
procedure TFrmMain.PpmCpyDecClick(Sender: TObject);
var S : string;
begin
  S := ByteDecStr(GetCharSelection);
  Clipboard.SetTextBuf(PChar(S));
end;


{ PpmList.PpmCopyChar.PpmCpyHex.OnClick

  Gestion evenement OnClick de PpmCpyHex, envois dans le presse papier la
  representation hexadecimale du caractere selectionné.
}
procedure TFrmMain.PpmCpyHexClick(Sender: TObject);
var S : string;
begin
  S := ByteHexStr(GetCharSelection);
  Clipboard.SetTextBuf(PChar(S));
end;


{ PpmList.PpmCopyChar.PpmCpyBin.OnClick

  Gestion evenement OnClick de PpmCpyBin, envois dans le presse papier la
  representation binaire du caractere selectionné.
}
procedure TFrmMain.PpmCpyBinClick(Sender: TObject);
var S : string;
begin
  S := ByteBinStr(GetCharSelection);
  Clipboard.SetTextBuf(PChar(S));
end;


{ PpmList.PpmCopyChar.PpmCpyChr.OnClick

  Gestion evenement OnClick de PpmCpyChr, envois dans le presse papier le
  caractere selectionné.
}
procedure TFrmMain.PpmCpyChrClick(Sender: TObject);
var S : string;
begin
  S := chr(byte(GetCharSelection));
  Clipboard.SetTextBuf(PChar(S));
end;



end.

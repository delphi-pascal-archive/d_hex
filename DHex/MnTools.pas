unit MnTools;

interface

uses windows, sysutils;

{ SpCharAscii

  Renvois le caractere ou la definition d'un caractere de la table Ascii.

  Params :
    CharCode    [I] byte, code du caractere 0..255
    UseLongName [I] boolean (Default False), utilise les noms long ou cours
                    pour les caracteres speciaux.
  Return :
    String, renvois le caractere correspondant a CharCode ou sa representation
    courte/longue.
}
function SpCharAscii(const CharCode : byte; const UseLongName : boolean = false) : string;


{ ByteBinStr

  Renvois le mots binaire (8 bits) correspondant a B.

  Params :
    B [I] Byte, valeur a convertir

  Return :
    String, valeur binaire de B.
}
function ByteBinStr(const B : byte) : string;


{ ByteHexStr

  Renvois la representation Hexadecimale de B.

  Params :
    B [I] byte, valeur a convertir

  Return :
    String, valeur hexadecimale de B.
}
function ByteHexStr(const B : byte) : string;


{ ByteDecStr

  Renvois la representation decimale de B.

  Params :
    B [I] byte, valeur a convertir

  Return :
    String, valeur decimale de B.
}
function ByteDecStr(const B : byte) : string;


{ InvColor

  Renvois le negatif d'une couleur.

  Params :
    Color [I] integer, couleur 24/32 bits (AABBGGRR)

  Return :
    integer, couleur negative de Color.
}
function InvColor(const Color : integer) : integer;


Type
  TFileVersionBlock = (fvMinor = 0, fvMajor = 1, fvBuild = 2, fvRelease = 3);
  TFileVersion = array[TFileVersionBlock] of word;

{ GetFileVersion

  Recupere le numero de version d'un fichier

  params
    AFileName [I] string, nom du fichier
    vM        [O] byte, version majeure
    vN        [O] byte, version mineure
    vR        [O] byte, version release
    vB        [O] byte, version build
	
  return	
    boolean, true si l'operation reussi, false sinon, appeler GetLastError.
}
function GetFileVersion(const AFileName: string; var FileVersion : TFileVersion) : boolean;

{ FileVersionToStr

  Renvois une chaine representant le numero de version definit dans FileVersion.

  params
    FileVersion [I] TFileVersion, version du fichier recupérée grace a GetFileVersion
    LongVersion [I] boolean (true par defaut), determine si la fonction renvois
                    la version longue (Major.Minor.Release.Build) ou la version
                    courte (Major.Minor).

  return
    String, chaine contenant la representation de la version du fichier.
}
function FileVersionToStr(const FileVersion : TFileVersion; const LongVersion : boolean = true) : string;


implementation

{ SpCharAscii }
function SpCharAscii(const CharCode : byte; const UseLongName : boolean = false) : string;
const
  MAP0_32 : array[boolean,0..32] of string =
    (('NUL','SOH','STX','ETX','EOT','ENQ','ACK','BEL','BS','HT','LF','VT','FF',
      'CR','SO','SI','DLE','DC1','DC2','DC3','DC4','NAK','SYN','ETB','CAN','EM',
      'SUB','ESC','FS','GS','RS','US','SP'),
     ('Null','Start of header','Start of text','End of text',
      'End of transmission','Enquiry','Acknowledge','Bell','Backspace',
      'Horizontal Tab','Line feed','Vertical Tab','Form feed','Carriage Return',
      'Shift out','Shift in','Data link escape','Device control 1',
      'Device control 2','Device control 3','Device control 4',
      'Negative acknowledge','Synchronous idle','End of transmission block',
      'Cancel','End of medium','Substitute','Escape','File separator',
      'Group separator','Record separator','Unit separator','Space'));
  MAP127 : array[boolean] of string = ('DEL','Delete');
begin
  case CharCode of
    0..32 : result := '('+MAP0_32[UseLongName,CharCode]+')';
    127   : result := '('+MAP127[UseLongName]+')';
    else
      if not UseLongName then
         result := chr(CharCode)
      else
         result := '';
  end;
end;


{ ByteBinStr }
function ByteBinStr(const B : byte) : string;
const
  MAP : array[boolean] of char = ('0','1');
begin
  result    := '0000-0000';
  result[9] := MAP[(B and $01) = $01];
  result[8] := MAP[(B and $02) = $02];
  result[7] := MAP[(B and $04) = $04];
  result[6] := MAP[(B and $08) = $08];
  result[4] := MAP[(B and $10) = $10];
  result[3] := MAP[(B and $20) = $20];
  result[2] := MAP[(B and $40) = $40];
  result[1] := MAP[(B and $80) = $80];
end;


{ ByteHexStr }
function ByteHexStr(const B : byte) : string;
const
  MAP : array[$0..$F] of char = '0123456789ABCDEF';
begin
  result := '$00';
  result[2] := MAP[B shr 4];
  result[3] := MAP[B and $0F];
end;


{ ByteDecStr }
function ByteDecStr(const B : byte) : string;
const
  MAP : array[0..9] of char ='0123456789';
begin
  result := '#000';
  result[4] := MAP[B mod 10];
  result[3] := MAP[(B mod 100) div 10];
  result[2] := MAP[B div 100];
end;


{ InvColor }
function InvColor(const Color : integer) : integer;
type
  CBB = array[0..3] of byte;
var
  pC : ^CBB;
begin
  {$IFOPT T+}
     { Desactive l'operateur @ typé si necessaire }
     {$DEFINE OPRT_AT_TYPED}
     {$T-}
  {$ENDIF}
  result := Color;
  pC     := @Result;
  pC^[0] := not pC^[0]; { Red }
  pC^[1] := not pC^[1]; { Green }
  pC^[2] := not pC^[2]; { Blue }
  {$IFDEF OPRT_AT_TYPED}
     {$T+}
     {$UNDEF OPRT_AT_TYPED}
  {$ENDIF}
end;

{ GetFileVersion }
function GetFileVersion(const AFileName: string; var FileVersion : TFileVersion) : boolean;
var
  FileName : string;
  InfoSize,
  Wnd,
  VerSize  : DWORD;
  VerBuf   : Pointer;
  FI       : PVSFixedFileInfo;
  pMS,pLS  : ^cardinal;
begin
  {$IFOPT T+}
     { Desactive l'operateur @ typé si necessaire }
     {$DEFINE OPRT_AT_TYPED}
     {$T-}
  {$ENDIF}
  result := false;

  pMS := @FileVersion[fvMinor];
  pLS := @FileVersion[fvBuild];

  if not FileExists(AFileName) then
     Exit;

  FileName := AFileName;
  UniqueString(FileName);
  InfoSize := GetFileVersionInfoSize(PChar(FileName), Wnd);
  if InfoSize <> 0 then
  begin
    GetMem(VerBuf, InfoSize);
    try
      if GetFileVersionInfo(PChar(FileName), Wnd, InfoSize, VerBuf) then
        if VerQueryValue(VerBuf, '\', Pointer(FI), VerSize) then
        begin
           pMS^ := FI.dwFileVersionMS;
           pLS^ := FI.dwFileVersionLS;
           Result := true;
        end;
    finally
      FreeMem(VerBuf);
    end;
  end;
  {$IFDEF OPRT_AT_TYPED}
     {$T+}
     {$UNDEF OPRT_AT_TYPED}
  {$ENDIF}
end;

{ FileVersionToStr }
function FileVersionToStr(const FileVersion : TFileVersion; const LongVersion : boolean = true) : string;
begin
  if LongVersion then
     result := format('%d.%d.%d.%d',[FileVersion[fvMajor],FileVersion[fvMinor],FileVersion[fvRelease],FileVersion[fvBuild]])
  else
     result := format('%d.%d',[FileVersion[fvMajor],FileVersion[fvMinor]]);
end;

end.

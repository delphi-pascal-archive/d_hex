unit OvTEdit;

interface

uses Windows, SysUtils, Classes, Controls, Messages, StdCtrls, ComCtrls;

{ TEdit }
type
  TTextFormat = (tfText, tfInteger, tfFloat);

  TEdit = class(StdCtrls.TEdit)
  private
    fTextAlign   : TAlignment;
    fTextFormat  : TTextFormat;
    procedure SetTextAlign(val : TAlignment);
    procedure SetValueInt(val : integer);
    function GetValueInt : integer;
    procedure SetValueFloat(val : extended);
    function GetValueFloat : extended;
  protected
    procedure KeyPress(var Key: Char); override;
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property TextFormat   : TTextFormat read fTextFormat   write fTextFormat  default tfText;
    property TextAlignment: TAlignment  read fTextAlign    write SetTextAlign default taLeftJustify;
    property ValueInt     : Integer     read GetValueInt   write SetValueInt;
    property ValueFloat   : Extended    read GetValueFloat write SetValueFloat;
  end;


implementation


{ TEdit }

constructor TEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fTextAlign   := taLeftJustify;
  fTextFormat  := tfText;
end;

procedure TEdit.CreateParams(var Params: TCreateParams);
const
  Alignments : array[TAlignment] of Word = (ES_LEFT, ES_RIGHT, ES_CENTER);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or Alignments[TextAlignment];
end;

procedure TEdit.SetTextAlign(val : TAlignment);
begin
  if fTextAlign <> val then
  begin
     fTextAlign := val;
     RecreateWnd;
  end;
end;

procedure TEdit.SetValueInt(val : integer);
var T : string;
begin
  T := IntToStr(Val);
  if Text <> T then
  begin
    Text := T;
    Change;
  end;
end;

function TEdit.GetValueInt : integer;
begin
  result := StrToInt(Text);
end;

procedure TEdit.SetValueFloat(val : extended);
var T : string;
begin
  T := FloatToStr(Val);
  if Text <> T then
  begin
    Text := T;
    Change;
  end;
end;

function TEdit.GetValueFloat : extended;
begin
  result := StrToFloat(Text);
end;

procedure TEdit.KeyPress(var Key: Char);
begin
  case fTextFormat of
    tfText    : inherited KeyPress(Key);

    tfInteger : if Key in ['0'..'9',#08] then
                   inherited KeyPress(Key)
                else
                   Key := #0;

    tfFLoat   : if Key in ['0'..'9',DecimalSeparator,#08] then
                   inherited KeyPress(Key)
                else
                   Key := #0;
  end;
end;


end.
 
unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, XPMan;


type
  TForm1 = class(TForm)
    Image1: TImage;
    RadioButton1: TRadioButton;
    Image2: TImage;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    RadioButton4: TRadioButton;
    RadioButton5: TRadioButton;
    Image3: TImage;
    Image4: TImage;
    Image5: TImage;
    Image6: TImage;
    RadioButton6: TRadioButton;
    Image7: TImage;
    SpeedButton1: TSpeedButton;
    Edit1: TEdit;
    Label1: TLabel;
    XPManifest1: TXPManifest;
    Image8: TImage;
    Image9: TImage;
    procedure FormCreate(Sender: TObject);
    procedure RadioButton1Click(Sender: TObject);
    procedure RadioButton2Click(Sender: TObject);
    procedure RadioButton3Click(Sender: TObject);
    procedure RadioButton4Click(Sender: TObject);
    procedure RadioButton5Click(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure RadioButton6Click(Sender: TObject);
    procedure Image8MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Image9MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
      procedure Save;
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  t:integer;
  Mass: array [0..19,0..19] of integer;
implementation

{$R *.dfm}

procedure TForm1.Save;
var
x,y:integer;
begin
 AssignFile(output,'Map.btl');
 Rewrite(output);
 Writeln(edit1.text);
 Writeln(Image9.left div 25);
 Writeln(Image9.top div 25);
 for y:=0 to 19 do begin
  for x:=0 to 19 do begin
  if Mass[x,y]<>0 then begin
   Writeln(Mass[x,y]);
   Writeln(x);
   Writeln(y);
  end;
  end;
 end;
 if (Image8.Left>=0) and (Image8.Left<=19*25) and (Image8.top>=0) and (Image8.top<=19*25) then begin
  Writeln('6');
  Writeln(Image8.left div 25);
  Writeln(Image8.top div 25);
 end;
CloseFile(output);
end;

procedure TForm1.FormCreate(Sender: TObject);
var
x,y:integer;
begin
for y:=0 to 19 do
 for x:=0 to 19 do
 Mass[x,y]:=0;
t:=1;
end;

procedure TForm1.RadioButton1Click(Sender: TObject);
begin
t:=1;
end;

procedure TForm1.RadioButton2Click(Sender: TObject);
begin
t:=3;
end;

procedure TForm1.RadioButton3Click(Sender: TObject);
begin
t:=2;
end;

procedure TForm1.RadioButton4Click(Sender: TObject);
begin
t:=4;
end;

procedure TForm1.RadioButton5Click(Sender: TObject);
begin
t:=5;
end;


procedure TForm1.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
  var
  Img:TImage;
begin
 if shift=[ssleft] then begin
  x:=(x div 25)*25;
  y:=(y div 25)*25;
  case t of
   1: Img:=Image2;
   2: Img:=Image4;
   3: Img:=Image3;
   4: Img:=Image5;
   5: Img:=Image6;
   0: Img:=Image7;
  end;
  Mass[x div 25,y div 25]:=t;
  Image1.Canvas.Draw(x,y,Img.Picture.Graphic);
 end;
end;

procedure TForm1.RadioButton6Click(Sender: TObject);
begin
t:=0;
end;

procedure TForm1.Image8MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
if shift=[ssleft] then begin
 x:=((Image8.Left+x) div 25)*25;
 y:=((Image8.Top+y) div 25)*25;
 Image8.Left:=x;
 Image8.Top:=y;
end;
end;

procedure TForm1.Image9MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
if shift=[ssleft] then begin
 x:=((Image9.Left+x) div 25)*25;
 y:=((Image9.Top+y) div 25)*25;
 Image9.Left:=x;
 Image9.Top:=y;
end;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
Save;
end;

end.

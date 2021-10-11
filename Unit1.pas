unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Buttons, StdCtrls, XPMan, Menus, ComCtrls;

type TStr=array of string;

type TObjectData=record
 Armor:integer;             //Броня
 Speed:integer;             //Скорость перемещения - в миллисекундах (Вообще скорость равна step/speed)
 ShotSpeed:integer;         //Скорость стрельбы
 Direction:integer;         //0-4  направления движения
 Power:integer;             //Сила удара (при столкновении)
 Step:integer;              //Шаг
 Data1,Data2,Data3:integer; //какие нибудь другие данные
 ObjParent,ObjType:String;
 Pictures,Collisions:TStr;
 Transparent:boolean;
end;

type TObj=class(TImage)
Public
 ObjectData:TObjectData;
end;

type
  TForm1 = class(TForm)
    XPManifest1: TXPManifest;
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    Bonus: TTimer;
    StatusBar1: TStatusBar;
    N7: TMenuItem;

  procedure LoadNextMap;
  procedure CreateBonus(x,y:integer);
  procedure PauseGame(Stop:boolean);
  function Collision(Obj:TObj):TObj;                          //Столкновение
  function Stop(Obj1,Obj2:TObj):boolean;                      //Надо ли остановиться при столкновении
  function ObjCreate(Data:TObjectData; x,y,dir:integer):TObj; //Создание объекта
  procedure CorrectPos(Obj:TObj; Len:integer);                //Корректировака позиции
  procedure LoadMap(FileName:string);                         //Загрузка карты
  procedure CollisionObjects(Obj1,Obj2:TObj);                 //При столкновении двух объектов, происходит то-то 
  function ObjMake(FileName:string; x,y,dir:integer):TObj;    //Загрузка объекта из файла и создание его
  procedure CreateTanks(Quan:integer);                        //Создание некторого количества танков
  procedure SetDir(var Obj:TObj; Dir:integer);                //Меняем напрвление
  procedure MoveObj(Sender: TObject);                         //Движение бъекта
  procedure ShotObj(Sender: TObject);                         //Выстрел объекта
  procedure ObjDestroy(var Obj:TObj);                         //Уничтожение
  function ObjDead(var Obj:TObj):boolean;                     //Уничтожаем, если нет жизни
  function FindImg(x,y:integer):TImage;                       //Поиск Image'а
  procedure FindMaps;                                         //Поиск карт и занесение их в список
  procedure DestroyGame;                                      //Уничтожаем все Image и все Timer кроме Bonus
  procedure InitLevel(FileName:string);                       //Инициализация уровня (карта + объекты)
  procedure ReplacementObj(var Obj1:TObj;  FileName:string);  //Замена Объекта другим
  procedure ItemClick(Sender: TObject);
  function  LoadObjData(FileName:string):TObjectData;         //Загрузка данных объекта из файла
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure BonusTimer(Sender: TObject);
    procedure NextEvoTank(var Obj1:TObj);                     //Следующая "эволюция" танка
    function FindObjByName(Name:string):TObj;
    procedure ColPlayer(Obj:TObj);                            //Событие Столкновения игрока с чем-то (с бонусами) 
    procedure PlayerNextEvo;
    procedure N7Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure N3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  Num,Tanks,Score,IndexMap:integer;
  Player:TObj;
  Maps:array of string;
implementation

{$R *.dfm}
{$R Data.RES}


procedure TForm1.DestroyGame;
var
destroy:boolean;
i:integer;
begin
Num:=0; Score:=0; Tanks:=0;
Bonus.Enabled:=false;
repeat
destroy:=false;
 for i:=0 to ComponentCount-1 do begin
  if (Components[i] is Timage) or ((Components[i] is TTimer) and (TTimer(Components[i]).Name<>'Bonus')) then begin
   Components[i].Free;
   destroy:=true;
   break;
  end;
 end;
until destroy=false;
end;

Function TForm1.Stop(Obj1,Obj2:TObj):boolean;
var
i:integer;
begin
for i:=0 to High(Obj1.ObjectData.Collisions) do begin
 if Obj1.ObjectData.Collisions[i]=Obj2.ObjectData.ObjType then begin
 result:=true;
 exit;
 end;
end;
result:=false;
end;

procedure TForm1.ObjDestroy(var Obj:TObj);
begin
TTImer(FindComponent('Move'+Obj.Name)).Free;
TTimer(FindComponent('Shot'+Obj.Name)).Free;
Obj.Free;
end;

function TForm1.ObjDead(var Obj:TObj):boolean;
begin
 if Obj.ObjectData.Armor<=0 then begin
  ObjDestroy(obj);
  Result:=true;
 end else Result:=false;
end;

function RandomDir:integer;
begin
 Randomize;
 result:=Random(4)+1;
end;

procedure TForm1.SetDir(var Obj:TObj; Dir:integer);
begin
if Obj<>nil then begin
 Obj.ObjectData.Direction:=dir;
 if Obj.ObjectData.Direction=0 then Dir:=1;
 Obj.Picture.Bitmap.LoadFromResourceName(Hinstance, Obj.ObjectData.Pictures[dir-1]);
end;
end;

function TForm1.LoadObjData(FileName:string):TObjectData;
var
i,p,t,c:integer;
Data:TObjectData;
begin
 AssignFile(input,FileName);
 Reset(input);
 Readln(Data.ObjType,p,c,t);
  if t=0 then Data.Transparent:=false else Data.Transparent:=true;
 SetLength(Data.Pictures,p);
 SetLength(Data.Collisions,c);
 For i:=0 to p-1 do Readln(Data.Pictures[i]);
 For i:=0 to c-1 do Readln(Data.Collisions[i]);
Read(Data.Armor,Data.Speed,Data.ShotSpeed,Data.Power,Data.Step, Data.Data1,Data.Data2,Data.Data3);
CloseFile(input);
Result:=Data;
end;

function TForm1.ObjMake(FileName:string; x,y,dir:integer):TObj;
var
Data:TObjectData;
begin
if Length(Data.Pictures)=1 then Dir:=0;
Result:=ObjCreate(LoadObjData(FileName),x,y,dir);
end;
//--------------------------------------------
function TForm1.ObjCreate(Data:TObjectData; x,y,dir:integer):TObj;
var
Obj:TObj;
begin
Inc(Num);
 Obj:=TObj.Create(Self);
with Obj do begin
 ObjectData:=Data;
  Autosize:=true;
   Transparent:=ObjectData.Transparent;
    Left:=x;
    Top:=y;
   ObjectData.Direction:=Dir;
  Name:=ObjectData.ObjType+inttostr(Num);
Parent:=Form1;
end;
 Obj.ObjectData.Direction:=dir;
 SetDir(Obj,Dir);
if  Obj.ObjectData.Speed<>0 then
with TTimer.Create(Self) do begin
 Interval:=Obj.ObjectData.Speed;
  OnTimer:=MoveObj;
 Name:='Move'+Obj.Name;
end;
if  Obj.ObjectData.ShotSpeed<>0 then
with TTimer.Create(Self) do begin
 Interval:=Obj.ObjectData.ShotSpeed;
  OnTimer:=ShotObj;
 Name:='Shot'+Obj.Name;
end;
result:=Obj;
end;
//------------------------------------------------
procedure TForm1.ColPlayer(Obj:TObj);
var
name:string;
begin
name:=Obj.ObjectData.ObjType;
if Name='Health' then begin
 Player.ObjectData.Armor:=Player.ObjectData.Armor+1;
 ObjDestroy(Obj);
end else
if Name='Speed' then begin
 if Player.ObjectData.Step<5 then Player.ObjectData.Step:=Player.ObjectData.Step+1;
 ObjDestroy(Obj);
end else
if Name='NextEvo' then begin
 PlayerNextEvo;
 ObjDestroy(Obj);
end else
if Name='Power' then begin
 Player.ObjectData.Data1:=Player.ObjectData.Data1+1;
 ObjDestroy(Obj);
end else
if Name='BulletSpeed' then begin
 if Player.ObjectData.Data2<10 then Player.ObjectData.Data2:=Player.ObjectData.Data2+1;
 ObjDestroy(Obj);
end;
end;

procedure TForm1.PlayerNextEvo;
begin
 if Player.ObjectData.Pictures[0]='Tank21' then begin
   ObjDestroy(Player);
   Player:=ObjMake('Objects\Player_2.obj',Player.Left,Player.Top,Player.ObjectData.Direction);
 end else
 if Player.ObjectData.Pictures[0]='Tank71' then begin
   ObjDestroy(Player);
   Player:=ObjMake('Objects\Player_3.obj',Player.Left,Player.Top,Player.ObjectData.Direction);
 end;
end;

procedure TForm1.CollisionObjects(Obj1,Obj2:TObj);
var
Data:integer;
Name1,Name2,Par1:string;
ParObj1,ParObj2:TObj;
begin
 Name1:=Obj1.ObjectData.ObjType;
 Name2:=Obj2.ObjectData.ObjType;
if (Name1='Tank') and (Name2='Tank') then begin
CorrectPos(Obj1,5);
 SetDir(Obj1,RandomDir);
end else
if (Name1='Tank') and (Name2='Wall') then begin
CorrectPos(Obj1,5);
 SetDir(Obj1,RandomDir);
end else
if (Name1='Tank') and (Name2='Box') then begin
CorrectPos(Obj1,5);
 SetDir(Obj1,RandomDir);
end else
if (Name1='Tank') and (Name2='Brick') then begin
CorrectPos(Obj1,5);
 SetDir(Obj1,RandomDir);
end else
if (Name1='Tank') and (Name2='Water') then begin
CorrectPos(Obj1,5);
 SetDir(Obj1,RandomDir);
end else
if (Name1='Tank') and (Name2='Concrete') then begin
CorrectPos(Obj1,5);
 SetDir(Obj1,RandomDir);
end else
if (Name1='Tank') and (Name2='Flag') then begin
CorrectPos(Obj1,5);
 SetDir(Obj1,RandomDir);
end else
if (Name1='Tank') and (Name2='Health') then begin
 Obj1.ObjectData.Armor:=Obj1.ObjectData.Armor+1;
 ObjDestroy(Obj2);
end else
if (Name1='Tank') and (Name2='Speed') then begin
 if Obj1.ObjectData.Step<5 then Obj1.ObjectData.Step:=Obj1.ObjectData.Step+1;
 ObjDestroy(Obj2);
end else
if (Name1='Tank') and (Name2='NextEvo') then begin
 NextEvoTank(Obj1);
 ObjDestroy(Obj2);
end else
if (Name1='Tank') and (Name2='Power') then begin
 Obj1.ObjectData.Data1:=Obj1.ObjectData.Data1+1;
 ObjDestroy(Obj2);
end else
if (Name1='Tank') and (Name2='BulletSpeed') then begin
 if Obj1.ObjectData.Data2<10 then Obj1.ObjectData.Data2:=Obj1.ObjectData.Data2+1;
 ObjDestroy(Obj2);
end else
if (Name1='Bullet') and (Name2='Wall') then begin
 Obj2.ObjectData.Armor:=Obj2.ObjectData.Armor-Obj1.ObjectData.Power;
 ObjDestroy(Obj1);
 ObjDead(Obj2);
end else
if (Name1='Bullet') and (Name2='Bullet') then begin
ObjDestroy(Obj1);
ObjDestroy(Obj2);
end else
if (Name1='Bullet') and (Name2='Tank') then begin
 Obj2.ObjectData.Armor:=Obj2.ObjectData.Armor-Obj1.ObjectData.Power;
 Data:=Obj2.ObjectData.Data3;
 Par1:=Obj1.ObjectData.ObjParent;
 ObjDestroy(Obj1);
 if ObjDead(Obj2)=true then begin
  if Par1=Player.Name then begin
   Score:=Score+Data;
   Statusbar1.Panels[1].Text:='Очки: '+inttostr(Score);
  end;
  if Tanks>5 then CreateTanks(1);
   Tanks:=Tanks-1;
   Statusbar1.Panels[0].Text:='Осталость танков: '+IntToStr(Tanks);
  end;
  if Tanks=0 then begin
   showmessage('Вы выиграли.');
   LoadNextMap;
  end;
end else
if (Name1='Bullet') and (Name2='Box') then begin
 Obj2.ObjectData.Armor:=Obj2.ObjectData.Armor-Obj1.ObjectData.Power;
 ObjDestroy(Obj1);
 ObjDead(Obj2);
end else
if (Name1='Bullet') and (Name2='Brick') then begin
 Obj2.ObjectData.Armor:=Obj2.ObjectData.Armor-Obj1.ObjectData.Power;
 ObjDestroy(Obj1);
 ObjDead(Obj2);
end else
if (Name1='Bullet') and (Name2='Concrete') then begin
 Obj2.ObjectData.Armor:=Obj2.ObjectData.Armor-Obj1.ObjectData.Power;
 ObjDestroy(Obj1);
 ObjDead(Obj2);
end else
if (Name1='Bullet') and (Name2='Flag') then begin
 Obj2.ObjectData.Armor:=Obj2.ObjectData.Armor-Obj1.ObjectData.Power;
 ObjDestroy(Obj1);
 if ObjDead(Obj2)=true then showmessage('Вы проиграли.');
end else
end;

procedure TForm1.MoveObj(Sender: TObject);
var
Obj,ColObj:TObj;
begin
Obj:=TObj(FindComponent(Copy((sender as TTimer).Name,5,length((sender as TTimer).Name)-4)));
if Obj<>Nil then begin
 case Obj.ObjectData.Direction of
  1: Obj.Top :=Obj.Top-Obj.ObjectData.Step;
  2: Obj.Top :=Obj.Top+Obj.ObjectData.Step;
  3: Obj.Left:=Obj.Left-Obj.ObjectData.Step;
  4: Obj.Left:=Obj.Left+Obj.ObjectData.Step;
 end;
ColObj:=Collision(Obj);
if (ColObj<>nil) and (Obj<>nil) then CollisionObjects(Obj,ColObj);
end;
end;

procedure TForm1.ShotObj(Sender: TObject);
var
ParObj,Obj:TObj;
dx,dy:integer;
begin
ParObj:=TObj(FindComponent(Copy((sender as TTimer).Name,5,length((sender as TTimer).Name)-4)));
if ParObj<>nil then begin
  if ParObj.ObjectData.Direction=4 then Obj:=ObjMake('Objects\Bullet.obj',ParObj.Left+ParObj.Width+5,ParObj.Top+(ParObj.Height div 2),4);
  if ParObj.ObjectData.Direction=3 then Obj:=ObjMake('Objects\Bullet.obj',ParObj.Left-5,ParObj.Top+(ParObj.Height div 2),3);
  if ParObj.ObjectData.Direction=1 then Obj:=ObjMake('Objects\Bullet.obj',ParObj.Left+(ParObj.Width div 2),ParObj.Top-5,1);
  if ParObj.ObjectData.Direction=2 then Obj:=ObjMake('Objects\Bullet.obj',ParObj.Left+(ParObj.Width div 2),ParObj.Top+ParObj.Height+5,2);
   Obj.ObjectData.ObjParent:=ParObj.Name;
   Obj.ObjectData.Power    :=ParObj.ObjectData.Data1;
   Obj.ObjectData.Step     :=ParObj.ObjectData.Data2;
end;
end;

function TForm1.Collision(Obj:TObj):TObj;
var
i:integer;
begin
for i:=0 to ComponentCount-1 do begin
if (Components[i] is TObj) and (TObj(Components[i]).Name<>Obj.Name) then begin
if (Obj.Left+Obj.Width>=TObj(Components[i]).Left)                 and
   (Obj.Left<TObj(Components[i]).Left+TObj(Components[i]).Width) and
   (Obj.Top+Obj.Height>TObj(Components[i]).Top)                  and
   (Obj.Top<TObj(Components[i]).Top+TObj(Components[i]).Height)  and
   (Obj.ObjectData.Direction=4)                                  then begin
if Stop(Obj,TObj(Components[i]))=true then Obj.Left:=TObj(Components[i]).Left-Obj.Width;
result:=TObj(Components[i]);
exit;
end;
if (Obj.Left<TObj(Components[i]).Left+TObj(Components[i]).Width) and
   (Obj.Left+Obj.Width>TObj(Components[i]).Left)                 and
   (Obj.Top+Obj.Height>TObj(Components[i]).Top)                  and
   (Obj.Top<TObj(Components[i]).Top+TObj(Components[i]).Height)  and
   (Obj.ObjectData.Direction=3)                                  then begin
if Stop(Obj,TObj(Components[i]))=true then Obj.Left:=TObj(Components[i]).Left+TObj(Components[i]).Width;
result:=TObj(Components[i]);
exit;
end;
if (Obj.top+Obj.Height>TObj(Components[i]).Top)                  and
   (Obj.top<TObj(Components[i]).top+TObj(Components[i]).Height)  and
   (Obj.left+Obj.Width>TObj(Components[i]).left)                 and
   (Obj.left<TObj(Components[i]).Left+TObj(Components[i]).Width) and
   (Obj.ObjectData.Direction=2)                                  then begin
if Stop(Obj,TObj(Components[i]))=true then Obj.Top:=TObj(Components[i]).top-Obj.Height;
result:=TObj(Components[i]);
exit;
end;
if (Obj.top<TObj(Components[i]).top+TObj(Components[i]).Height)  and
   (Obj.top+Obj.Height>TObj(Components[i]).top)                  and
   (Obj.left+Obj.Width>TObj(Components[i]).left)                 and
   (Obj.left<TObj(Components[i]).left+TObj(Components[i]).Width) and
   (Obj.ObjectData.Direction=1)                                  then begin
if Stop(Obj,TObj(Components[i]))=true then Obj.top:=TObj(Components[i]).top+TObj(Components[i]).Height;
result:=TObj(Components[i]);
exit;
end;
end;
end;
result:=Nil;
end;

procedure TForm1.LoadMap(FileName:string);
var
x,y,t,i,px,py:integer;
f:string;
List:TStringList;
begin
List:=TStringList.Create;
List.LoadFromFile(FileName);
 Tanks:=StrToInt(List.Strings[0]);
 px:=StrToInt(List.Strings[1]);
 py:=StrToInt(List.Strings[2]);
for i:=3 to (List.Count-1) do begin
if i mod 3 =0 then begin
 t:=strtoint(Trim(list.Strings[i]));
 x:=strtoint(Trim(list.Strings[i+1]));
 y:=strtoint(Trim(list.Strings[i+2]));
  if t=1 then f:='Wall'     else
  if t=2 then f:='Box'      else
  if t=3 then f:='Brick'    else
  if t=4 then f:='Water'    else
  if t=5 then f:='Concrete' else
  if t=6 then f:='Flag';
   ObjMake('Objects\'+f+'.obj',x*25,y*25,0);
 application.ProcessMessages;
end;
end;
Player:=ObjMake('Objects\Player.obj',px*25,py*25,RandomDir);
List.Free;
end;


procedure TForm1.CorrectPos(Obj:TObj; Len:integer);
var
r1,r2,r3,r4:integer;
begin
if Obj<>nil then begin
 r1:=(Obj.top div 25)*25-Obj.top;
 r2:=((Obj.top+Obj.Height) div 25)*25+25-(Obj.top+Obj.Height);
 r3:=(Obj.left div 25)*25-Obj.left;
 r4:=((Obj.left+Obj.Width) div 25)*25+25-(Obj.left+Obj.Width);
 case Obj.ObjectData.direction of
  1: if Abs(r1)<=Len then Obj.top:=Obj.Top+r1;
  2: if Abs(r2)<=Len then Obj.top:=Obj.Top+r2;
  3: if Abs(r3)<=Len then Obj.left:=Obj.left+r3;
  4: if Abs(r4)<=Len then Obj.left:=Obj.left+r4;
 end;
end;
end;

function TForm1.FindImg(x,y:integer):TImage;
var
i:integer;
begin
 For i:=0 to ComponentCount-1 do begin
  if (Components[i] is Timage) and (Timage(Components[i]).Top=y) and (Timage(Components[i]).left=x) then begin
    Result:=Timage(Components[i]);
    exit;
  end;
 end;
 Result:=nil;
end;
//-**************************************************
procedure TForm1.CreateTanks(Quan:integer);
var
r,x,y:integer;
name:string;
begin
Randomize;
while Quan>0 do begin
 x:=random(18)+1;
 y:=1;
if FindImg(x*25,y*25)=nil then begin
Quan:=Quan-1;
 r:=random(5);
 case r of
  0: name:='RedTank';
  1: name:='BlackTank';
  2: name:='GreenTank';
  3: name:='BlueTank';
  4: name:='YellowTank';
 end;
ObjMake('Objects\'+Name+'.obj',x*25,y*25,RandomDir);
application.ProcessMessages;
end;
end;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
ColObj,Bullet:TObj;
begin
if Player<>nil then begin
if key=vk_left then begin
 SetDir(Player,3);
 Player.Left:=Player.Left-Player.ObjectData.Step;
end else
if key=vk_right then begin
 SetDir(Player,4);
 Player.Left:=Player.Left+Player.ObjectData.Step;
end else
if key=vk_up then begin
 SetDir(Player,1);
 Player.top:=Player.top-Player.ObjectData.Step;
end else
if key=vk_down then begin
 SetDir(Player,2);
 Player.top:=Player.top+Player.ObjectData.Step;
end else
if key=vk_space then begin
 case Player.ObjectData.Direction of
  4: Bullet:=ObjMake('Objects\Bullet.obj',Player.Left+Player.Width+5,Player.Top+(Player.Height div 2),4);
  3: Bullet:=ObjMake('Objects\Bullet.obj',Player.Left-5,Player.Top+(Player.Height div 2),3);
  1: Bullet:=ObjMake('Objects\Bullet.obj',Player.Left+(Player.Width div 2),Player.Top-5,1);
  2: Bullet:=ObjMake('Objects\Bullet.obj',Player.Left+(Player.Width div 2),Player.Top+Player.Height+5,2);
 end;
  Bullet.ObjectData.ObjParent:=Player.Name;
  Bullet.ObjectData.Power    :=Player.ObjectData.Data1;
  Bullet.ObjectData.Step     :=Player.ObjectData.Data2;
end;
ColObj:=Collision(Player);
if (ColObj<>Nil) and (Player<>nil) then ColPlayer(ColObj);
end;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if Player<>nil then CorrectPos(Player,10);
end;

procedure TForm1.FindMaps;
var
DirInfo: TSearchRec;
r : Integer;
item:TMenuItem;
begin
MainMenu1.Items.Items[0].Items[0].Clear;
SetLength(Maps,0);
r := FindFirst('Maps\*.btl', FaAnyfile, DirInfo);
while r = 0 do begin
if ((DirInfo.Attr and FaDirectory<>FaDirectory) and (DirInfo.Attr and FaVolumeId<>FaVolumeID)) then
  item:=Tmenuitem.Create(self);
  item.OnClick:=ItemClick;
  item.Caption:=DirInfo.Name;
  MainMenu1.Items.Items[0].Items[0].Add(item);
   SetLength(Maps,Length(Maps)+1);
   Maps[High(Maps)]:=DirInfo.Name;
 r := FindNext(DirInfo);
end;
SysUtils.FindClose(DirInfo);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
FindMaps;
end;

procedure TForm1.InitLevel(FileName:string);
begin
 DestroyGame;
 LoadMap(FileName);
 CreateTanks(5);
 StatusBar1.Panels[0].Text:='Осталось танков: '+IntToStr(Tanks);
end;


procedure TForm1.ItemClick(Sender: TObject);
begin
IndexMap:=MainMenu1.Items.items[0].items[0].IndexOf((Sender as TMenuItem));
InitLevel('Maps\'+Maps[IndexMap]);
Bonus.Enabled:=true;
end;

procedure TForm1.LoadNextMap;
begin
 if IndexMap<MainMenu1.Items.items[0].items[0].Count-1 then begin
  IndexMap:=IndexMap+1;
  InitLevel('Maps\'+Maps[IndexMap]);
  Bonus.Enabled:=true;
 end;
end;

procedure TForm1.ReplacementObj(var Obj1:TObj; FileName:string);
var
x,y,dir:integer;
begin
 x  :=Obj1.Left;
 y  :=Obj1.Top;
 dir:=Obj1.ObjectData.Direction;
ObjDestroy(Obj1);
ObjMake(FileName,x,y,dir);
end;

procedure TForm1.NextEvoTank(var Obj1:TObj);
var
FileName:string;
begin
if Obj1.ObjectData.Pictures[0]='Tank11' then begin
 ReplacementObj(Obj1,'Objects\RedTank_2.obj');
end else
if Obj1.ObjectData.Pictures[0]='Tank21' then begin
 ReplacementObj(Obj1,'Objects\GreenTank_2.obj');
end else
if Obj1.ObjectData.Pictures[0]='Tank31' then begin
 ReplacementObj(Obj1,'Objects\BlueTank_2.obj');
end else
if Obj1.ObjectData.Pictures[0]='Tank41' then begin
 ReplacementObj(Obj1,'Objects\YellowTank_2.obj');
end else
if Obj1.ObjectData.Pictures[0]='Tank51' then begin
 ReplacementObj(Obj1,'Objects\blackTank_2.obj');
end else
if Obj1.ObjectData.Pictures[0]='Tank101' then begin
 ReplacementObj(Obj1,'Objects\blackTank_3.obj');
end else
if Obj1.ObjectData.Pictures[0]='Tank61' then begin
 ReplacementObj(Obj1,'Objects\RedTank_3.obj');
end else
if Obj1.ObjectData.Pictures[0]='Tank71' then begin
 ReplacementObj(Obj1,'Objects\GreenTank_3.obj');
end else
if Obj1.ObjectData.Pictures[0]='Tank81' then begin
 ReplacementObj(Obj1,'Objects\BlueTank_3.obj');
end else
if Obj1.ObjectData.Pictures[0]='Tank91' then begin
 ReplacementObj(Obj1,'Objects\YellowTank_3.obj');
end;
end;

procedure TForm1.BonusTimer(Sender: TObject);
begin
CreateBonus((random(18)+1)*25,(random(18)+1)*25);
end;

procedure TForm1.CreateBonus(x,y:integer);
var
r:integer;
begin
Randomize;
r:=Random(5);
 case r of
  0: ObJMake('Objects\Speed.obj'      ,x,y,0);
  1: ObJMake('Objects\Health.obj'     ,x,y,0);
  2: ObJMake('Objects\NextEvo.obj'    ,x,y,0);
  3: ObJMake('Objects\Power.obj'      ,x,y,0);
  4: ObJMake('Objects\BulletSpeed.obj',x,y,0);
 end;
end;

function TForm1.FindObjByName(Name:string):TObj;
var
i:integer;
begin
 for i:=0 to ComponentCount-1 do begin
  if (Components[i] is TObj) and (TObj(Components[i]).Name=Name) then begin
   Result:=TObj(Components[i]);
   exit;
  end;
 end;
Result:=Nil;
end;

procedure TForm1.PauseGame(Stop:boolean);
var
i:integer;
begin
 for i:=0 to ComponentCount-1 do begin
  if Components[i] is TTimer then begin
   if stop=true then TTimer(Components[i]).Enabled:=false else TTimer(Components[i]).Enabled:=true;
  end;
 end;
end;

procedure TForm1.N7Click(Sender: TObject);
begin
PauseGame(true);
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
application.ProcessMessages;
end;

procedure TForm1.N3Click(Sender: TObject);
begin
Form1.Close;
end;

end.

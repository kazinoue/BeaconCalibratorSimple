unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Beacon,
  System.Bluetooth, FMX.Layouts, FMX.ListBox, System.Beacon.Components,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Edit, System.Math,
  FMXTee.Engine, FMXTee.Series, FMXTee.Procs, FMXTee.Chart, FMX.StdCtrls,
  FMXTee.Chart.Functions, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent, System.NetEncoding,
  System.Bluetooth.Components, FMX.Objects, FMX.TabControl, FMX.Gestures;
type
  TForm1 = class(TForm)
    Beacon1: TBeacon;
    ListBox1: TListBox;
    Memo1: TMemo;
    EditAverage: TEdit;
    EditCount: TEdit;
    LabelRSSIAverage: TLabel;
    UUID: TEdit;
    Layout2: TLayout;
    SwitchMonitoring: TSwitch;
    Label7: TLabel;
    LabelUUID: TLabel;
    Layout4: TLayout;
    Layout5: TLayout;
    LabelRSSI: TLabel;
    EditRSSI: TEdit;
    Label11: TLabel;
    SwitchFindBeacon: TSwitch;
    BluetoothLE1: TBluetoothLE;
    Panel1: TPanel;
    Text1: TText;
    TabControl1: TTabControl;
    TabItem4Log: TTabItem;
    TabItem2Values: TTabItem;
    TabItem1FindBeacon: TTabItem;
    LabelCount: TLabel;
    Label1: TLabel;
    EditTxPowerCalibrated: TEdit;
    procedure Beacon1BeaconEnter(const Sender: TObject; const ABeacon: IBeacon;
      const CurrentBeaconList: TBeaconList);
    procedure ListBox1ItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure FormCreate(Sender: TObject);
    procedure SwitchFindBeaconSwitch(Sender: TObject);
    procedure Beacon1CalculateDistances(const Sender: TObject;
      const ABeacon: IBeacon; ATxPower, ARssi: Integer;
      var NewDistance: Double);
//    procedure Button1Click(Sender: TObject);
    procedure SwitchMonitoringSwitch(Sender: TObject);
    procedure Beacon1BeaconExit(const Sender: TObject; const ABeacon: IBeacon;
      const CurrentBeaconList: TBeaconList);
    procedure Beacon1BeaconProximity(const Sender: TObject;
      const ABeacon: IBeacon; Proximity: TBeaconProximity);
    procedure AddMemoLog(AString: String);
    procedure Beacon1CalcDistance(const Sender: TObject; const UUID: TGUID;
      AMajor, AMinor: Word; ATxPower, ARssi: Integer; var NewDistance: Double);
  private
    { private 宣言 }
    SelectedBeaconUUID: String;
    SelectedBeaconMajor: Integer;
    SelectedBeaconMinor: Integer;

    ListRSSI: array of Single;
    ListDistance: array of Double;
    procedure TxPowerCallibration();
  public
    { public 宣言 }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.Beacon1BeaconEnter(const Sender: TObject;
  const ABeacon: IBeacon; const CurrentBeaconList: TBeaconList);
{ Beaconを検出した時の処理 }
var
  BeaconMajorMinorSSID: String;
begin
  // Beacon を検出したら ListBox に追記する。
  BeaconMajorMinorSSID := Format( '%d:%d:%s', [ ABeacon.Major, ABeacon.Minor, ABeacon.GUID.toString ] );
  with ListBox1.Items do
    if IndexOf(BeaconMajorMinorSSID) < 0 then
      ListBox1.Items.Insert(0,BeaconMajorMinorSSID);
end;

procedure TForm1.Beacon1BeaconExit(const Sender: TObject;
  const ABeacon: IBeacon; const CurrentBeaconList: TBeaconList);
{ Beacon が検出できなくなったときの処理? }
var
  BeaconMajorMinorSSID: String;
begin
  // Beacon の情報を Listbox から消す
  BeaconMajorMinorSSID := Format( '%d:%d:%s', [ ABeacon.Major, ABeacon.Minor, ABeacon.GUID.toString ] );
  with ListBox1.Items do
    if IndexOf(BeaconMajorMinorSSID) < 0 then
      ListBox1.Items.Delete(IndexOf(BeaconMajorMinorSSID));
end;

procedure TForm1.Beacon1BeaconProximity(const Sender: TObject;
  const ABeacon: IBeacon; Proximity: TBeaconProximity);
begin
  AddMemoLog(ABeacon.GUID.ToString);
end;

procedure TForm1.Beacon1CalcDistance(const Sender: TObject; const UUID: TGUID;
  AMajor, AMinor: Word; ATxPower, ARssi: Integer; var NewDistance: Double);
{ Beacon の距離計算処理のオーバーライド処理 }
var
  numofListRSSI: integer;
  numofListDistance: integer;

  RssiAvg: Double;
  RssiStdDev: Double;

begin
  NewDistance := BluetoothLE1.RssiToDistance(
      ARssi,
      ATxPower,
      0.5
  );

  // 監視対象のビーコンの場合だけ、距離計算を実施する
  if ( SwitchMonitoring.isChecked = True ) AND
     ( SelectedBeaconUUID  = UUID.toString ) AND
     ( SelectedBeaconMajor = AMajor ) AND
     ( SelectedBeaconMinor = AMinor ) then
  begin
    // RSSI の値を保持しているリストに新しい計測値を追記する
    numofListRSSI := Length(ListRSSI);
    setLength(ListRSSI,numofListRSSI+1);
    ListRSSI[numofListRSSI] := ARssi;
    inc(numofListRSSI);

    // 距離の計算結果のリストもアップデートする
    numofListDistance := Length(ListRSSI);
    setLength(ListDistance,numofListDistance+1);

    // RSSI を ログ用の TMemo に出力する。
    AddMemoLog( Format( '%d dBm', [ ARssi ] ) );

    EditRSSi.Text := Format( '%d', [ ARssi ] );

    // 平均値と標準偏差を計算する
    EditCount.text := IntToStr(numofListRSSI);
    if ( numofListRSSI > 3 ) then
    begin

      RssiAvg    := System.Math.Mean  ( ListRSSI );
      RssiStdDev := System.Math.StdDev( ListRSSI );

      EditAverage.text := Format( '%.1f', [ RssiAvg ] );

      if ( Abs(RssiAvg - ARssi) >= RssiStdDev ) then
        EditRssi.FontColor := TAlphaColors.Red
      else
        EditRssi.FontColor := TAlphaColors.Black;
    end;

  end;

  // RSSIの受信状況に基づいて、ビーコンに設定すべき TxPower を算出する
  TxPowerCallibration();
end;

procedure TForm1.Beacon1CalculateDistances(const Sender: TObject;
  const ABeacon: IBeacon; ATxPower, ARssi: Integer; var NewDistance: Double);
{ Beacon の距離計算処理のオーバーライド処理 }
var
  numofListRSSI: integer;
  numofListDistance: integer;

  RssiAvg: Double;
  RssiStdDev: Double;

  UUID: TGUID;
  AMajor, AMinor: Word;
begin
  NewDistance := BluetoothLE1.RssiToDistance(
      ARssi,
      ATxPower,
      0.5
  );

  UUID   := ABeacon.GUID;
  AMajor := ABeacon.Major;
  AMinor := ABeacon.Minor;

  // 監視対象のビーコンの場合だけ、距離計算を実施する
  if ( SwitchMonitoring.isChecked = True ) AND
     ( SelectedBeaconUUID  = UUID.toString ) AND
     ( SelectedBeaconMajor = AMajor ) AND
     ( SelectedBeaconMinor = AMinor ) then
  begin
    // RSSI の値を保持しているリストに新しい計測値を追記する
    numofListRSSI := Length(ListRSSI);
    setLength(ListRSSI,numofListRSSI+1);
    ListRSSI[numofListRSSI] := ARssi;
    inc(numofListRSSI);

    // 距離の計算結果のリストもアップデートする
    numofListDistance := Length(ListRSSI);
    setLength(ListDistance,numofListDistance+1);

    // RSSI を ログ用の TMemo に出力する。
    AddMemoLog( Format( '%d dBm', [ ARssi ] ) );

    EditRSSi.Text := Format( '%d', [ ARssi ] );

    // 平均値と標準偏差を計算する
    EditCount.text := IntToStr(numofListRSSI);
    if ( numofListRSSI > 3 ) then
    begin

      RssiAvg    := System.Math.Mean  ( ListRSSI );
      RssiStdDev := System.Math.StdDev( ListRSSI );

      EditAverage.text := Format( '%.1f', [ RssiAvg ] );

      if ( Abs(RssiAvg - ARssi) >= RssiStdDev ) then
        EditRssi.FontColor := TAlphaColors.Red
      else
        EditRssi.FontColor := TAlphaColors.Black;
    end;

  end;

  // RSSIの受信状況に基づいて、ビーコンに設定すべき TxPower を算出する
  TxPowerCallibration();
end;

procedure TForm1.TxPowerCallibration();
{ 現状の実測値に基づいて、ビーコンに設定すべき TxPower を算出する }
var
  // for ループ用のカウンタ
  loopTxPower: Integer;
  loopRSSIindex: Integer;

  // ビーコンの距離計算に使用する一時変数
  CalcDistance: Double;

  // RSSIリストに基づいて生成する距離リスト
  ListDistanceCalc: array of Double;
  numofListDistanceCalc: Integer;

  // ビーコンまでの距離の平均値（距離リストから算出）
  DistanceAvg: Double;

  // 補正後の平均距離、TxPower
  CallibratedDistanceAvg: Double;
  CallibratedTxPower: Integer;


begin
  CallibratedDistanceAvg := 9999;
  CallibratedTxPower     := -56;

  // TxPower の最適値を -100 ～ -30 の間で探す。
  for loopTxPower := -100 to -30 do
  begin
    // 測定済みの RSSI リストに基づいて距離の再計算を行う。
    setLength(ListDistanceCalc,0);
    for loopRSSIindex := Low(ListRSSI) to High(ListRSSI) do
     begin
      //
      CalcDistance := BluetoothLE1.RssiToDistance(
          StrToInt(Format('%.0f',[ListRSSI[loopRSSIindex]])),
          loopTxPower,
          0.5
      );

      // 算出した距離を array に追加する。
      numofListDistanceCalc := Length(ListDistanceCalc);
      setLength(ListDistanceCalc,numofListDistanceCalc+1);
      ListDistanceCalc[numofListDistanceCalc] := CalcDistance;

    end;

    // RSSIリストから生成した距離リストを使って距離の平均値を算出する。
    DistanceAvg := System.Math.Mean(ListDistanceCalc);

    // ビーコンからの平均距離が、既存の計算済み最適値よりも1m地点に近い場合は
    // 今回の算出で用いた TxPower や平均距離を最適値として取り扱う。
    if ( Abs(DistanceAvg - 1) < Abs(CallibratedDistanceAvg - 1 ) ) then
    begin
      CallibratedTxPower := loopTxPower;
      CallibratedDistanceAvg := DistanceAvg;
    end;

  end;

  // TxPower の補正値をログに書いたり、アプリ内に表示したり。
  AddMemoLog(
    Format('Callibrated Tx = %d',
      [
        CallibratedTxPower
      ]
    )
  );
  EditTxPowerCalibrated.Text := Format('%d', [CallibratedTxPower]);

end;


procedure TForm1.SwitchFindBeaconSwitch(Sender: TObject);
{ Beacon 検索の on / off の切り替えに伴う処理 }
begin
 if (SwitchFindBeacon.IsChecked = True) then
  begin
    // Beacon の検索を行う
    if ( UUID.Text.Length > 0 )  then begin
      // UUID が明示されている場合は、その UUID だけを検索する。
      Beacon1.MonitorizedRegions.Add;
      Beacon1.MonitorizedRegions.Items[0].UUID := UUID.Text;
      ListBox1.Clear;
    end;
    Beacon1.Enabled := True;
    BluetoothLE1.Enabled := True;
    SwitchMonitoring.Enabled := True;
  end
  else
  begin
    // Beacon の検索をやめる
    Beacon1.Enabled := False;
    BluetoothLE1.Enabled := False;
    SwitchMonitoring.Enabled := False;
    SwitchMonitoring.IsChecked := False;
    ListBox1.Clear;
  end;
end;


procedure TForm1.SwitchMonitoringSwitch(Sender: TObject);
{ 指定されたビーコンのモニタリングの on / off }
begin
  // Beacon 選択用のリストボックスの有効無効を切り替える
  Listbox1.Enabled := not SwitchMonitoring.IsChecked;

  if (SwitchMonitoring.isChecked = True ) then
  begin
    // モニタリングの開始に伴って受信済みの RSSI リストを空にする。
    setLength(ListRSSI,0);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // アプリ起動時の TabControl の初期表示はビーコン一覧表示にする
  TabControl1.Activetab := TabItem1FindBeacon;
end;

procedure TForm1.ListBox1ItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
{ ビーコン一覧からビーコンを選択したときの処理 }
var
  BeaconSL_quote: TStringList;
  BeaconSL:       TStringList;
begin
  // Beacon一覧は Major:Minor:{UUID} の形式なので、ここから UUID だけを抜き出す。
  BeaconSL_quote := TStringList.Create;
  BeaconSL_quote.Delimiter := '''';
  BeaconSL_quote.DelimitedText := Item.toString;

  BeaconSL := TStringList.Create;
  BeaconSL.Delimiter := ':';
  BeaconSL.DelimitedText := BeaconSL_quote.Strings[1];

  SelectedBeaconMajor := BeaconSL.Strings[0].toInteger;
  SelectedBeaconMinor := BeaconSL.Strings[1].toInteger;
  SelectedBeaconUUID  := BeaconSL.Strings[2];

  BeaconSL_quote.free;
  BeaconSL.free;

  Memo1.Lines.Clear;
  setLength(ListRSSI,0);
  UUID.Text := SelectedBeaconUUID;

end;

procedure TForm1.AddMemoLog(AString: String);
{ Memo1 に日付時刻付きのログを書くだけの処理 }
begin
  Memo1.Lines.Insert(0,
      FormatDateTime('yyyy/mm/dd hh:mm:ss',Now()) + ' ' + AString );
end;

end.

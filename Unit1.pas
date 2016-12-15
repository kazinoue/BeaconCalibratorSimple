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
    { private �錾 }
    SelectedBeaconUUID: String;
    SelectedBeaconMajor: Integer;
    SelectedBeaconMinor: Integer;

    ListRSSI: array of Single;
    ListDistance: array of Double;
    procedure TxPowerCallibration();
  public
    { public �錾 }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure TForm1.Beacon1BeaconEnter(const Sender: TObject;
  const ABeacon: IBeacon; const CurrentBeaconList: TBeaconList);
{ Beacon�����o�������̏��� }
var
  BeaconMajorMinorSSID: String;
begin
  // Beacon �����o������ ListBox �ɒǋL����B
  BeaconMajorMinorSSID := Format( '%d:%d:%s', [ ABeacon.Major, ABeacon.Minor, ABeacon.GUID.toString ] );
  with ListBox1.Items do
    if IndexOf(BeaconMajorMinorSSID) < 0 then
      ListBox1.Items.Insert(0,BeaconMajorMinorSSID);
end;

procedure TForm1.Beacon1BeaconExit(const Sender: TObject;
  const ABeacon: IBeacon; const CurrentBeaconList: TBeaconList);
{ Beacon �����o�ł��Ȃ��Ȃ����Ƃ��̏���? }
var
  BeaconMajorMinorSSID: String;
begin
  // Beacon �̏��� Listbox �������
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
{ Beacon �̋����v�Z�����̃I�[�o�[���C�h���� }
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

  // �Ď��Ώۂ̃r�[�R���̏ꍇ�����A�����v�Z�����{����
  if ( SwitchMonitoring.isChecked = True ) AND
     ( SelectedBeaconUUID  = UUID.toString ) AND
     ( SelectedBeaconMajor = AMajor ) AND
     ( SelectedBeaconMinor = AMinor ) then
  begin
    // RSSI �̒l��ێ����Ă��郊�X�g�ɐV�����v���l��ǋL����
    numofListRSSI := Length(ListRSSI);
    setLength(ListRSSI,numofListRSSI+1);
    ListRSSI[numofListRSSI] := ARssi;
    inc(numofListRSSI);

    // �����̌v�Z���ʂ̃��X�g���A�b�v�f�[�g����
    numofListDistance := Length(ListRSSI);
    setLength(ListDistance,numofListDistance+1);

    // RSSI �� ���O�p�� TMemo �ɏo�͂���B
    AddMemoLog( Format( '%d dBm', [ ARssi ] ) );

    EditRSSi.Text := Format( '%d', [ ARssi ] );

    // ���ϒl�ƕW���΍����v�Z����
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

  // RSSI�̎�M�󋵂Ɋ�Â��āA�r�[�R���ɐݒ肷�ׂ� TxPower ���Z�o����
  TxPowerCallibration();
end;

procedure TForm1.Beacon1CalculateDistances(const Sender: TObject;
  const ABeacon: IBeacon; ATxPower, ARssi: Integer; var NewDistance: Double);
{ Beacon �̋����v�Z�����̃I�[�o�[���C�h���� }
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

  // �Ď��Ώۂ̃r�[�R���̏ꍇ�����A�����v�Z�����{����
  if ( SwitchMonitoring.isChecked = True ) AND
     ( SelectedBeaconUUID  = UUID.toString ) AND
     ( SelectedBeaconMajor = AMajor ) AND
     ( SelectedBeaconMinor = AMinor ) then
  begin
    // RSSI �̒l��ێ����Ă��郊�X�g�ɐV�����v���l��ǋL����
    numofListRSSI := Length(ListRSSI);
    setLength(ListRSSI,numofListRSSI+1);
    ListRSSI[numofListRSSI] := ARssi;
    inc(numofListRSSI);

    // �����̌v�Z���ʂ̃��X�g���A�b�v�f�[�g����
    numofListDistance := Length(ListRSSI);
    setLength(ListDistance,numofListDistance+1);

    // RSSI �� ���O�p�� TMemo �ɏo�͂���B
    AddMemoLog( Format( '%d dBm', [ ARssi ] ) );

    EditRSSi.Text := Format( '%d', [ ARssi ] );

    // ���ϒl�ƕW���΍����v�Z����
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

  // RSSI�̎�M�󋵂Ɋ�Â��āA�r�[�R���ɐݒ肷�ׂ� TxPower ���Z�o����
  TxPowerCallibration();
end;

procedure TForm1.TxPowerCallibration();
{ ����̎����l�Ɋ�Â��āA�r�[�R���ɐݒ肷�ׂ� TxPower ���Z�o���� }
var
  // for ���[�v�p�̃J�E���^
  loopTxPower: Integer;
  loopRSSIindex: Integer;

  // �r�[�R���̋����v�Z�Ɏg�p����ꎞ�ϐ�
  CalcDistance: Double;

  // RSSI���X�g�Ɋ�Â��Đ������鋗�����X�g
  ListDistanceCalc: array of Double;
  numofListDistanceCalc: Integer;

  // �r�[�R���܂ł̋����̕��ϒl�i�������X�g����Z�o�j
  DistanceAvg: Double;

  // �␳��̕��ϋ����ATxPower
  CallibratedDistanceAvg: Double;
  CallibratedTxPower: Integer;


begin
  CallibratedDistanceAvg := 9999;
  CallibratedTxPower     := -56;

  // TxPower �̍œK�l�� -100 �` -30 �̊ԂŒT���B
  for loopTxPower := -100 to -30 do
  begin
    // ����ς݂� RSSI ���X�g�Ɋ�Â��ċ����̍Čv�Z���s���B
    setLength(ListDistanceCalc,0);
    for loopRSSIindex := Low(ListRSSI) to High(ListRSSI) do
     begin
      //
      CalcDistance := BluetoothLE1.RssiToDistance(
          StrToInt(Format('%.0f',[ListRSSI[loopRSSIindex]])),
          loopTxPower,
          0.5
      );

      // �Z�o���������� array �ɒǉ�����B
      numofListDistanceCalc := Length(ListDistanceCalc);
      setLength(ListDistanceCalc,numofListDistanceCalc+1);
      ListDistanceCalc[numofListDistanceCalc] := CalcDistance;

    end;

    // RSSI���X�g���琶�������������X�g���g���ċ����̕��ϒl���Z�o����B
    DistanceAvg := System.Math.Mean(ListDistanceCalc);

    // �r�[�R������̕��ϋ������A�����̌v�Z�ςݍœK�l����1m�n�_�ɋ߂��ꍇ��
    // ����̎Z�o�ŗp���� TxPower �╽�ϋ������œK�l�Ƃ��Ď�舵���B
    if ( Abs(DistanceAvg - 1) < Abs(CallibratedDistanceAvg - 1 ) ) then
    begin
      CallibratedTxPower := loopTxPower;
      CallibratedDistanceAvg := DistanceAvg;
    end;

  end;

  // TxPower �̕␳�l�����O�ɏ�������A�A�v�����ɕ\��������B
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
{ Beacon ������ on / off �̐؂�ւ��ɔ������� }
begin
 if (SwitchFindBeacon.IsChecked = True) then
  begin
    // Beacon �̌������s��
    if ( UUID.Text.Length > 0 )  then begin
      // UUID ����������Ă���ꍇ�́A���� UUID ��������������B
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
    // Beacon �̌�������߂�
    Beacon1.Enabled := False;
    BluetoothLE1.Enabled := False;
    SwitchMonitoring.Enabled := False;
    SwitchMonitoring.IsChecked := False;
    ListBox1.Clear;
  end;
end;


procedure TForm1.SwitchMonitoringSwitch(Sender: TObject);
{ �w�肳�ꂽ�r�[�R���̃��j�^�����O�� on / off }
begin
  // Beacon �I��p�̃��X�g�{�b�N�X�̗L��������؂�ւ���
  Listbox1.Enabled := not SwitchMonitoring.IsChecked;

  if (SwitchMonitoring.isChecked = True ) then
  begin
    // ���j�^�����O�̊J�n�ɔ����Ď�M�ς݂� RSSI ���X�g����ɂ���B
    setLength(ListRSSI,0);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  // �A�v���N������ TabControl �̏����\���̓r�[�R���ꗗ�\���ɂ���
  TabControl1.Activetab := TabItem1FindBeacon;
end;

procedure TForm1.ListBox1ItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
{ �r�[�R���ꗗ����r�[�R����I�������Ƃ��̏��� }
var
  BeaconSL_quote: TStringList;
  BeaconSL:       TStringList;
begin
  // Beacon�ꗗ�� Major:Minor:{UUID} �̌`���Ȃ̂ŁA�������� UUID �����𔲂��o���B
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
{ Memo1 �ɓ��t�����t���̃��O�����������̏��� }
begin
  Memo1.Lines.Insert(0,
      FormatDateTime('yyyy/mm/dd hh:mm:ss',Now()) + ' ' + AString );
end;

end.

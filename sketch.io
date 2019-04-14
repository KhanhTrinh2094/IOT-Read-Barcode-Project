
#include <hiduniversal.h>
#include <usbhub.h>
#include <avr/pgmspace.h>
#include <Usb.h>
#include <usbhub.h>
#include <avr/pgmspace.h>
#include <hidboot.h>
#include <SoftwareSerial.h>

const byte rxPin = 5;
const byte txPin = 6;

SoftwareSerial ESP8266 (rxPin, txPin);
USB     Usb;
USBHub     Hub(&Usb); //I enable this line
String codeString;
char z;
int cont = 0;
String readString;
String host = "930bbc8297.to.intercept.rest";

HIDUniversal      Hid(&Usb);
HIDBoot<USB_HID_PROTOCOL_KEYBOARD>    Keyboard(&Usb);

class KbdRptParser : public KeyboardReportParser
{
    void PrintKey(uint8_t mod, uint8_t key);
  protected:
    virtual void OnKeyDown  (uint8_t mod, uint8_t key);
    virtual void OnKeyPressed(uint8_t key);
};

void KbdRptParser::OnKeyDown(uint8_t mod, uint8_t key)
{
  uint8_t c = OemToAscii(mod, key);
  if (c)
    OnKeyPressed(c);

}

void sendRequest(String barcode) {
  String cmd = "GET /?cage=5&orderRef=" + barcode + " HTTP/1.1\r\n";
  cmd += "Host: " + host + "\r\n";
  cmd += "Connection: keep-alive";
  ESP8266.println("AT+CIPSEND=0," + String(cmd.length() + 4));
  delay(100);

  ESP8266.println(cmd);
  delay(100);

  ESP8266.println("");

  Serial.println("Sent Request");
}

/* what to do when symbol arrives */
void KbdRptParser::OnKeyPressed(uint8_t key)
{
  z = ((char)key);
  codeString += z;
  cont = cont + 1;

  if (key == 13) {
    codeString.remove(cont - 1);
    Serial.println(codeString);

    sendRequest(codeString);
    codeString = "";
    cont = 0;
  }
}

KbdRptParser Prs;

void setup()
{
  Serial.begin(9600);
  ESP8266.begin(115200);
  delay(2000);

  //    ESP8266.println("AT");
  //    delay(1000);
  //  printResponse();
  //    ESP8266.println("AT+CWMODE=1");
  //    delay(1000);
  //  printResponse();
  //    ESP8266.println("AT+CWJAP=\"Dat09\",\"bananhquan\"");
  //    delay(10000);
  //  printResponse();
  //    ESP8266.println("AT+CIPMUX=1");
  //    delay(1000);
  //  printResponse();

  //  ESP8266.println("AT+CIPCLOSE=4");
  //  delay(1000);

  ESP8266.println("AT+CIPSTART=0,\"TCP\",\"" + host + "\",80");
  delay(1000);

  printResponse();

  //  ESP8266.println("AT+HTTPSSL=1");
  //  delay(1000);
  //  printResponse();
  Serial.println("Start");

  if (Usb.Init() == -1) {
    Serial.println("OSC did not start.");
  }

  Hid.SetReportParser(0, (HIDReportParser*)&Prs);
  delay( 200 );
}

void loop()
{
  Usb.Task();
}

void printResponse() {
  while (ESP8266.available()) {
    Serial.println(ESP8266.readStringUntil('\n'));
  }
}

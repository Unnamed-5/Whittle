// System Inialization Setup
char *protocolString = "007,006,150,200,002,003,180,060,045,167,946,268,567,278,007,006,007,006,150,200,150,2,150,200,15,200,150,200,150,200,0150,200,150,0200,150,200,150,200,150,200,150,200,150,200,";

String protocolString = "";
boolean protocolWait = false;
String parsedString = "";
int startIndex = 0;
String totalString = "";
String ledString = "";
unsigned int XTimecount;
unsigned int XTime;
unsigned int YTimecount;
unsigned int YTime;
unsigned int XPositionNew;
unsigned int YPositionNew;
unsigned int XDurationcount;
unsigned int YDurationcount;
unsigned int width = 625;
unsigned int xleft = 0;
unsigned int xright = 0;
unsigned int yboth;
unsigned int xleftold = 0;
unsigned int ybothold = 0;
unsigned int xdiagonal;
unsigned int ydiagonal;
int xleftnew = 0;
int ybothnew = 0;
unsigned int leftdiagonalreal;
unsigned int rightdiagonalreal;
unsigned int leftdiagonalold = 0;
unsigned int rightdiagonalold = 0;
int STEPState1 = LOW;
int DIRState1 = HIGH;
int STEPState2 = LOW;
int DIRState2 = HIGH;
const int DIRPin1 = 2;
const int STEPPin1 = 3;
const int ENNPin1 = 8;
const int DIRPin2 = 4;
const int STEPPin2 = 7;
const int Sprayer = 12; 
int leftDistance;
int rightDistance;
bool positionFound = false;



void initOutput() {
  //digitalWrite(ENNpin,HIGH);   // Disable motors
  //We are going to overwrite the Timer1 to use the stepper motors
  // STEPPER MOTORS INITIALIZATION
  // TIMER1 CTC MODE
  TCCR1B &= ~(1<<WGM13);
  TCCR1B |=  (1<<WGM12);
  TCCR1A &= ~(1<<WGM11); 
  TCCR1A &= ~(1<<WGM10);

  // output mode = 00 (disconnected)
  TCCR1A &= ~(3<<COM1A0); 
  TCCR1A &= ~(3<<COM1B0); 

  // Set the timer pre-scaler
  // Generally we use a divider of 8, resulting in a 2MHz timer on 16MHz CPU
  TCCR1B = (TCCR1B & ~(0x07<<CS10)) | (2<<CS10);

  //OCR1A = 125;  // 16Khz
  //OCR1A = 100;  // 20Khz
  OCR1A = 250;   // 8Khz
  TCNT1 = 0;

  TIMSK1 |= (1<<OCIE1A);  // Enable Timer1 interrupt
  //digitalWrite(ENNpin, LOW);   // Enable stepper drivers
}
void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB
  }
  pinMode(DIRPin1, OUTPUT);
  pinMode(STEPPin1, OUTPUT);
  pinMode(DIRPin2, OUTPUT);
  pinMode(STEPPin2, OUTPUT);
  pinMode(ENNPin1, OUTPUT);
  pinMode(Sprayer, OUTPUT);
  digitalWrite(DIRPin1, HIGH);
  digitalWrite(STEPPin1, LOW);
  digitalWrite(DIRPin2, LOW);
  digitalWrite(STEPPin2, HIGH);
  digitalWrite(ENNPin1, LOW);
  digitalWrite(Sprayer, LOW);
  initOutput();
}

void loop() {
  char data[50][5];
  Serial.println("split string...");
  delay(50);
  int cnt = split(data, protocolString, ",");
  for (int i = 0; i < cnt; i++){
      Serial.print("M"）；
      Serial.print(data[i]);
      Serial.println(";");
      delay(50);
  }
//  Serial.println("pass");
  if (Serial.available() > 0) {
    protocolString = Serial.readString();
    Serial.println(protocolString);
    for (int i = 0; i <= protocolString.length(); i++){ // Analyze command string one character at a time
      parsedString = protocolString.substring(i,i+1); 
      if (parsedString == ";"){ // ';' Symbolizes the end of a command
          if (protocolString.substring(startIndex, startIndex+1) == "M"){
          xleft = protocolString.substring(startIndex+1,i-3).toInt();
          yboth = protocolString.substring(startIndex+4,i).toInt();
          xleftnew = (xleft*6.25);
          ybothnew = (yboth*6.25);
          xrightnew = width - xleftnew;
          xdiagonal = (xleftnew*xleftnew)+(ybothnew*ybothnew);
          ydiagonal = (xrightnew*xrightnew)+(ybothnew*ybothnew);
          leftdiagonalreal = sqrt(xdiagonal);
          rightdiagonalreal = sqrt(ydiagonal);
          leftDistance = (leftdiagonalreal - leftdiagonalold);
          rightDistance = (rightdiagonalreal - rightdiagonalold);
          if ((leftDistance > 0)){
            digitalWrite(DIRPin1,HIGH);
          }
          else if ((leftDistance < 0)){
            digitalWrite(DIRPin1, LOW);
          }
          else if (leftDistance = 0){
            XTimecount = XTime;
          }
          if (rightDistance > 0){
            digitalWrite(DIRPin2,LOW);
          }
          else if (rightDistance < 0){
            digitalWrite(DIRPin2, HIGH);
          }
          else if (rightDistance =0){
            YTimecount = YTime;
          }
          XTime = abs(leftDistance);
          YTime = abs(rightDistance);
          XDurationcount = 0;
          YDurationcount = 0;
          XTimecount = 0;
          YTimecount = 0;
          delay(max(abs(leftDistance),abs(rightDistance))*0.75);
          Serial.println("done");
        }
        else if(protocolString.substring(startIndex, startIndex+1) == "S"){
           leftdiagonalreal = 0;
           rightdiagonalreal = 1000;
           MoveFunction();
           digitalWrite(Sprayer, HIGH);
           delay(400);
           digitalWrite(Sprayer, LOW);
           rightdiagonalreal = 2000;
           MoveFunction();
           digitalWrite(Sprayer, HIGH);
           delay(400);
           digitalWrite(Sprayer, LOW);
           rightdiagonalreal = 3000;
           MoveFunction();
           digitalWrite(Sprayer, HIGH);
           delay(400);
           digitalWrite(Sprayer, LOW);
           rightdiagonalreal = 4000;
           MoveFunction();
           digitalWrite(Sprayer, HIGH);
           delay(400);
           digitalWrite(Sprayer, LOW);
           Serial.println("done");
         }
      }  
    } 
  }
}


  ISR(TIMER1_COMPA_vect){
    if ((XTimecount < XTime) && (0 <= leftdiagonalreal) && (leftdiagonalreal <=2659600)) {
      if (XDurationcount < 45) {
        XDurationcount++;
      }
      else if (XDurationcount >= 45) {
        if (STEPState1 == LOW) {
          STEPState1 = HIGH;
        } else {
          STEPState1 = LOW;
        }
        digitalWrite(STEPPin1, STEPState1);
        XDurationcount = 0;
        XTimecount++;
        if ((leftDistance > 0)){
          leftdiagonalold++;
        }
        else if ((leftDistance < 0)){
          leftdiagonalold--;
        }
      }
    }
    if (YTimecount < YTime && (0 <= rightdiagonalreal) && (rightdiagonalreal <=1355600)) {
      if (YDurationcount < 45) {
        YDurationcount++;
      }
      else if (YDurationcount >= 45) {
        if (STEPState2 == LOW) {
          STEPState2 = HIGH;
        } else {
          STEPState2 = LOW;
        }
        digitalWrite(STEPPin2, STEPState2);
        YDurationcount = 0;
        YTimecount++;
        if ((rightDistance > 0)){
          rightdiagonalold++;
        }
        else if ((rightDistance < 0)){
          rightdiagonalold--;
        }
      }
    }
    if (YTimecount >= YTime){
      digitalWrite(STEPPin2, 0);
    }
    if (XTimecount >= XTime){
      digitalWrite(STEPPin1, 0);
    }
  }


void MoveFunction(void){
  leftDistance = (leftdiagonalreal - leftdiagonalold);
  rightDistance = (rightdiagonalreal - rightdiagonalold);
  if ((leftDistance > 0)){
    digitalWrite(DIRPin1,HIGH);
  }
  else if ((leftDistance < 0)){
    digitalWrite(DIRPin1, LOW);
  }
  else if (leftDistance = 0){
    XTime = XTimecount;
  }
  if (rightDistance > 0){
    digitalWrite(DIRPin2,LOW);
  }
  else if (rightDistance < 0){
    digitalWrite(DIRPin2, HIGH);
  }
  else if (rightDistance =0){
    YTime = YTimecount;
  }
  XTime = abs(leftDistance);
  YTime = abs(rightDistance);
  XDurationcount = 0;
  YDurationcount = 0;
  XTimecount = 0;
  YTimecount = 0;
  delay(max(abs(leftDistance),abs(rightDistance))*0.75);
}

void Split(void){
int split(char dst[][5], char* str, const char* spl)
{
    int n = 0;
    char *result = NULL;
//    Serial.println(str);
    result = strtok(str, spl);
//    Serial.println(result);

    while( result != NULL )
    {
        Serial.println(result);
        strcpy(dst[n++], result);
        delay(50);
        Serial.println(n);
    for (int i = 0; i < n; i++){
    }
        result = strtok(NULL, spl);
    }
    return n;
}
}

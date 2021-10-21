int split(char dst[][5], char* str, const char* spl){
    int n = 0;
    char *result = NULL;
    result = strtok(str, spl);
    while( result != NULL ){
    strcpy(dst[n++], result);
    delay(50);
    for (int i = 0; i < n; i++){
    }
    result = strtok(NULL, spl);
    }
    return n;
}
int coff = 120;
boolean protocolWait = false;
String parsedString = "";
int startIndex = 0;
String totalString = "";
String ledString = "";
unsigned int long XTimecount;
unsigned int long YTimecount;
unsigned int xleft = 0;
unsigned int xright = 0;
unsigned int yboth = 0;
int long leftDistance;
int long rightDistance;
float width = 100;
float XTime;
float YTime;
float xdiagonal;
float ydiagonal;
float xleftnew = 0;
float ybothnew = 0;
float xrightnew = 0;
float leftdiagonalreal;
float rightdiagonalreal;
float leftdiagonalold = 0;
float rightdiagonalold = width*coff;
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
const float time11 = 5;
bool positionFound = false;

void setup() {
  Serial.begin(9600);
  while (!Serial) {
  ;}
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
  delay(100);
  char data[100][5];
  long int moveset[2];
  Serial.println("split string...");
  delay(50);
  int cnt = split(data, protocolString, ",");
  Serial.println("finish split");
  Serial.println(cnt);
  for (int i = 0; i < cnt; i=i+2){
    delay(50);
    xleft = atoi(data[i]);
    yboth = atoi(data[i+1]);
    Computation (moveset);
    Serial.println(moveset[0]);
    Serial.println(moveset[1]);
    XTimecount = 0;
    YTimecount = 0;
    if ((leftDistance > 0)){
      digitalWrite(DIRPin1,LOW);
    }
    else if ((leftDistance < 0)){
      digitalWrite(DIRPin1, HIGH);
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
    Serial.print("XTime");
    Serial.println(XTime);
    Serial.print("YTime");
    Serial.println(YTime);
    delay(1000);
    digitalWrite(Sprayer, HIGH);
    while (XTimecount < XTime){
          if (STEPState1 == LOW) {
            delay(time11);
            STEPState1 = HIGH;
          } else {
            delay(time11);
            STEPState1 = LOW;
          }
          digitalWrite(STEPPin1, STEPState1);
          XTimecount++;
    }
    while (YTimecount < YTime) {
        if (STEPState2 == LOW) {
          delay(time11);
          STEPState2 = HIGH;
        } else {
          delay(time11);
          STEPState2 = LOW;
        }
        digitalWrite(STEPPin2, STEPState2);
        YTimecount++;
      }
  digitalWrite(Sprayer, LOW);
  if (YTimecount >= YTime){
    digitalWrite(STEPPin2, 0);
  }
  if (XTimecount >= XTime){
    digitalWrite(STEPPin1, 0);
  }
  }
  Serial.println("done");
}
void loop() {}

void Computation (long int resultant[2]){
xright = width - xleft;
xleftnew = (xleft*coff);
ybothnew = (yboth*coff);
xrightnew = (xright*coff);
xdiagonal = (xleftnew*xleftnew)+(ybothnew*ybothnew);
ydiagonal = (xrightnew*xrightnew)+(ybothnew*ybothnew);
leftdiagonalreal = sqrt(xdiagonal);
rightdiagonalreal = sqrt(ydiagonal);
leftDistance = (leftdiagonalreal - leftdiagonalold);
rightDistance = (rightdiagonalreal - rightdiagonalold);
resultant[0] = leftDistance;
resultant[1] = rightDistance;
leftdiagonalold = leftdiagonalreal;
rightdiagonalold = rightdiagonalreal;
}

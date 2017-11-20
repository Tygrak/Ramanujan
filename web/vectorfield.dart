import 'dart:html';
import 'dart:math';
import 'dart:collection';

CanvasElement canvas;
ButtonElement button;
CanvasRenderingContext2D ctx;
double x = 0.0;
double y = 0.0;
double zoom = 10.0;
double timeScale = 0.1;
num updateTimer = 40;
num lastTimeStamp = 0;
List<Point> points = [new Point(0.1, 0.1)];
int pointSize = 2;
Random rand = new Random();
String xEquation = "-y";
String yEquation = "x";
String backgroundColor = "173, 217, 230";
String pointsColor = "4, 4, 38";
double fadealpha = 0.05;

void main(){
  canvas = querySelector("#canvas");
  ctx = canvas.getContext("2d");
  button = querySelector("#regeneratebutton");
  button.addEventListener("click", Regenerate);
  GeneratePoints(300);
  Run();
}

void Regenerate(e){
  InputElement element = querySelector("[name=x]");
  x = double.parse(element.value);
  element = querySelector("[name=y]");
  y = double.parse(element.value);
  element = querySelector("[name=xequation]");
  xEquation = element.value;
  element = querySelector("[name=yequation]");
  yEquation = element.value;
  element = querySelector("[name=zoom]");
  zoom = double.parse(element.value);
  element = querySelector("[name=timescale]");
  timeScale = double.parse(element.value);
  element = querySelector("[name=pointsize]");
  pointSize = int.parse(element.value);
  element = querySelector("[name=points]");
  GeneratePoints(int.parse(element.value));
  element = querySelector("[name=fadealpha]");
  fadealpha = double.parse(element.value);
  element = querySelector("[name=backgroundcolor]");
  backgroundColor = element.value;
  element = querySelector("[name=pointscolor]");
  pointsColor = element.value;
  ctx.fillStyle = "rgba($backgroundColor)";
  ctx.fillRect(0, 0, canvas.width, canvas.height);
}

void GeneratePoints(int amount){
  points = [];
  for (var i = 0; i < amount; i++){
    points.add(new Point(x+rand.nextDouble()*zoom-zoom/2, y+rand.nextDouble()*zoom-zoom/2));
  }
}

void Run(){
  window.animationFrame.then(UpdateField);
}

void UpdateField(num time){
  num delta = time - lastTimeStamp;
  if (delta > updateTimer){
    lastTimeStamp = time;
    ctx.fillStyle = "rgba($backgroundColor, $fadealpha)";
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    for (var i = 0; i < points.length; i++){
      double pointx = points[i].x + ((GetEquationValue(points[i], xEquation))*timeScale*1/delta);
      double pointy = points[i].y + ((GetEquationValue(points[i], yEquation))*timeScale*1/delta);
      if (!pointx.isInfinite && !pointx.isNaN && !pointy.isInfinite && !pointy.isNaN){
        points[i] = new Point(pointx, pointy);
      }
      int pX = Map(points[i].x, x-zoom/2, x+zoom/2, 0.0, canvas.width as double).toInt();
      int pY = Map(points[i].y, y-zoom/2, y+zoom/2, 0.0, canvas.height as double).toInt();
      ctx.fillStyle = "rgb($pointsColor)";
      ctx.fillRect(pX, pY, pointSize, pointSize);
    }
    for (var i = 0; i < points.length/100; i++){
      int r = rand.nextInt(points.length);
      points[r] = new Point(x+rand.nextDouble()*zoom-zoom/2, y+rand.nextDouble()*zoom-zoom/2);
    }
  }
  Run();
}

double Map(double value, double min1, double max1, double min2, double max2){
  if (max1-min1 != 0){
    value = (value-min1)/(max1-min1) * (max2-min2) + min2;
    return value;
  }
  throw new Exception("Map min1 and max1 are equal!");
}

double GetEquationValue(Point p, String equation){
  Queue<num> stack = new Queue<num>();
  List<String> values = equation.split(" ");
  for (var i = 0; i < values.length; i++){
    num value;
    try{
      value = num.parse(values[i]);
    } catch (e){
    }
    if (value != null){
      stack.add(value);
    } else if (values[i] == "x"){
      stack.add(p.x);
    } else if (values[i] == "-x"){
      stack.add(-p.x);
    } else if (values[i] == "y"){
      stack.add(p.y);
    } else if (values[i] == "-y"){
      stack.add(-p.y);
    } else if (values[i] == "+"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()+last);
    } else if (values[i] == "-"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()-last);
    } else if (values[i] == "*"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()*last);
    } else if (values[i] == "/"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()/last);
    } else if (values[i] == "%"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()%last);
    } else if (values[i] == "sin"){
      stack.add(sin(stack.removeLast()));
    } else if (values[i] == "cos"){
      stack.add(cos(stack.removeLast()));
    } else if (values[i] == "tan"){
      stack.add(tan(stack.removeLast()));
    } else if (values[i] == "sqrt"){
      stack.add(sqrt(stack.removeLast()));
    } else if (values[i] == "pow"){
      double last = stack.removeLast();
      stack.add(pow(stack.removeLast(), last));
    } else if (values[i] == "ln" || values[i] == "log"){
      stack.add(log(stack.removeLast()));
    } else if (values[i] == "abs"){
      double last = stack.removeLast();
      if (last > 0){
        stack.add(last);
      } else{
        stack.add(-last);
      }
    } else if (values[i] == "sign"){
      double last = stack.removeLast();
      if (last > 0){
        stack.add(1);
      } else if (last < 0){
        stack.add(-1);
      } else{
        stack.add(0);
      }
    } else if (values[i] == "floor"){
      stack.add((stack.removeLast()).floorToDouble());
    } else if (values[i] == "ceil"){
      stack.add((stack.removeLast()).ceilToDouble());
    } else if (values[i] == "round"){
      stack.add((stack.removeLast()).roundToDouble());
    } else if (values[i] == "pi"){
      stack.add(PI);
    } else if (values[i] == "e"){
      stack.add(E);
    }
    //print(stack);
  }
  return stack.removeLast().toDouble();
}
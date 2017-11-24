import 'dart:html';
import 'dart:math';
import 'dart:collection';
import 'Variable.dart';
import 'Complex.dart';
import 'mathExtensions.dart';

ButtonElement button;
CanvasElement canvas;

void main(){
  button = querySelector("#calculatebutton");
  canvas = querySelector("#canvas");
  print(canvas.className);
  button.addEventListener("click", ButtonClicked);
}

void ButtonClicked(e){
  PageClearResult();
  InputElement element = querySelector("[name=equation]");
  String equation = element.value;
  List<String> infixStack = ParseEquation(equation);
  print("$infixStack");
  List<String> postfixStack = InfixToPostfix(infixStack);
  print("----------");
  try{
    double expressionValue = GetPostfixValue(postfixStack);
    print("$infixStack -> $postfixStack -> $expressionValue");
    PageAddResult("Result", "$expressionValue");
  } catch (e){
    //try{
      VariablePolynom vp = SimplifyPostfix(postfixStack);
      VariablePolynom deriv = DerivatePolynom(vp);
      VariablePolynom deriv2 = DerivatePolynom(deriv);
      List<double> roots = GetPolynomRoots(vp);
      print("$infixStack -> $postfixStack -> $vp -> $deriv -> $deriv2");
      PlotPolynomFunction(vp, roots);
      String rootsHtml = "";
      for (var i = 0; i < roots.length; i++){
        if (rootsHtml != "") rootsHtml += "<br>";
        rootsHtml += "${roots[i]}";
        print("root : ${roots[i]}");
      }
      if (roots.length == 0){
        PageAddResult("Roots", "No roots found.");
      } else if (roots.length == 1){
        PageAddResult("Root", "${rootsHtml}");
      } else{
        PageAddResult("Roots", "${rootsHtml}");
      }
      if (deriv2.variables.length > 0) PageAddResult("Second Derivate", "$deriv2");
      if (deriv.variables.length > 0) PageAddResult("Derivate", "$deriv");
      PageAddResult("Simplified", "$vp");
      print("Equation for 1:${vp.Evaluate(1.0)}");
      print("Equation for 2:${vp.Evaluate(2.0)}");
    /*} catch (e){
      print(e);
    }*/
  }
}

void PageClearResult(){
  Element results = querySelector("#resultitems");
  results.innerHtml = "";
  querySelector("#canvasresult").className = "resultitem hidden";
}

void PageAddResult(String type, String value){
  Element results = querySelector("#resultitems");
  String className = querySelector("#canvasresult").className.contains("hidden") ? "resultitem" : "resultitem border";
  if (!className.contains("border") && results.innerHtml.contains("resultitem")){
    className = "resultitem border";
  }
  String result = 
"""<div class="$className">
    <div class="type">
      $type:
    </div>
    <div class="result">
      $value
    </div>
  </div>""";
  results.innerHtml = result + results.innerHtml;
}

List<String> ParseEquation(String equation){
  equation = equation.replaceAll(new RegExp("[	 ]"), "");
  String number = "";
  String lastSymbol = "";
  List<String> stack = new List<String>();
  void AddNumberToStack(){
    if (number != ""){
      stack.add(number);
      number = "";
    }
  }
  for (var i = 0; i < equation.length; i++){
    if (equation[i] == "+"){
      AddNumberToStack();
      stack.add("+");
    } else if (equation[i] == "-"){
      if (!(lastSymbol.contains(new RegExp("[0-9.)]")) || lastSymbol.contains(new RegExp("[A-Za-z]"))) && number == ""){
        number += "-";
      } else{
        AddNumberToStack();
        stack.add("-");
      }
    } else if (equation[i] == "*" && i < equation.length && equation[i+1] == "*"){
      AddNumberToStack();
      stack.add("**");
      lastSymbol = "**";
      i++;
    } else if (equation[i] == "^"){
      AddNumberToStack();
      stack.add("**");
      lastSymbol = "**";
    } else if (equation[i] == "*"){
      AddNumberToStack();
      stack.add("*");
    } else if (equation[i] == "/"){
      AddNumberToStack();
      stack.add("/");
    } else if (equation[i] == "%"){
      AddNumberToStack();
      stack.add("%");
    } else if (equation[i] == "("){
      bool flag = false;
      if (number == "-"){
        number = "-1";
        flag = true;
      } else if (number != ""){
        flag = true;
      }
      AddNumberToStack();
      if (flag || lastSymbol == ")"){
        stack.add("*");
      }
      stack.add("(");
    } else if (equation[i] == ")"){
      AddNumberToStack();
      stack.add(")");
    } else if (equation.length > i+1 && equation.substring(i, i+2) == "pi"){
      if (number == "-"){
        number += PI.toString();
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = PI.toString();
      } else{
        number = PI.toString();
      }
      AddNumberToStack();
      i += 1;
    } else if (equation[i] == "e"){
      if (number == "-"){
        number += E.toString();
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = E.toString();
      } else{
        number = E.toString();
      }
      AddNumberToStack();
    } else if (equation[i] == "!"){
      AddNumberToStack();
      stack.add("!");
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "sin"){
      AddNumberToStack();
      stack.add("sin");
      i += 2;
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "cos"){
      AddNumberToStack();
      stack.add("cos");
      i += 2;
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "log"){
      AddNumberToStack();
      stack.add("log");
      i += 2;
    } else if (equation.length > i+1 && equation.substring(i, i+2) == "ln"){
      AddNumberToStack();
      stack.add("ln");
      i += 1;
    } else if (equation.length > i+3 && equation.substring(i, i+4) == "sqrt"){
      AddNumberToStack();
      stack.add("sqrt");
      i += 3;
    } else if (equation[i].contains(new RegExp("[0-9.]"))){
      number += equation[i];
    } else{
      if (number == "-"){
        number += equation[i];
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = equation[i];
      } else{
        number = equation[i];
      }
      AddNumberToStack();
    }
    lastSymbol = equation[i];
  }
  AddNumberToStack();
  return stack;
}

List<String> InfixToPostfix(List<String> infixStack){
  List<String> stack = new List<String>();
  List<String> opstack = new List<String>();
  for (var i = 0; i < infixStack.length; i++){
    if (infixStack[i].contains(new RegExp("[0-9.]")) || (infixStack[i].contains(new RegExp("[A-Za-z]")) && infixStack[i].length == 1)){
      stack.add(infixStack[i]);
    } else{
      if (infixStack[i] == "("){
        opstack.add("(");
      } else if (infixStack[i] == ")"){
        for (var j = opstack.length-1; j >= 0; j--){
          String last = opstack.removeLast();
          if (last != "("){
            stack.add(last);
          } else{
            break;
          }
        }
      } else if (opstack.length == 0 || opstack[opstack.length-1] == "("){
        opstack.add(infixStack[i]);
      } else if (GetOpPrecedence(opstack[opstack.length-1]) >= GetOpPrecedence(infixStack[i])){
        while (opstack.length > 0 && GetOpPrecedence(opstack[opstack.length-1]) >= GetOpPrecedence(infixStack[i])){
          stack.add(opstack.removeLast());
        }
        opstack.add(infixStack[i]);
      } else if (GetOpPrecedence(opstack[opstack.length-1]) < GetOpPrecedence(infixStack[i])){
        opstack.add(infixStack[i]);
      }
    }
    print("${infixStack[i]} : $opstack : $stack");
  }
  for (var j = opstack.length-1; j >= 0; j--){
    stack.add(opstack.removeLast());
    print("_ : $opstack : $stack");
  }
  return stack;
}

VariablePolynom SimplifyPostfix(List<String> postfixStack){
  List<VariablePolynom> stack = new List<VariablePolynom>();
  for (var i = 0; i < postfixStack.length; i++){
    VariablePolynom value;
    try{
      VariablePolynom vp = new VariablePolynom();
      double val = num.parse(postfixStack[i]);
      vp.variables.add(new Variable(val, 0.0));
      stack.add(vp);
    } catch (e){
      try{
        if (postfixStack[i].contains(new RegExp("[A-Za-z]"))){
          VariablePolynom vp = new VariablePolynom();
          String toParse = postfixStack[i].replaceAll(new RegExp("[A-Za-z]"), "");
          if (toParse.length == 0){
            toParse = "1";
          }
          double val = num.parse(toParse);
          vp.variables.add(new Variable(val, 1.0));
          stack.add(vp);
        }
      } catch (e){
      }
    }
    if (value != null){
      stack.add(value);
    } else if (postfixStack[i] == "+"){
      VariablePolynom last = stack.removeLast();
      stack.add(stack.removeLast()+last);
    } else if (postfixStack[i] == "-"){
      VariablePolynom last = stack.removeLast();
      stack.add(stack.removeLast()-last);
    } else if (postfixStack[i] == "*"){
      VariablePolynom last = stack.removeLast();
      stack.add(stack.removeLast()*last);
    } else if (postfixStack[i] == "**"){
      VariablePolynom last = stack.removeLast();
      VariablePolynom slast = stack.removeLast();
      VariablePolynom res = new VariablePolynom();
      res.variables = new List.from(slast.variables);
      if ((last.variables[0].c).round() == 0){
        res = new VariablePolynom();
        res.variables.add(new Variable(1.0, 0.0));
      } else{
        for (var j = 0; j < (last.variables[0].c-1).round(); j++) {
          res = res * slast;
        }
      }
      stack.add(res);
    } else if (postfixStack[i] == "/"){
      VariablePolynom last = stack.removeLast();
      stack.add(stack.removeLast()/last);
    }
    print("${postfixStack[i]} : $stack");
  }
  VariablePolynom polynom = stack.removeLast();
  for (var i = polynom.variables.length-1; i >= 0; i--){
    if (polynom.variables[i].c == 0){
      polynom.variables.removeAt(i);
    }
  }
  return polynom;
}

VariablePolynom DerivatePolynom(VariablePolynom polynom){
  VariablePolynom pnom = new VariablePolynom.from(polynom);
  for (var i = pnom.variables.length-1; i >= 0; i--){
    if (pnom.variables[i].degree != 0){
      pnom.variables[i] = new Variable(pnom.variables[i].c*pnom.variables[i].degree, pnom.variables[i].degree-1);
    } else{
      pnom.variables.removeAt(i);
    }
  }
  return pnom;
}

List<double> GetPolynomRoots(VariablePolynom polynom){
  List<double> roots = new List<double>();
  VariablePolynom derivate = DerivatePolynom(polynom);
  double NewtonFrom(double r){
    double z = r;
    for (var i = 0; i < 1000; i++){
      z = z-((polynom.Evaluate(z))/(derivate.Evaluate(z)));
    }
    if (!z.isFinite){
      return null;
    }
    return z;
  }
  void GetRootsFromRange(double min, double max, double step){
    for (double r = min; r <= max; r+=step){
      double root = NewtonFrom(r);
      if (root == null) continue;
      bool f = true;
      for (var i = 0; i < roots.length; i++){
        if ((root-roots[i]).abs() < 0.001){
          f = false;
          break;
        }
      }
      if (f){
        if ((root.round()-root).abs() < 0.000001){
          roots.add(root.roundToDouble());
        } else{
          roots.add(root);
        }
      }
    }
  }
  List<int> divisorsNum = NumDivisors(polynom.GetDegreeCoefficient(0).abs().toInt());
  List<double> divisors = new List<double>();
  double highestCoefficient = polynom.GetHighestMonomial().c;
  for (var i = 0; i < divisorsNum.length; i++){
    divisors.add(divisorsNum[i].toDouble()/highestCoefficient);
    divisors.add(-divisorsNum[i].toDouble()/highestCoefficient);
  }
  print("Potential roots: $divisors");
  for (var i = 0; i < divisors.length; i++){
    if (polynom.Evaluate(divisors[i]) == 0){
      roots.add(divisors[i]);
    }
  }
  for (var i = 0; i < divisors.length; i++){
    if (!roots.contains(divisors[i])){
      GetRootsFromRange(divisors[i], divisors[i]+2, 5.0);
    }
  }
  GetRootsFromRange(-10.0, 10.0, 0.1);
  GetRootsFromRange(-10000.0, 10000.0, 100.0);
  for (var i = roots.length-1; i >= 0; i--){
    if (polynom.Evaluate(roots[i]).abs() > 1){
      roots.removeAt(i);
    }
  }
  return roots;
}

void PlotPolynomFunction(VariablePolynom polynom, List<double> roots){
  querySelector("#canvasresult").className = "resultitem";
  CanvasRenderingContext2D ctx = canvas.context2D;
  roots.sort();
  double minX;
  double maxX;
  double minY;
  double maxY;
  if (roots.length > 0){
    minX = roots.first-2.0;
    maxX = roots.last+2.0;
    if (polynom.Evaluate((maxX+minX)/3) > polynom.Evaluate(2*(maxX+minX)/3)){
      maxY = polynom.Evaluate((maxX+minX)/3)+3.0;
      minY = polynom.Evaluate(2*(maxX+minX)/3)-3.0;
    } else{
      minY = polynom.Evaluate((maxX+minX)/3)-3.0;
      maxY = polynom.Evaluate(2*(maxX+minX)/3)+3.0;
    }
    if (polynom.Evaluate((maxX+minX)/2) > maxY) maxY = polynom.Evaluate((maxX+minX)/2)+3.0;
    if (polynom.Evaluate((maxX+minX)/2) < minY) minY = polynom.Evaluate((maxX+minX)/2)-3.0;
  } else{
    minX = -5.0;
    maxX = 5.0;
    if (polynom.Evaluate((maxX+minX)/3) > polynom.Evaluate(2*(maxX+minX)/3)){
      maxY = polynom.Evaluate((maxX+minX)/3)+3.0;
      minY = polynom.Evaluate(2*(maxX+minX)/3)-3.0;
    } else{
      minY = polynom.Evaluate((maxX+minX)/3)-3.0;
      maxY = polynom.Evaluate(2*(maxX+minX)/3)+3.0;
    }
    if (polynom.Evaluate((maxX+minX)/2) > maxY) maxY = polynom.Evaluate((maxX+minX)/2)+3.0;
    if (polynom.Evaluate((maxX+minX)/2) < minY) minY = polynom.Evaluate((maxX+minX)/2)-3.0;
  }
  if (!minY.isFinite) minY = -5.0;
  if (!maxY.isFinite) maxY = 5.0;
  ctx.fillStyle = "#111111";// = "#292929";
  ctx.strokeStyle = "white";
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  double xorigin = MapToRange(0.0, minX, maxX, 0.0, 400.0);
  double yorigin = MapToRange(0.0, minY, maxY, 0.0, 400.0);
  ctx.beginPath();
  ctx.moveTo(0, 400-yorigin);
  ctx.lineTo(400, 400-yorigin);
  ctx.closePath();
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(xorigin, 0);
  ctx.lineTo(xorigin, 400);
  ctx.closePath();
  ctx.stroke();
  ctx.fillStyle = "white";
  ctx.textAlign = "center";
  bool f = true;
  if (yorigin < 10 || yorigin > 400){
    yorigin = 22.0;
    f = false;
  }
  for (var i = minX; i < maxX; i+=(maxX-minX)~/10 > 1 ? (maxX-minX)~/10 : 1){
    if (i <= minX || i >= maxX || i == 0) continue;
    ctx.beginPath();
    ctx.moveTo(MapToRange(i, minX, maxX, 0.0, 400.0), 400-yorigin-5);
    ctx.lineTo(MapToRange(i, minX, maxX, 0.0, 400.0), 400-yorigin+5);
    ctx.fillText("${i.toStringAsFixed(2)}", MapToRange(i, minX, maxX, 0.0, 400.0), 400-yorigin+18);
    ctx.closePath();
    if (f) ctx.stroke();
  }
  f = true;
  if (xorigin < 10 || xorigin > 400){
    yorigin = 30.0;
    f = false;
  }
  for (var i = minY; i < maxY; i+=(maxY-minY)~/10 > 1 ? (maxY-minY)~/10 : 1){
    if (i <= minY || i >= maxY || i == 0) continue;
    ctx.beginPath();
    ctx.moveTo(xorigin-5, 400-MapToRange(i, minY, maxY, 0.0, 400.0));
    ctx.lineTo(xorigin+5, 400-MapToRange(i, minY, maxY, 0.0, 400.0));
    ctx.fillText("${i.toStringAsFixed(2)}", xorigin-20, 400-MapToRange(i, minY, maxY, 0.0, 400.0)+4);
    ctx.closePath();
    if (f) ctx.stroke();
  }
  ctx.fillStyle = "#818181";
  double lastY;
  for (var i = 0; i <= 400; i++){
    double x = MapToRange(i.toDouble(), 0.0, 400.0, minX, maxX);
    double y = polynom.Evaluate(x);
    if (lastY == null){
      lastY = y;
      continue;
    }
    ctx.beginPath();
    ctx.moveTo(i-1, 400-MapToRange(lastY, minY, maxY, 0.0, 400.0));
    ctx.lineTo(i, 400-MapToRange(y, minY, maxY, 0.0, 400.0));
    ctx.closePath();
    ctx.stroke();
    lastY = y;
  }
}

double GetPostfixValue(List<String> postfixStack){
  Queue<num> stack = new Queue<num>();
  for (var i = 0; i < postfixStack.length; i++){
    num value;
    try{
      value = num.parse(postfixStack[i]);
    } catch (e){
    }
    if (value != null){
      stack.add(value);
    } else if (postfixStack[i] == "+"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()+last);
    } else if (postfixStack[i] == "-"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()-last);
    } else if (postfixStack[i] == "*"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()*last);
    } else if (postfixStack[i] == "**"){
      double last = stack.removeLast();
      stack.add(pow(stack.removeLast(), last));
    } else if (postfixStack[i] == "/"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()/last);
    } else if (postfixStack[i] == "%"){
      double last = stack.removeLast();
      stack.add(stack.removeLast()%last);
    } else if (postfixStack[i] == "!"){
      double fact(double val){
        double res = 1.0;
        for (var i = 2; i < val.round().abs(); i++) {
          res *= i;
        }
        return res;
        //TODO: Gamma function.
      }
      stack.add(fact(stack.removeLast()));
    } else if (postfixStack[i] == "sin"){
      stack.add(sin(stack.removeLast()));
    } else if (postfixStack[i] == "cos"){
      stack.add(cos(stack.removeLast()));
    } else if (postfixStack[i] == "tan"){
      stack.add(tan(stack.removeLast()));
    } else if (postfixStack[i] == "sqrt"){
      stack.add(sqrt(stack.removeLast()));
    } else if (postfixStack[i] == "ln"){
      stack.add(log(stack.removeLast()));
    } else if (postfixStack[i] == "log"){
      stack.add(log(stack.removeLast())/log(10));
    } else if (postfixStack[i] == "abs"){
      double last = stack.removeLast();
      if (last > 0){
        stack.add(last);
      } else{
        stack.add(-last);
      }
    } else if (postfixStack[i] == "sign"){
      double last = stack.removeLast();
      if (last > 0){
        stack.add(1);
      } else if (last < 0){
        stack.add(-1);
      } else{
        stack.add(0);
      }
    } else if (postfixStack[i] == "floor"){
      stack.add((stack.removeLast()).floorToDouble());
    } else if (postfixStack[i] == "ceil"){
      stack.add((stack.removeLast()).ceilToDouble());
    } else if (postfixStack[i] == "round"){
      stack.add((stack.removeLast()).roundToDouble());
    }
    print("${postfixStack[i]} : $stack");
  }
  return stack.removeLast().toDouble();
}

int GetOpPrecedence(String op){
  if (op == "+"){
    return 1;
  } else if (op == "-"){
    return 1;
  } else if (op == "*"){
    return 2;
  } else if (op == "/"){
    return 2;
  } else if (op == "%"){
    return 2;
  } else if (op == "**"){
    return 3;
  } else if (op == "("){
    return 0;
  } 
  return 4;
}
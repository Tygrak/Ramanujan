import 'dart:html';
import 'dart:math';
import 'dart:collection';
import 'Variable.dart';
import 'Complex.dart';
import 'mathExtensions.dart';

ButtonElement button;
CanvasElement canvas;
double eMinX;
double eMinY;
double eMaxX;
double eMaxY;

var stream;

void main(){
  button = querySelector("#calculatebutton");
  canvas = querySelector("#canvas");
  print(canvas.className);
  button.addEventListener("click", ButtonClicked);
  if (Uri.base.queryParameters['minx'] != "" && Uri.base.queryParameters['minx'] != null){
    print("MinX: ${Uri.base.queryParameters['minx']}");
    eMinX = num.parse(Uri.base.queryParameters['minx']);
  }
  if (Uri.base.queryParameters['miny'] != "" && Uri.base.queryParameters['miny'] != null){
    print("MinY: ${Uri.base.queryParameters['miny']}");
    eMinY = num.parse(Uri.base.queryParameters['miny']);
  }
  if (Uri.base.queryParameters['maxx'] != "" && Uri.base.queryParameters['maxx'] != null){
    print("MaxX: ${Uri.base.queryParameters['maxx']}");
    eMaxX = num.parse(Uri.base.queryParameters['maxx']);
  }
  if (Uri.base.queryParameters['maxy'] != "" && Uri.base.queryParameters['maxy'] != null){
    print("MaxY: ${Uri.base.queryParameters['maxy']}");
    eMaxY = num.parse(Uri.base.queryParameters['maxy']);
  }
  if (Uri.base.queryParameters['q'] != "" && Uri.base.queryParameters['q'] != null){
    print("Equation from url: ${Uri.base.queryParameters['q']}");
    InputElement element = querySelector("[name=equation]");
    element.value = Uri.base.queryParameters['q'].replaceAll("|43", "+");
    ButtonClicked("e");
  }
  window.onKeyDown.listen((KeyboardEvent ke){
    if (ke.keyCode == KeyCode.ENTER) {
      ButtonClicked("e");       
    }   
  });
}

void ButtonClicked(e){
  PageClearResult();
  InputElement element = querySelector("[name=equation]");
  String equation = element.value;
  if (equation.toLowerCase().startsWith("xfrom ") || equation.toLowerCase().startsWith("minx ")){
    List<String> parts = equation.toLowerCase().split(" ");
    eMinX = null;
    eMaxX = null;
    for (var i = 0; i < parts.length; i++){
      double val = num.parse(parts[i], (String s) => null);
      print("${parts[i]} : $val");
      if (val != null){
        if (eMinX == null) eMinX = val;
        else if (eMaxX == null) eMaxX = val;
        else break;
      }
    }
    print("MinX set to $eMinX, maxX set to $eMaxX");
    PageAddResult("Result", "MinX set to $eMinX, maxX set to $eMaxX.");
    return;
  } else if (equation.toLowerCase().startsWith("yfrom ") || equation.toLowerCase().startsWith("miny ")){
    List<String> parts = equation.toLowerCase().split(" ");
    eMinY = null;
    eMaxY = null;
    for (var i = 0; i < parts.length; i++){
      double val = num.parse(parts[i], (String s) => null);
      print("${parts[i]} : $val");
      if (val != null){
        if (eMinY == null) eMinY = val;
        else if (eMaxY == null) eMaxY = val;
        else break;
      }
    }
    print("MinY set to $eMinY, maxY set to $eMaxY");
    PageAddResult("Result", "MinY set to $eMinY, maxY set to $eMaxY.");
    return;
  }
  List<String> infixStack = ParseEquation(equation);
  print("$infixStack");
  List<String> postfixStack = InfixToPostfix(infixStack);
  print("----------");
  try{
    Complex expressionValue = GetComplexPostfixValue(postfixStack);
    print("$infixStack -> $postfixStack -> $expressionValue");
    PageAddResult("Result", "$expressionValue");
  } catch (e){
    try{
      double expressionValue = GetPostfixValue(postfixStack);
      print("$infixStack -> $postfixStack -> $expressionValue");
      PageAddResult("Result", "$expressionValue");
    } catch (e){
      try{
        VariablePolynom vp = SimplifyPostfix(postfixStack);
        VariablePolynom deriv = DerivatePolynom(vp);
        VariablePolynom deriv2 = DerivatePolynom(deriv);
        List<double> roots = GetPolynomRoots(vp);
        print("$infixStack -> $postfixStack -> $vp -> $deriv -> $deriv2");
        PlotPolynomFunction(vp);
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
      } catch (e){
        if (e.toString() != "UnsupportedError") print(e);
        List<double> roots = GetSecantRoots(postfixStack);
        PlotFunction(postfixStack);
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
      }
    }
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
    } else if (equation.length > i+5 && equation.substring(i, i+6) == "arcsin"){
      AddNumberToStack();
      stack.add("arcsin");
      i += 5;
    } else if (equation.length > i+7 && equation.substring(i, i+8) == "arccosec"){
      AddNumberToStack();
      stack.add("arccosec");
      i += 7;
    } else if (equation.length > i+5 && equation.substring(i, i+6) == "arccos"){
      AddNumberToStack();
      stack.add("arccos");
      i += 5;
    } else if (equation.length > i+5 && equation.substring(i, i+6) == "arctan"){
      AddNumberToStack();
      stack.add("arctan");
      i += 5;
    } else if (equation.length > i+7 && equation.substring(i, i+8) == "arccotan"){
      AddNumberToStack();
      stack.add("arccotan");
      i += 7;
    } else if (equation.length > i+5 && equation.substring(i, i+6) == "arcsec"){
      AddNumberToStack();
      stack.add("arcsec");
      i += 5;
    } else if (equation.length > i+3 && equation.substring(i, i+4) == "sinh"){
      AddNumberToStack();
      stack.add("sinh");
      i += 3;
    } else if (equation.length > i+3 && equation.substring(i, i+4) == "cosh"){
      AddNumberToStack();
      stack.add("cosh");
      i += 3;
    } else if (equation.length > i+3 && equation.substring(i, i+4) == "tanh"){
      AddNumberToStack();
      stack.add("tanh");
      i += 3;
    } else if (equation.length > i+5 && equation.substring(i, i+6) == "cotanh"){
      AddNumberToStack();
      stack.add("cotanh");
      i += 5;
    } else if (equation.length > i+3 && equation.substring(i, i+4) == "coth"){
      AddNumberToStack();
      stack.add("cotanh");
      i += 3;
    } else if (equation.length > i+3 && equation.substring(i, i+4) == "sech"){
      AddNumberToStack();
      stack.add("sech");
      i += 3;
    } else if (equation.length > i+5 && equation.substring(i, i+6) == "cosech"){
      AddNumberToStack();
      stack.add("cosech");
      i += 5;
    } else if (equation.length > i+3 && equation.substring(i, i+4) == "csch"){
      AddNumberToStack();
      stack.add("cosech");
      i += 3;
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "sin"){
      AddNumberToStack();
      stack.add("sin");
      i += 2;
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "cos" && !(equation.length > i+4 && equation.substring(i, i+5) == "cosec")){
      AddNumberToStack();
      stack.add("cos");
      i += 2;
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "tan"){
      AddNumberToStack();
      stack.add("tan");
      i += 2;
    } else if ((equation.length > i+4 && equation.substring(i, i+5) == "cotan")){
      AddNumberToStack();
      stack.add("cotan");
      i += 4;
    } else if ((equation.length > i+2 && equation.substring(i, i+3) == "cot")){
      AddNumberToStack();
      stack.add("cotan");
      i += 2;
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "sec"){
      AddNumberToStack();
      stack.add("sec");
      i += 2;
    } else if ((equation.length > i+4 && equation.substring(i, i+5) == "cosec")){
      AddNumberToStack();
      stack.add("cosec");
      i += 4;
    } else if ((equation.length > i+2 && equation.substring(i, i+3) == "csc")){
      AddNumberToStack();
      stack.add("cosec");
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
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "abs"){
      AddNumberToStack();
      stack.add("abs");
      i += 2;
    } else if (equation.length > i+3 && equation.substring(i, i+4) == "sign"){
      AddNumberToStack();
      stack.add("sign");
      i += 3;
    } else if (equation.length > i+4 && equation.substring(i, i+5) == "round"){
      AddNumberToStack();
      stack.add("round");
      i += 4;
    } else if (equation.length > i+4 && equation.substring(i, i+5) == "floor"){
      AddNumberToStack();
      stack.add("floor");
      i += 4;
    } else if (equation.length > i+3 && equation.substring(i, i+4) == "ceil"){
      AddNumberToStack();
      stack.add("ceil");
      i += 3;
    } else if (equation[i].contains(new RegExp("[0-9.]"))){
      number += equation[i];
    } else if (equation[i] == "i"){
      if (number == "-"){
        number += "i";
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = "i";
      } else{
        number = "i";
      }
      AddNumberToStack();
    } else{
      if (number == "-"){
        number += "x";
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = "x";
      } else{
        number = "x";
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
      value = vp;
    } catch (e){
      try{
        if (postfixStack[i].contains(new RegExp("[A-Za-z]")) && postfixStack[i].length == 1){
          VariablePolynom vp = new VariablePolynom();
          String toParse = postfixStack[i].replaceAll(new RegExp("[A-Za-z]"), "");
          if (toParse.length == 0){
            toParse = "1";
          }
          double val = num.parse(toParse);
          vp.variables.add(new Variable(val, 1.0));
          stack.add(vp);
          value = vp;
        }
      } catch (e){
      }
    }
    if (value != null){
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
    } else{
      print(postfixStack[i]);
      throw UnsupportedError;
    }
    print("${postfixStack[i]} : $stack");
  }
  VariablePolynom polynom = stack.removeLast();
  for (var i = polynom.variables.length-1; i >= 0; i--){
    if (polynom.variables[i].c == 0 && polynom.variables.length > 1){
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
  double highestCoefficient = polynom.GetHighestMonomial() == null ? 1.0 : polynom.GetHighestMonomial().c;
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
    if (!divisors.contains(roots[i]) && polynom.Evaluate(roots[i]).abs() > 0.6){
      roots.removeAt(i);
    }
  }
  return roots;
}

List<double> GetSecantRoots(List<String> postfixStack){
  List<double> roots = new List<double>();
  double SecantFrom(double r){
    double z = r;
    double lastz = r+0.1;
    for (var i = 0; i < 1000; i++){
      //x(i) = x(i-1) - (f(x(i-1)))*((x(i-1) - x(i-2))/(f(x(i-1)) - f(x(i-2))));
      double tmp = z;
      double fz = EvaluateFuncAt(postfixStack, z);
      double flastz = EvaluateFuncAt(postfixStack, lastz);
      if (fz - flastz == 0){
        
        break;
      }
      z = z-(fz)*((z-lastz)/(fz - flastz));
      lastz = tmp;
    }
    if (!z.isFinite){
      return null;
    }
    return z;
  }
  void GetRootsFromRange(double min, double max, double step){
    for (double r = min; r <= max; r+=step){
      double root = SecantFrom(r);
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
  GetRootsFromRange(-10.0, 10.0, 1.0);
  for (var i = roots.length-1; i >= 0; i--){
    if (EvaluateFuncAt(postfixStack, roots[i]).abs() > 0.01){
      roots.removeAt(i);
    }
  }
  for (var i = roots.length-1; i >= 0; i--){
    if (roots[i] != -roots[i] && EvaluateFuncAt(postfixStack, -roots[i]).abs() < 0.000001 && !roots.contains(-roots[i])){
      roots.add(-roots[i]);
    }
  }
  return roots;
}

void PlotPolynomFunction(VariablePolynom polynom){
  querySelector("#canvasresult").className = "resultitem";
  CanvasRenderingContext2D ctx = canvas.context2D;
  VariablePolynom derivate = DerivatePolynom(polynom);
  List<double> roots = GetPolynomRoots(derivate);
  roots.sort();
  double minX;
  double maxX;
  double minY;
  double maxY;
  if (eMinX != null){
    minX = eMinX;
    maxX = eMaxX;
  } else if (roots.length > 1){
    minX = roots.first-2.0;
    maxX = roots.last+2.0;
  } else if (roots.length == 1){
    minX = roots.first-5.0;
    maxX = roots.first+5.0;
  } else{
    minX = -5.0;
    maxX = 5.0;
  }
  maxY = polynom.Evaluate(minX+2.0)+3.0;
  minY = polynom.Evaluate(maxX-2.0)-3.0;
  if (minY > maxY){
    double tmp = minY;
    minY = maxY;
    maxY = tmp;
  }
  if (maxY < polynom.Evaluate((minX+maxX)/2)){
    maxY = polynom.Evaluate((minX+maxX)/2) + 3.0;
  }
  if (minY > polynom.Evaluate((minX+maxX)/2)){
    minY = polynom.Evaluate((minX+maxX)/2) - 3.0;
  }
  if (eMinY != null){
    minY = eMinY;
    maxY = eMaxY;
  }
  if ((minY.roundToDouble()-minY).abs() < 0.011){
    minY = minY.roundToDouble();
  }
  if ((maxY.roundToDouble()-maxY).abs() < 0.011){
    maxY = maxY.roundToDouble();
  }
  if (minY == maxY){
    minY = -5.0;
    maxY = 5.0;
  }
  print("minX:$minX, maxX:$maxX > ${polynom.Evaluate(minX+2.0)} : ${polynom.Evaluate(maxX-2.0)} > minY:$minY, maxY:$maxY");
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
  for (var i = minX; i < maxX; i+=(maxX-minX)/10 > 0.1 ? (maxX-minX)/10 : 0.1){
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
    xorigin = 40.0;
    f = false;
  }
  for (var i = minY; i < maxY; i+=(maxY-minY)/10 > 0.1 ? (maxY-minY)/10 : 0.1){
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

double EvaluateFuncAt(List<String> postfixStack, double x){
  List<String> stack = new List.from(postfixStack);
  for (var i = 0; i < stack.length; i++) {
    if (stack[i] == "x"){
      stack[i] = x.toString();
    }
  }
  return GetPostfixValue(stack);
}

void PlotFunction(List<String> postfixStack){
  querySelector("#canvasresult").className = "resultitem";
  CanvasRenderingContext2D ctx = canvas.context2D;
  double minX;
  double maxX;
  double minY;
  double maxY;
  if (eMinX != null){
    minX = eMinX;
    maxX = eMaxX;
  } else{
    minX = -10.0;
    maxX = 10.0;
  }
  if (!EvaluateFuncAt(postfixStack, minX).isFinite){
    minX = -1.0;
  }
  if (!EvaluateFuncAt(postfixStack, maxX).isFinite){
    maxX = pi-0.000001;
  }
  maxY = EvaluateFuncAt(postfixStack, minX+2.0)+3.0;
  minY = EvaluateFuncAt(postfixStack, maxX-2.0)-3.0;
  if (minY > maxY){
    double tmp = minY;
    minY = maxY;
    maxY = tmp;
  }
  if (maxY < EvaluateFuncAt(postfixStack, (minX+maxX)/2)){
    maxY = EvaluateFuncAt(postfixStack, (minX+maxX)/2) + 3.0;
  }
  if (minY > EvaluateFuncAt(postfixStack, (minX+maxX)/2)){
    minY = EvaluateFuncAt(postfixStack, (minX+maxX)/2) - 3.0;
  }
  if (eMinY != null){
    minY = eMinY;
    maxY = eMaxY;
  }
  if (minY > maxY){
    double tmp = minY;
    minY = maxY;
    maxY = tmp;
  }
  if ((minY.roundToDouble()-minY).abs() < 0.011){
    minY = minY.roundToDouble();
  }
  if ((maxY.roundToDouble()-maxY).abs() < 0.011){
    maxY = maxY.roundToDouble();
  }
  if (!minY.isFinite){
    minY = maxY > 0 ? -maxY : maxY*2;
  }
  if (!maxY.isFinite){
    maxY = minY < 0 ? minY.abs() : minY*2;
  }
  print("minX:$minX, maxX:$maxX > ${EvaluateFuncAt(postfixStack, minX+2.0)} : ${EvaluateFuncAt(postfixStack, maxX-2.0)} > minY:$minY, maxY:$maxY");
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
  for (var i = minX; i < maxX; i+=(maxX-minX)/10 > 0.1 ? (maxX-minX)/10 : 0.1){
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
    xorigin = 40.0;
    f = false;
  }
  for (var i = minY; i < maxY; i+=(maxY-minY)/10 > 0.1 ? (maxY-minY)/10 : 0.1){
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
    double y = EvaluateFuncAt(postfixStack, x);
    if (lastY == null || !y.isFinite){
      lastY = y;
      continue;
    }
    ctx.beginPath();
    if (!lastY.isFinite){
      ctx.moveTo(i-1, 400-MapToRange(y, minY, maxY, 0.0, 400.0));
    } else{
      ctx.moveTo(i-1, 400-MapToRange(lastY, minY, maxY, 0.0, 400.0));
    }
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
      stack.add(Fact(stack.removeLast()));
    } else if (postfixStack[i] == "sin"){
      stack.add(sin(stack.removeLast()));
    } else if (postfixStack[i] == "cos"){
      stack.add(cos(stack.removeLast()));
    } else if (postfixStack[i] == "tan"){
      stack.add(tan(stack.removeLast()));
    } else if (postfixStack[i] == "cotan"){
      stack.add(cotan(stack.removeLast()));
    } else if (postfixStack[i] == "sec"){
      stack.add(sec(stack.removeLast()));
    } else if (postfixStack[i] == "cosec"){
      stack.add(cosec(stack.removeLast()));
    } else if (postfixStack[i] == "sinh"){
      stack.add(sinh(stack.removeLast()));
    } else if (postfixStack[i] == "cosh"){
      stack.add(cosh(stack.removeLast()));
    } else if (postfixStack[i] == "tanh"){
      stack.add(tanh(stack.removeLast()));
    } else if (postfixStack[i] == "cotanh"){
      stack.add(cotanh(stack.removeLast()));
    } else if (postfixStack[i] == "sech"){
      stack.add(sech(stack.removeLast()));
    } else if (postfixStack[i] == "cosech"){
      stack.add(cosech(stack.removeLast()));
    } else if (postfixStack[i] == "arcsin"){
      stack.add(arcsin(stack.removeLast()));
    } else if (postfixStack[i] == "arccos"){
      stack.add(arccos(stack.removeLast()));
    } else if (postfixStack[i] == "arctan"){
      stack.add(arctan(stack.removeLast()));
    } else if (postfixStack[i] == "arccotan"){
      stack.add(arccotan(stack.removeLast()));
    } else if (postfixStack[i] == "arcsec"){
      stack.add(arcsec(stack.removeLast()));
    } else if (postfixStack[i] == "arccosec"){
      stack.add(arccosec(stack.removeLast()));
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
    //print("${postfixStack[i]} : $stack");
  }
  return stack.removeLast().toDouble();
}

Complex GetComplexPostfixValue(List<String> postfixStack){
  Queue<Complex> stack = new Queue<Complex>();
  for (var i = 0; i < postfixStack.length; i++){
    Complex value;
    try{
      value = new Complex(num.parse(postfixStack[i]), 0.0);
    } catch (e){
    }
    if (value != null){
      stack.add(value);
    } else if (postfixStack[i] == "i"){
      stack.add(new Complex(0.0, 1.0));
    } else if (postfixStack[i] == "+"){
      Complex last = stack.removeLast();
      stack.add(stack.removeLast()+last);
    } else if (postfixStack[i] == "-"){
      Complex last = stack.removeLast();
      stack.add(stack.removeLast()-last);
    } else if (postfixStack[i] == "*"){
      Complex last = stack.removeLast();
      stack.add(stack.removeLast()*last);
    } else if (postfixStack[i] == "**"){
      Complex last = stack.removeLast();
      stack.add(Pow(stack.removeLast(), last));
    } else if (postfixStack[i] == "/"){
      Complex last = stack.removeLast();
      stack.add(stack.removeLast()/last);
    } /* else if (postfixStack[i] == "%"){
      Complex last = stack.removeLast();
      stack.add(stack.removeLast()%last);
    } else if (postfixStack[i] == "!"){
      stack.add(Fact(stack.removeLast()));
    }*/ else if (postfixStack[i] == "sin"){
      stack.add(stack.removeLast().sin());
    } else if (postfixStack[i] == "cos"){
      stack.add(stack.removeLast().cos());
    } else if (postfixStack[i] == "tan"){
      Complex c = stack.removeLast();
      stack.add(c.sin()/c.cos());
    } else if (postfixStack[i] == "cotan"){
      Complex c = stack.removeLast();
      stack.add(c.cos()/c.sin());
    } else if (postfixStack[i] == "sec"){
      stack.add(new Complex.from(1.0)/stack.removeLast().cos());
    } else if (postfixStack[i] == "cosec"){
      stack.add(new Complex.from(1.0)/stack.removeLast().sin());
    } /*else if (postfixStack[i] == "sinh"){
      stack.add(sinh(stack.removeLast()));
    } else if (postfixStack[i] == "cosh"){
      stack.add(cosh(stack.removeLast()));
    } else if (postfixStack[i] == "tanh"){
      stack.add(tanh(stack.removeLast()));
    } else if (postfixStack[i] == "cotanh"){
      stack.add(cotanh(stack.removeLast()));
    } else if (postfixStack[i] == "sech"){
      stack.add(sech(stack.removeLast()));
    } else if (postfixStack[i] == "cosech"){
      stack.add(cosech(stack.removeLast()));
    } else if (postfixStack[i] == "arcsin"){
      stack.add(arcsin(stack.removeLast()));
    } else if (postfixStack[i] == "arccos"){
      stack.add(arccos(stack.removeLast()));
    } else if (postfixStack[i] == "arctan"){
      stack.add(arctan(stack.removeLast()));
    } else if (postfixStack[i] == "arccotan"){
      stack.add(arccotan(stack.removeLast()));
    } else if (postfixStack[i] == "arcsec"){
      stack.add(arcsec(stack.removeLast()));
    } else if (postfixStack[i] == "arccosec"){
      stack.add(arccosec(stack.removeLast()));
    }*/ else if (postfixStack[i] == "sqrt"){
      stack.add(Pow(stack.removeLast(), new Complex.from(1/2)));
    } else if (postfixStack[i] == "ln"){
      stack.add(Log(stack.removeLast()));
    } else if (postfixStack[i] == "log"){
      stack.add(Log(stack.removeLast())/Log(new Complex.from(10.0)));
    } /*else if (postfixStack[i] == "abs"){
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
    }*/ else{
      throw UnimplementedError;
    }
    //print("${postfixStack[i]} : $stack");
  }
  if (stack.length > 1){
    throw Error;
  }
  return stack.removeLast();
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
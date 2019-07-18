import 'dart:html';
import 'dart:math';
import 'dart:collection';
import 'Variable.dart';
import 'Complex.dart';
import 'mathExtensions.dart';

ButtonElement button;
CanvasElement canvas;
ButtonElement degreemodebutton;
double eMinX;
double eMinY;
double eMaxX;
double eMaxY;
List<int> primes;
int highestPrecalculatedPrime;
double lastMinX;
double lastMinY;
double lastMaxX;
double lastMaxY;

var stream;

void main(){
  button = querySelector("#calculatebutton");
  canvas = querySelector("#canvas");
  canvas.onClick.listen(CanvasClicked);
  button.addEventListener("click", ButtonClicked);
  ButtonElement linkbutton = querySelector("#createlinkbutton");
  linkbutton.addEventListener("click", (e) {CreateLink();});
  ButtonElement sidemenubutton = querySelector("#sidemenubutton");
  sidemenubutton.addEventListener("click", (e) {
    sidemenubutton.innerHtml = sidemenubutton.innerHtml == "x" ? "" : "x";
    Element menu = querySelector("#sidemenu");
    menu.classes.toggle("sidemenu-open");}
  );
  ButtonElement enableplottingbutton = querySelector("#plotenabledbutton");
  enableplottingbutton.addEventListener("click", (e) {
    Element menu = querySelector("#plotoptions");
    menu.classes.toggle("hidden");}
  );
  degreemodebutton = querySelector("#degreemodebutton");
  ButtonElement summodebutton = querySelector("#summodebutton");
  summodebutton.addEventListener("click", (e) {
    Element menu = querySelector("#summodeoptions");
    menu.classes.toggle("hidden");}
  );
  ButtonElement setplotrangebutton = querySelector("#setplotrangebutton");
  setplotrangebutton.addEventListener("click", SetPlotRangeButtonClicked);
  print("Precalculating primes to 625");
  primes = PrimesTo(625);
  highestPrecalculatedPrime = 625;
  LoadLinkParametres();
  window.onKeyDown.listen((KeyboardEvent ke){
    if (ke.keyCode == KeyCode.ENTER){
      ButtonClicked("e");       
    } else if (ke.keyCode == KeyCode.F1){
      Element menu = querySelector("#sidemenu");
      menu.classes.toggle("sidemenu-open");
    } else if (ke.keyCode == KeyCode.F2){
      CreateLink();
    }
  });
}

void ButtonClicked(e){
  PageClearResults();
  InputElement element = querySelector("[name=equation]");
  String equation = element.value;
  List<String> infixStack = ParseEquation(equation);
  print("$infixStack");
  List<String> postfixStack = InfixToPostfix(infixStack);
  print("----------");
  ButtonElement complexModeButton = querySelector("#complexmodebutton");
  try{
    if (!complexModeButton.classes.contains("button-active")){
      throw Exception;
    }
    Complex expressionValue = GetComplexPostfixValue(postfixStack);
    print("$infixStack -> $postfixStack -> $expressionValue");
    if ((expressionValue.r.round()-expressionValue.r).abs() < 0.000005){
      expressionValue = new Complex(expressionValue.r.roundToDouble(), expressionValue.i);
    }
    if ((expressionValue.i.round()-expressionValue.i).abs() < 0.000005){
      expressionValue = new Complex(expressionValue.r, expressionValue.i.roundToDouble());
    }
    PageAddResult("Result", "$expressionValue");
  } catch (e){
    try{
      double expressionValue = GetPostfixValue(postfixStack);
      print("$infixStack -> $postfixStack -> $expressionValue");
      if ((expressionValue.round()-expressionValue).abs() < 0.00000005){
        expressionValue = expressionValue.roundToDouble();
      }
      PageAddResult("Result", "$expressionValue");
    } catch (e){
      try{
        VariablePolynom vp = SimplifyPostfix(postfixStack);
        VariablePolynom deriv = DerivatePolynom(vp);
        VariablePolynom deriv2 = DerivatePolynom(deriv);
        List<double> roots = GetPolynomRoots(vp);
        List<Complex> complexRoots;
        if ((roots.length < vp.GetHighestMonomial().degree.round() || vp.GetLowestMonomial().degree < 1) && complexModeButton.classes.contains("button-active")){
          complexRoots = GetPolynomComplexRoots(vp);
        }
        print("$infixStack -> $postfixStack -> $vp -> $deriv -> $deriv2");
        ButtonElement plotButton = querySelector("#plotenabledbutton");
        if (plotButton.classes.contains("button-active")){
          PlotPolynomFunction(vp);
        }
        String rootsHtml = "";
        if (complexModeButton.classes.contains("button-active") && complexRoots != null){
          for (var i = 0; i < complexRoots.length; i++){
            Complex val = complexRoots[i];
            if (rootsHtml != "") rootsHtml += "<br>";
            if ((complexRoots[i].i-complexRoots[i].i.roundToDouble()).abs() < 0.00000001){
              val = new Complex(val.r, complexRoots[i].i.roundToDouble());
            }
            if ((complexRoots[i].r-complexRoots[i].r.roundToDouble()).abs() < 0.00000001){
              val = new Complex(complexRoots[i].r.roundToDouble(), val.i);
            }
            rootsHtml += "${val}";
            print("complex root : ${val}");
          }
          if (complexRoots.length == 0){
            //PageAddResult("Complex roots", "No roots found.");
          } else if (complexRoots.length == 1){
            PageAddResult("Complex root", "${rootsHtml}");
          } else{
            PageAddResult("Complex roots", "${rootsHtml}");
          }
        }
        rootsHtml = "";
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
        ButtonElement plotButton = querySelector("#plotenabledbutton");
        if (plotButton.classes.contains("button-active")){
          PlotFunction(postfixStack);
        }
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

void LoadLinkParametres(){
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
  if (Uri.base.queryParameters['complex'] == "0"){
    ButtonElement complexmodebutton = querySelector("#complexmodebutton");
    complexmodebutton.classes.remove("button-active");
  }
  if (Uri.base.queryParameters['plot'] == "0"){
    ButtonElement plotenabledbutton = querySelector("#plotenabledbutton");
    plotenabledbutton.classes.remove("button-active");
    Element menu = querySelector("#plotoptions");
    menu.classes.add("hidden");
  }
  if (Uri.base.queryParameters['mdegree'] == "1"){
    ButtonElement degreemodebutton = querySelector("#degreemodebutton");
    degreemodebutton.classes.add("button-active");
  }
  if (Uri.base.queryParameters['sum'] == "1"){
    ButtonElement summodebutton = querySelector("#summodebutton");
    summodebutton.classes.add("button-active");
    Element menu = querySelector("#summodeoptions");
    menu.classes.remove("hidden");
  }
  if (Uri.base.queryParameters['summin'] != "" && Uri.base.queryParameters['summin'] != null){
    print("SumMin: ${Uri.base.queryParameters['summin']}");
    InputElement input = querySelector("[name=nfrom]");
    input.value = num.parse(Uri.base.queryParameters['summin']).toString();
  }
  if (Uri.base.queryParameters['summax'] != "" && Uri.base.queryParameters['summax'] != null){
    print("SumMax: ${Uri.base.queryParameters['summax']}");
    InputElement input = querySelector("[name=nto]");
    input.value = num.parse(Uri.base.queryParameters['summax']).toString();
  }
  if (Uri.base.queryParameters['menu'] == "1"){
    ButtonElement sidemenubutton = querySelector("#sidemenubutton");
    sidemenubutton.innerHtml = "x";
    sidemenubutton.classes.add("button-active");
    Element menu = querySelector("#sidemenu");
    menu.classes.toggle("sidemenu-open");
  }
  if (Uri.base.queryParameters['q'] != "" && Uri.base.queryParameters['q'] != null){
    print("Equation from url: ${Uri.base.queryParameters['q']}");
    InputElement element = querySelector("[name=equation]");
    element.value = Uri.base.queryParameters['q'].replaceAll("|43", "+");
    ButtonClicked("e");
  }
}

void CreateLink(){
  Element results = querySelector("#resultitems");
  if (!results.innerHtml.contains("Equation Link")){
    InputElement element = querySelector("[name=equation]");
    String link = "http://ramanujan.wz.cz/?q=" + element.value.replaceAll("+", "|43");
    if (eMinX != null){
      link += "&minx=$eMinX&maxx=$eMaxX";
    }
    if (eMinY != null){
      link += "&miny=$eMinY&maxy=$eMaxY";
    }
    ButtonElement complexModeButton = querySelector("#complexmodebutton");
    if (!complexModeButton.classes.contains("button-active")){
      link += "&complex=0";
    }
    ButtonElement plotenabledbutton = querySelector("#plotenabledbutton");
    if (!plotenabledbutton.classes.contains("button-active")){
      link += "&plot=0";
    }
    if (degreemodebutton.classes.contains("button-active")){
      link += "&mdegree=1";
    }
    ButtonElement summodebutton = querySelector("#summodebutton");
    if (summodebutton.classes.contains("button-active")){
      link += "&sum=1";
      InputElement input = querySelector("[name=nfrom]");
      link += "&summin=${input.value}";
      input = querySelector("[name=nto]");
      link += "&summax=${input.value}";
    }
    PageAddResult("Equation Link", link);
  } else{
    for (var i = 0; i < results.children.length; i++){
      if (results.children[i].innerHtml.contains("Equation Link")){
        results.children[i].remove();
        CreateLink();
      }
    }
  }
}

void CanvasClicked(e){
  int x = e.client.x - canvas.getBoundingClientRect().left;
  int y = canvas.height- (e.client.y - canvas.getBoundingClientRect().top);
  Element posx = querySelector("#coordx");
  Element posy = querySelector("#coordy");
  posx.innerHtml = MapToRange(x.toDouble(), 0.0, canvas.width.toDouble(), lastMinX, lastMaxX).toStringAsFixed(2);
  posy.innerHtml = MapToRange(y.toDouble(), 0.0, canvas.height.toDouble(), lastMinY, lastMaxY).toStringAsFixed(2);
}

void SetPlotRangeButtonClicked(e){
  InputElement input = querySelector("[name=xfrom]");
  eMinX = num.parse(input.value);
  input = querySelector("[name=xto]");
  eMaxX = num.parse(input.value);
  input = querySelector("[name=yfrom]");
  eMinY = num.parse(input.value);
  input = querySelector("[name=yto]");
  eMaxY = num.parse(input.value);
}

void PageClearResults(){
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
  equation = equation.replaceAll(new RegExp("[	 ]"), "").toLowerCase();
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
        number += pi.toString();
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = pi.toString();
      } else{
        number = pi.toString();
      }
      AddNumberToStack();
      i += 1;
    } else if (equation[i] == "π"){
      if (number == "-"){
        number += pi.toString();
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = pi.toString();
      } else{
        number = pi.toString();
      }
      AddNumberToStack();
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "mod"){
      AddNumberToStack();
      stack.add("mod");
      i += 2;
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "rem"){
      AddNumberToStack();
      stack.add("rem");
      i += 2;
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "exp"){
      AddNumberToStack();
      stack.add("exp");
      i += 2;
    } else if (equation[i] == "e"){
      if (number == "-"){
        number += e.toString();
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = e.toString();
      } else{
        number = e.toString();
      }
      AddNumberToStack();
    } else if (equation[i] == "°"){
      if (number == "-"){
        number += (0.017453292519943295).toString();
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = (0.017453292519943295).toString();
      } else{
        number = (0.017453292519943295).toString();
      }
      AddNumberToStack();
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "phi"){
      if (number == "-"){
        number += (1.61803398874989484820458683436563811772030917980576).toString();
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = (1.61803398874989484820458683436563811772030917980576).toString();
      } else{
        number = (1.61803398874989484820458683436563811772030917980576).toString();
      }
      AddNumberToStack();
      i += 2;
    } else if (equation[i] == "φ" || equation[i] == "Φ" || equation[i] == "ϕ"){
      if (number == "-"){
        number += (1.61803398874989484820458683436563811772030917980576).toString();
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = (1.61803398874989484820458683436563811772030917980576).toString();
      } else{
        number = (1.61803398874989484820458683436563811772030917980576).toString();
      }
      AddNumberToStack();
    } else if (equation[i] == "γ"){
      if (number == "-"){
        number += (0.5772156649015328606065120900824024310421).toString();
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = (0.5772156649015328606065120900824024310421).toString();
      } else{
        number = (0.5772156649015328606065120900824024310421).toString();
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
    } else if ((equation.length > i+4 && equation.substring(i, i+5) == "gamma")){
      AddNumberToStack();
      stack.add("gamma");
      i += 4;
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
    } else if (equation.length > i+7 && equation.substring(i, i+8) == "argument"){
      AddNumberToStack();
      stack.add("arg");
      i += 7;
    } else if (equation.length > i+2 && equation.substring(i, i+3) == "arg"){
      AddNumberToStack();
      stack.add("arg");
      i += 2;
    } else if (equation.length > i+5 && equation.substring(i, i+6) == "choose"){
      AddNumberToStack();
      stack.add("choose");
      i += 5;
    } else if (equation.length > i+4 && equation.substring(i, i+5) == "sigma"){
      AddNumberToStack();
      stack.add("sigma");
      i += 4;
    } else if (equation.length > i+6 && equation.substring(i, i+7) == "divisor"){
      AddNumberToStack();
      stack.add("divisor");
      i += 6;
    } else if (equation.length > i+7 && equation.substring(i, i+8) == "divisors"){
      AddNumberToStack();
      stack.add("divisor");
      i += 7;
    } else if (equation.length > i+6 && equation.substring(i, i+7) == "isprime"){
      AddNumberToStack();
      stack.add("isprime");
      i += 6;
    } else if (equation.length > i+4 && equation.substring(i, i+5) == "prime"){
      AddNumberToStack();
      stack.add("prime");
      i += 4;
    } else if (equation[i].contains(new RegExp("[0-9.]"))){
      number += equation[i];
    } else if (equation[i] == "i"){
      if (number == "-"){
        stack.add("-1");
        stack.add("*");
        number = "i";
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = "i";
      } else{
        number = "i";
      }
      AddNumberToStack();
    } else if (equation[i] == "n"){
      if (number == "-"){
        stack.add("-1");
        stack.add("*");
        number = "n";
      } else if (number.length > 0){
        AddNumberToStack();
        stack.add("*");
        number = "n";
      } else{
        number = "n";
      }
      AddNumberToStack();
    } else{
      if (number == "-"){
        stack.add("-1");
        stack.add("*");
        number = "x";
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
      if (last.GetHighestMonomial().degree > 0 || last.variables[0].c%1 != 0){
        throw UnsupportedError;
      }
      if (last.variables[0].c == 0){
        res = new VariablePolynom();
        res.variables.add(new Variable(1.0, 0.0));
      } else if (last.variables[0].c < 0){
        for (var j = 0; j < (last.variables[0].c.abs()+1).round(); j++) {
          res = res / slast;
        }
      } else{
        for (var j = 0; j < (last.variables[0].c-1).round(); j++) {
          res = res * slast;
        }
      }
      stack.add(res);
    } else if (postfixStack[i] == "/"){
      VariablePolynom last = stack.removeLast();
      VariablePolynom slast = stack.removeLast();
      if (slast.GetHighestMonomial().degree == 0){
        throw UnsupportedError;
      }
      stack.add(slast/last);
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
    if (polynom.Evaluate(roots[i]).abs() > 0.6){
      roots.removeAt(i);
    } else{
      int count = 0;
      for (var j = -5; j < 5; j++){
        if (polynom.Evaluate(roots[i]+j).abs() <= 0.00001){
          count++;
        }
      }
      if (count > 3){
        roots.removeAt(i);
      }
    }
  }
  return roots;
}

List<Complex> GetPolynomComplexRoots(VariablePolynom polynom){
  List<Complex> roots = new List<Complex>();
  VariablePolynom derivate = DerivatePolynom(polynom);
  Complex NewtonFrom(Complex c){
    Complex z = c;
    for (var i = 0; i < 400; i++){
      //print("$z -> ${polynom.ComplexEvaluate(z)}/${derivate.ComplexEvaluate(z)}");
      z = z-((polynom.ComplexEvaluate(z))/(derivate.ComplexEvaluate(z)));
    }
    if (!z.isFinite){
      return null;
    }
    //print("potential root: ${c} -> $z -> ${polynom.ComplexEvaluate(z)}");
    return z;
  }
  void GetRootsFromRange(double i, double min, double max, double step){
    for (double r = min; r <= max; r+=step){
      Complex root = NewtonFrom(new Complex(r, i));
      if (root == null) continue;
      bool f = true;
      for (var i = 0; i < roots.length; i++){
        if ((root-roots[i]).ModulusSquared < 0.0001){
          f = false;
          break;
        }
      }
      if (f){
        if ((root.round()-root).ModulusSquared < 0.0001){
          roots.add(root.round());
        } else{
          roots.add(root);
        }
      }
      //print("${new Complex(r, i)} -> $root");
      //print("potroot: ${new Complex(r, i)} -> $root -> ${polynom.ComplexEvaluate(root)}");
    }
  }
  GetRootsFromRange(0.5, 0.0, 10.0, 100.5);
  GetRootsFromRange(-0.5, 0.0, 10.0, 100.5);
  GetRootsFromRange(1.0, -10.0, 10.0, 0.5);
  GetRootsFromRange(-1.0, -10.0, 10.0, 0.5);
  GetRootsFromRange(-10.0, -10000.0, 10000.0, 2000.0);
  GetRootsFromRange(10.0, -10000.0, 10000.0, 2000.0);
  for (var i = roots.length-1; i >= 0; i--){
    //print("${roots[i]*Complex.ione} -> ${polynom.ComplexEvaluate(roots[i]*Complex.ione)}");
    if (polynom.ComplexEvaluate(-roots[i]).ModulusSquared <= 0.000001){
      Complex c = -roots[i];
      bool f = true;
      for (var j = 0; j < roots.length; j++) {
        if ((c-roots[j]).ModulusSquared <= 0.00001){
          f = false;
        }
      }
      if (f) roots.add(c);
    }
    if (polynom.ComplexEvaluate(roots[i]*Complex.ione).ModulusSquared <= 0.000001){
      Complex c = roots[i]*Complex.ione;
      bool f = true;
      for (var j = 0; j < roots.length; j++) {
        if ((c-roots[j]).ModulusSquared <= 0.00001){
          f = false;
        }
      }
      if (f) roots.add(c);
    }
    if (polynom.ComplexEvaluate(roots[i]*-Complex.ione).ModulusSquared <= 0.000001){
      Complex c = roots[i]*-Complex.ione;
      bool f = true;
      for (var j = 0; j < roots.length; j++) {
        if ((c-roots[j]).ModulusSquared <= 0.00001){
          f = false;
        }
      }
      if (f) roots.add(c);
    }
  }
  for (var i = roots.length-1; i >= 0; i--){
    //print(roots[i]);
    if ((roots[i].round()-roots[i]).ModulusSquared < 0.01){
      Complex val = roots.removeAt(i);
      if (polynom.ComplexEvaluate(val.round()).ModulusSquared <= 0.001){
        if (!roots.contains(val.round())) roots.add(val.round());
      } else{
        Complex valr = NewtonFrom(val.round());
        if (!roots.contains(valr)) roots.add(valr);
      }
    }
  }
  for (var i = roots.length-1; i >= 0; i--){
    if (roots[i] == null || roots[i].i.abs() <= 0.000001 || !roots[i].isFinite || polynom.ComplexEvaluate(roots[i]).ModulusSquared > 0.001){
      roots.removeAt(i);
    } else{
      print("root ${roots[i]} -> ${polynom.ComplexEvaluate(roots[i])}");
      int count = 0;
      for (var j = -5; j < 5; j++){
        if (polynom.ComplexEvaluate(roots[i]+new Complex.from(j.toDouble())).Modulus <= 0.00001){
          count++;
        }
      }
      if (count > 3){
        roots.removeAt(i);
      }
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
    } else{
      int count = 0;
      for (var j = -5; j < 5; j++){
        if (EvaluateFuncAt(postfixStack, roots[i]+j).abs() <= 0.00001){
          count++;
        }
      }
      if (count > 3){
        roots.removeAt(i);
      }
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
  if (!minY.isFinite) minY = -5.0;
  if (!maxY.isFinite) maxY =  5.0;
  if (minY == maxY){
    minY = -5.0;
    maxY = 5.0;
  }
  if (maxY-minY > 4){
    minY = minY.roundToDouble();
    maxY = maxY.roundToDouble();
  }
  lastMinX = minX;
  lastMaxX = maxX;
  lastMinY = minY;
  lastMaxY = maxY;
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
  double stepSize;
  print("Plot range: ${(maxX-minX).round()}");
  if ((maxX-minX).round() == 10){
    stepSize = 1.0;
  } else if ((maxX-minX).round() == 20){
    stepSize = 2.0;
  } else if ((maxX-minX)/2 <= 0.25){
    stepSize = ((maxX-minX)/2).floor()*0.05 > 0.05 ? ((maxX-minX)/2).floor()*0.05 : 0.05;
  } else if ((maxX-minX).round() <= 1){
    stepSize = ((maxX-minX)/2).floor()*0.1 > 0.1 ? ((maxX-minX)/2).floor()*0.1 : 0.1;
  } else {
    stepSize = ((maxX-minX)/2).floor()*0.25 > 0.25 ? ((maxX-minX)/2).floor()*0.25 : 0.25;
  }
  if (stepSize > 1.0) stepSize = stepSize.roundToDouble();
  for (var i = minX; i < maxX; i += stepSize){
    if (i <= minX || i >= maxX || i == 0) continue;
    ctx.beginPath();
    ctx.moveTo(MapToRange(i, minX, maxX, 0.0, 400.0), 400-yorigin-5);
    ctx.lineTo(MapToRange(i, minX, maxX, 0.0, 400.0), 400-yorigin+5);
    if (i.abs() > 0.000001) ctx.fillText("${i.toStringAsFixed(2)}", MapToRange(i, minX, maxX, 0.0, 400.0), 400-yorigin+18);
    ctx.closePath();
    if (f) ctx.stroke();
  }
  f = true;
  if (xorigin < 10 || xorigin > 400){
    xorigin = 40.0;
    f = false;
  }
  if ((maxY-minY).round() == 10){
    stepSize = 1.0;
  } else if ((maxY-minY).round() == 20){
    stepSize = 2.0;
  } else if ((maxY-minY)/2 <= 0.25){
    stepSize = ((maxY-minY)/2).floor()*0.05 > 0.05 ? ((maxY-minY)/2).floor()*0.05 : 0.05;
  } else if ((maxY-minY).round() <= 1){
    stepSize = ((maxY-minY)/2).floor()*0.1 > 0.1 ? ((maxY-minY)/2).floor()*0.1 : 0.1;
  } else {
    stepSize = ((maxY-minY)/2).floor()*0.25 > 0.25 ? ((maxY-minY)/2).floor()*0.25 : 0.25;
  }
  if (stepSize > 1.0) stepSize = stepSize.roundToDouble();
  for (var i = minY; i < maxY; i += stepSize){
    if (i <= minY || i >= maxY || i == 0) continue;
    ctx.beginPath();
    ctx.moveTo(xorigin-5, 400-MapToRange(i, minY, maxY, 0.0, 400.0));
    ctx.lineTo(xorigin+5, 400-MapToRange(i, minY, maxY, 0.0, 400.0));
    if (i.abs() > 0.000001) ctx.fillText("${i.toStringAsFixed(2)}", xorigin-20, 400-MapToRange(i, minY, maxY, 0.0, 400.0)+4);
    ctx.closePath();
    if (f) ctx.stroke();
  }
  ctx.fillStyle = "#818181";
  double lastY;
  for (var i = 0; i <= 400; i++){
    double x = MapToRange(i.toDouble(), 0.0, 400.0, minX, maxX);
    double y = polynom.Evaluate(x);
    //print("$x : $y");
    if (!y.isFinite){
      lastY = null;
      continue;
    }
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
  minX = -10.0;
  maxX = 10.0;
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
  if (eMinX != null){
    minX = eMinX;
    maxX = eMaxX;
  }
  if (eMinY != null){
    minY = eMinY;
    maxY = eMaxY;
  }
  lastMinX = minX;
  lastMaxX = maxX;
  lastMinY = minY;
  lastMaxY = maxY;
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
  double stepSize;
  print("Plot range: ${(maxX-minX).round()}");
  if ((maxX-minX).round() == 10){
    stepSize = 1.0;
  } else if ((maxX-minX).round() == 20){
    stepSize = 2.0;
  } else if ((maxX-minX)/2 <= 0.25){
    stepSize = ((maxX-minX)/2).floor()*0.05 > 0.05 ? ((maxX-minX)/2).floor()*0.05 : 0.05;
  } else if ((maxX-minX).round() <= 1){
    stepSize = ((maxX-minX)/2).floor()*0.1 > 0.1 ? ((maxX-minX)/2).floor()*0.1 : 0.1;
  } else {
    stepSize = ((maxX-minX)/2).floor()*0.25 > 0.25 ? ((maxX-minX)/2).floor()*0.25 : 0.25;
  }
  if (stepSize > 1.0) stepSize = stepSize.roundToDouble();
  for (var i = minX; i < maxX; i += stepSize){
    if (i <= minX || i >= maxX || i == 0) continue;
    ctx.beginPath();
    ctx.moveTo(MapToRange(i, minX, maxX, 0.0, 400.0), 400-yorigin-5);
    ctx.lineTo(MapToRange(i, minX, maxX, 0.0, 400.0), 400-yorigin+5);
    if (i.abs() > 0.000001) ctx.fillText("${i.toStringAsFixed(2)}", MapToRange(i, minX, maxX, 0.0, 400.0), 400-yorigin+18);
    ctx.closePath();
    if (f) ctx.stroke();
  }
  f = true;
  if (xorigin < 10 || xorigin > 400){
    xorigin = 40.0;
    f = false;
  }
  if ((maxY-minY).round() == 10){
    stepSize = 1.0;
  } else if ((maxY-minY).round() == 20){
    stepSize = 2.0;
  } else if ((maxY-minY)/2 <= 0.25){
    stepSize = ((maxY-minY)/2).floor()*0.05 > 0.05 ? ((maxY-minY)/2).floor()*0.05 : 0.05;
  } else if ((maxY-minY).round() <= 1){
    stepSize = ((maxY-minY)/2).floor()*0.1 > 0.1 ? ((maxY-minY)/2).floor()*0.1 : 0.1;
  } else {
    stepSize = ((maxY-minY)/2).floor()*0.25 > 0.25 ? ((maxY-minY)/2).floor()*0.25 : 0.25;
  }
  if (stepSize > 1.0) stepSize = stepSize.roundToDouble();
  for (var i = minY; i < maxY; i += stepSize){
    if (i <= minY || i >= maxY || i == 0) continue;
    ctx.beginPath();
    ctx.moveTo(xorigin-5, 400-MapToRange(i, minY, maxY, 0.0, 400.0));
    ctx.lineTo(xorigin+5, 400-MapToRange(i, minY, maxY, 0.0, 400.0));
    if (i.abs() > 0.000001) ctx.fillText("${i.toStringAsFixed(2)}", xorigin-20, 400-MapToRange(i, minY, maxY, 0.0, 400.0)+4);
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
  double result = 0.0;
  int nmin = 1;
  int nmax = 2;
  ButtonElement summodeButton = querySelector("#summodebutton");
  if (summodeButton.classes.contains("button-active")){
    InputElement input = querySelector("[name=nfrom]");
    nmin = num.parse(input.value);
    input = querySelector("[name=nto]");
    nmax = num.parse(input.value)+1;
  }
  for (var n = nmin; n < nmax; n++){
    List<String> equationStack = new List<String>.from(postfixStack);
    for (var i = 0; i < equationStack.length; i++){
      if (equationStack[i] == "n"){
        equationStack[i] = n.toString();
      }
    }
    Queue<num> stack = new Queue<num>();
    for (var i = 0; i < equationStack.length; i++){
      num value;
      try{
        value = num.parse(equationStack[i]);
      } catch (e){
      }
      if (value != null){
        stack.add(value);
      } else if (equationStack[i] == "+"){
        double last = stack.removeLast();
        stack.add(stack.removeLast()+last);
      } else if (equationStack[i] == "-"){
        double last = stack.removeLast();
        stack.add(stack.removeLast()-last);
      } else if (equationStack[i] == "*"){
        double last = stack.removeLast();
        stack.add(stack.removeLast()*last);
      } else if (equationStack[i] == "**"){
        double last = stack.removeLast();
        stack.add(pow(stack.removeLast(), last));
      } else if (equationStack[i] == "/"){
        double last = stack.removeLast();
        stack.add(stack.removeLast()/last);
      } else if (equationStack[i] == "%"){
        double last = stack.removeLast();
        stack.add(stack.removeLast()%last);
      } else if (equationStack[i] == "!"){
        stack.add(fact(stack.removeLast()));
      } else if (equationStack[i] == "mod"){
        double last = stack.removeLast();
        stack.add(mod(stack.removeLast(), last));
      } else if (equationStack[i] == "rem"){
        double last = stack.removeLast();
        stack.add(remainder(stack.removeLast(), last));
      } else if (equationStack[i] == "sin"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")) last = last*0.017453292519943295;
        stack.add(sin(last));
      } else if (equationStack[i] == "cos"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")) last = last*0.017453292519943295;
        stack.add(cos(last));
      } else if (equationStack[i] == "tan"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")) last = last*0.017453292519943295;
        stack.add(tan(last));
      } else if (equationStack[i] == "cotan"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")) last = last*0.017453292519943295;
        stack.add(cotan(last));
      } else if (equationStack[i] == "sec"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")) last = last*0.017453292519943295;
        stack.add(sec(last));
      } else if (equationStack[i] == "cosec"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")) last = last*0.017453292519943295;
        stack.add(cosec(last));
      } else if (equationStack[i] == "sinh"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")) last = last*0.017453292519943295;
        stack.add(sinh(last));
      } else if (equationStack[i] == "cosh"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")) last = last*0.017453292519943295;
        stack.add(cosh(last));
      } else if (equationStack[i] == "tanh"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")) last = last*0.017453292519943295;
        stack.add(tanh(last));
      } else if (equationStack[i] == "cotanh"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")) last = last*0.017453292519943295;
        stack.add(cotanh(last));
      } else if (equationStack[i] == "sech"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")) last = last*0.017453292519943295;
        stack.add(sech(last));
      } else if (equationStack[i] == "cosech"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")) last = last*0.017453292519943295;
        stack.add(cosech(last));
      } else if (equationStack[i] == "arcsin"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")){
          stack.add(arcsin(last)*57.295779513082320876798154);
        } else{
          stack.add(arcsin(last));
        }
      } else if (equationStack[i] == "arccos"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")){
          stack.add(arccos(last)*57.295779513082320876798154);
        } else{
          stack.add(arccos(last));
        }
      } else if (equationStack[i] == "arctan"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")){
          stack.add(arctan(last)*57.295779513082320876798154);
        } else{
          stack.add(arctan(last));
        }
      } else if (equationStack[i] == "arccotan"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")){
          stack.add(arccotan(last)*57.295779513082320876798154);
        } else{
          stack.add(arccotan(last));
        }
        stack.add(arccotan(stack.removeLast()));
      } else if (equationStack[i] == "arcsec"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")){
          stack.add(arcsec(last)*57.295779513082320876798154);
        } else{
          stack.add(arcsec(last));
        }
      } else if (equationStack[i] == "arccosec"){
        double last = stack.removeLast();
        if (degreemodebutton.classes.contains("button-active")){
          stack.add(arccosec(last)*57.295779513082320876798154);
        } else{
          stack.add(arccosec(last));
        }
      } else if (equationStack[i] == "sqrt"){
        stack.add(sqrt(stack.removeLast()));
      } else if (equationStack[i] == "exp"){
        stack.add(exp(stack.removeLast()));
      } else if (equationStack[i] == "gamma"){
        stack.add(gamma(stack.removeLast()));
      } else if (equationStack[i] == "ln"){
        stack.add(log(stack.removeLast()));
      } else if (equationStack[i] == "log"){
        stack.add(log(stack.removeLast())/log(10));
      } else if (equationStack[i] == "abs"){
        double last = stack.removeLast();
        if (last > 0){
          stack.add(last);
        } else{
          stack.add(-last);
        }
      } else if (equationStack[i] == "sign"){
        double last = stack.removeLast();
        if (last > 0){
          stack.add(1);
        } else if (last < 0){
          stack.add(-1);
        } else{
          stack.add(0);
        }
      } else if (equationStack[i] == "floor"){
        stack.add((stack.removeLast()).floorToDouble());
      } else if (equationStack[i] == "ceil"){
        stack.add((stack.removeLast()).ceilToDouble());
      } else if (equationStack[i] == "round"){
        stack.add((stack.removeLast()).roundToDouble());
      } else if (equationStack[i] == "choose"){
        double last = stack.removeLast();
        stack.add(binomialCoefficient(stack.removeLast(), last));
      } else if (equationStack[i] == "divisor"){
        double last = stack.removeLast();
        stack.add(Sigma(last.toInt(), 0));
      } else if (equationStack[i] == "sigma"){
        double last = stack.removeLast();
        stack.add(Sigma(last.toInt(), 1));
      } else if (equationStack[i] == "prime"){
        int last = stack.removeLast().toInt();
        if (last <= 0){
          stack.add(0);
        } else{
          while (last > primes.length){
            print("Calculating more primes - max: ${highestPrecalculatedPrime*2}, currently have ${primes.length} primes, need $last");
            primes = PrimesTo(highestPrecalculatedPrime*2);
            highestPrecalculatedPrime = highestPrecalculatedPrime*2;
            print("Done, now have ${primes.length} primes");
          }
          stack.add(primes[last-1]);
        }
      } else if (equationStack[i] == "isprime"){
        int last = stack.removeLast().toInt();
        while (last > primes.last){
          print("Calculating more primes - max: ${highestPrecalculatedPrime*2}, currently highest is ${primes.last}, need $last");
          primes = PrimesTo(highestPrecalculatedPrime*2);
          highestPrecalculatedPrime = highestPrecalculatedPrime*2;
          print("Done, now have ${primes.length} primes");
        }
        stack.add(primes.contains(last) ? 1 : 0);
      }
      //print("${postfixStack[i]} : $stack");
    }
    result += stack.removeLast().toDouble();
  }
  return result;
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
      Complex slast = stack.removeLast();
      if (last.i == 0.0 && slast.i == 0.0 && ((last.r % 1) == 0 || slast.r >= 0.0)){
        stack.add(new Complex.from(pow(slast.r, last.r)));
      } else{
        stack.add(Pow(slast, last));
      }
    } else if (postfixStack[i] == "/"){
      Complex last = stack.removeLast();
      stack.add(stack.removeLast()/last);
    } /* else if (postfixStack[i] == "%"){
      Complex last = stack.removeLast();
      stack.add(stack.removeLast()%last);
    }*/ else if (postfixStack[i] == "!"){
      stack.add(Gamma(stack.removeLast()+Complex.one));
    } else if (postfixStack[i] == "sin"){
      Complex last = stack.removeLast();
      if (last.i == 0.0){
        if (degreemodebutton.classes.contains("button-active")) last = new Complex.from(last.r*0.017453292519943295);
        stack.add(new Complex.from(sin(last.r)));
      } else{
        stack.add(last.sin());
      }
    } else if (postfixStack[i] == "cos"){
      Complex last = stack.removeLast();
      if (last.i == 0.0){
        if (degreemodebutton.classes.contains("button-active")) last = new Complex.from(last.r*0.017453292519943295);
        stack.add(new Complex.from(cos(last.r)));
      } else{
        stack.add(last.cos());
      }
    } else if (postfixStack[i] == "tan"){
      Complex last = stack.removeLast();
      if (last.i == 0.0){
        if (degreemodebutton.classes.contains("button-active")) last = new Complex.from(last.r*0.017453292519943295);
        stack.add(new Complex.from(tan(last.r)));
      } else{
        stack.add(last.sin()/last.cos());
      }
    } else if (postfixStack[i] == "cotan"){
      Complex last = stack.removeLast();
      if (last.i == 0.0){
        if (degreemodebutton.classes.contains("button-active")) last = new Complex.from(last.r*0.017453292519943295);
        stack.add(new Complex.from(cotan(last.r)));
      } else{
        stack.add(last.cos()/last.sin());
      }
    } else if (postfixStack[i] == "sec"){
      Complex last = stack.removeLast();
      if (last.i == 0.0){
        if (degreemodebutton.classes.contains("button-active")) last = new Complex.from(last.r*0.017453292519943295);
        stack.add(new Complex.from(sec(last.r)));
      } else{
        stack.add(new Complex.from(1.0)/last.cos());
      }
    } else if (postfixStack[i] == "cosec"){
      Complex last = stack.removeLast();
      if (last.i == 0.0){
        if (degreemodebutton.classes.contains("button-active")) last = new Complex.from(last.r*0.017453292519943295);
        stack.add(new Complex.from(cosec(last.r)));
      } else{
        stack.add(new Complex.from(1.0)/last.sin());
      }
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
      Complex last = stack.removeLast();
      if (last.i == 0.0 && last.r >= 0.0){
        stack.add(new Complex.from(sqrt(last.r)));
      } else{
        stack.add(Sqrt(last));
      }
      //stack.add(Sqrt(stack.removeLast()));
    } else if (postfixStack[i] == "exp"){
      stack.add(Exp(stack.removeLast()));
    } else if (postfixStack[i] == "gamma"){
      stack.add(Gamma(stack.removeLast()));
    } else if (postfixStack[i] == "ln"){
      Complex last = stack.removeLast();
      if (last.i == 0.0 && last.r >= 0.0){
        stack.add(new Complex.from(log(last.r)));
      } else{
        stack.add(Log(last));
      }
    } else if (postfixStack[i] == "log"){
      Complex last = stack.removeLast();
      if (last.i == 0.0 && last.r >= 0.0){
        stack.add(new Complex.from(log(last.r)/log(10.0)));
      } else{
        stack.add(Log(last)/Log(new Complex.from(10.0)));
      }
    } else if (postfixStack[i] == "abs"){
      stack.add(new Complex.from(stack.removeLast().Modulus));
    } else if (postfixStack[i] == "arg"){
      stack.add(new Complex.from(stack.removeLast().Argument));
    } else if (postfixStack[i] == "sign"){
      stack.add(stack.removeLast().Sign);
    } else if (postfixStack[i] == "floor"){
      stack.add((stack.removeLast()).floor());
    } else if (postfixStack[i] == "ceil"){
      stack.add((stack.removeLast()).ceil());
    } else if (postfixStack[i] == "round"){
      stack.add((stack.removeLast()).round());
    } else if (postfixStack[i] == "choose"){
      Complex last = stack.removeLast();
      stack.add(BinomialCoefficient(stack.removeLast(), last));
    } else{
      throw UnimplementedError;
    }
    //print("${postfixStack[i]} : $stack");
  }
  if (stack.length > 1){
    throw Error;
  }
  Complex comp = stack.removeLast();
  if ((comp.r.roundToDouble()-comp.r).abs() < 0.0000000001){
    comp = new Complex(comp.r.roundToDouble(), comp.i);
  }
  if ((comp.i.roundToDouble()-comp.i).abs() < 0.0000000001){
    comp = new Complex(comp.r, comp.i.roundToDouble());
  }
  return comp;
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
  } else if (op == "mod"){
    return 2;
  } else if (op == "rem"){
    return 2;
  } else if (op == "**"){
    return 3;
  } else if (op == "("){
    return 0;
  } 
  return 4;
}
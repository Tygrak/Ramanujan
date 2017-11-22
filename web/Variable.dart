class VariablePolynom{
  List<Variable> variables = new List<Variable>();

  VariablePolynom();
  int get hashCode => (variables.hashCode).floor();
  String toString(){
    String res = "";
    variables.sort((Variable v1, Variable v2){
      if (v1.degree > v2.degree) return -1;
      else if (v1.degree < v2.degree) return 1;
      else return 0;
    });
    for (var i = 0; i < variables.length; i++){
      if (res.length > 0){
        res += " + ";
      }
      res += "${variables[i]}";
    }
    return res;
  }
 
  VariablePolynom operator +(VariablePolynom other){
    for (var v1 in variables){
      Variable v2 = other.variables.firstWhere((Variable v) => v1.degree == v.degree, orElse: () => null);
      if (v2 != null){
        v2 = v1+v2;
      } else{
        other.variables.add(new Variable(v1.c, v1.degree));
      }
    }
    return other;
  }
  VariablePolynom operator -(VariablePolynom other){
    for (var v1 in variables){
      Variable v2 = other.variables.firstWhere((Variable v) => v1.degree == v.degree, orElse: () => null);
      if (v2 != null){
        v2 = v1-v2;
      } else{
        other.variables.add(new Variable(v1.c, v1.degree));
      }
    }
    return other;
  }
  VariablePolynom operator *(VariablePolynom other){
    VariablePolynom res = new VariablePolynom();
    for (var v1 in variables){
      for (var v2 in other.variables){
        res.variables.add(v1*v2);
      }
    }
    //print(res);
    for (var i = res.variables.length-1; i >= 0; i--){
      for (var j = i-1; j >= 0; j--){
        if (res.variables[i].degree == res.variables[j].degree){
          res.variables[j] = res.variables[j]+res.variables[i];
          res.variables.removeAt(i);
          break;
        }
      }
    }
    //print(res);
    return res;
  }
  VariablePolynom operator /(VariablePolynom other){
    VariablePolynom res = new VariablePolynom();
    for (var v1 in variables){
      for (var v2 in other.variables){
        res.variables.add(v1/v2);
      }
    }
    //print(res);
    for (var i = res.variables.length-1; i >= 0; i--){
      for (var j = i-1; j >= 0; j--){
        if (res.variables[i].degree == res.variables[j].degree){
          res.variables[j] = res.variables[j]+res.variables[i];
          res.variables.removeAt(i);
          break;
        }
      }
    }
    //print(res);
    return res;
  }
  bool operator ==(VariablePolynom other){
    for (var i = variables.length-1; i >= 0; i--){
      if (variables[i] != other.variables[i]){
        return false;
      }
    }
    return true;
  }
}

class Variable{
  double _c;
  double _degree = 1.0;

  Variable(this._c, this._degree);

  double get c => _c;
  double get degree => _degree;
  int get hashCode => ((17 * _c) * 31 + _degree).floor();
  String toString(){
    String res = "";
    if (c != 1 || degree == 0){
      res += "${c}";
    }
    if (degree == 1){
      res += "x";
    } else if (degree != 0){
      res += "x^$degree";
    }
    return res;
  }
 
  Variable operator +(Variable other){
    if (_degree == other._degree){
      return new Variable(_c+other._c, _degree);
    } else{
      print("$this + $other : Not the same variable - can't add.");
      throw TypeError;
    }
  }
  Variable operator -(Variable other){
    if (_degree == other._degree){
      return new Variable(_c-other._c, _degree);
    } else{
      print("$this - $other : Not the same variable - can't subtract.");
      throw TypeError;
    }
  }
  Variable operator *(Variable other){
    return new Variable(_c*other._c, _degree+other._degree);
  }
  Variable operator /(Variable other){
    return new Variable(_c/other._c, _degree-other._degree);
  }
  bool operator ==(Variable other) => (_c == other._c) && (_degree == other._degree);
}

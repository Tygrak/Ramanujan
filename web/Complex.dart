import 'dart:math';
import 'mathExtensions.dart';

class Complex{
  final double _r,_i;
 
  Complex(this._r,this._i);
  Complex.from(double r) : _r = r, _i = 0.0;
  double get r => _r;
  double get i => _i;
  int get hashCode => ((17 * r) * 31 + i).floor();
  String toString(){
    String toPrint = "";
    if (r == 0 && i == 0) return "0";
    if (r != 0) toPrint += r.toString();
    if (i > 0 && r != 0) toPrint += "+";
    if (i != 0) toPrint += i.toString()+"i";
    return toPrint;
  }

  double get Modulus{
    return sqrt(r*r+i*i);
  }

  double get ModulusSquared{
    return r*r+i*i;
  }

  double get Argument{
    return arctan(i/r);
  }

  ///The complex number 0+1*i
  static Complex ione = new Complex(0.0, 1.0);
 
  Complex operator +(Complex other) => new Complex(r+other.r,i+other.i);
  Complex operator -(Complex other) => new Complex(r-other.r,i-other.i);
  Complex operator *(Complex other) => new Complex(r*other.r-i*other.i,r*other.i+other.r*i);
  Complex operator /(Complex other) => _Divide(other);
  bool operator ==(Complex other) => (r == other.r) && (i == other.i);
  Complex _Divide (Complex other){
    double temp = other.r*other.r + other.i*other.i;
    if (temp == 0){
      //return new Complex(0.0, 0.0);
      throw new Exception("Complex division leads to division by zero.");
    }
    return new Complex((r*other.r + i*other.i)/temp, (i*other.r - r*other.i)/temp);
  }
  Complex pow (int toPow){
    Complex val = this;
    for (var i = 0; i < toPow; i++) {
      val = val * this;
    }
    return val;
  }
  Complex timesConst (num constant){
    return new Complex(r*constant, i*constant);
  }
  Complex sin (){
    return (DoubleToComplexPow(E, new Complex(0.0, 1.0)*this)-DoubleToComplexPow(E, new Complex(0.0, -1.0)*this))/(new Complex(0.0, 1.0).timesConst(2));
  }
  Complex cos (){
    return (DoubleToComplexPow(E, new Complex(0.0, 1.0)*this)+DoubleToComplexPow(E, new Complex(0.0, -1.0)*this))/(new Complex(1.0, 0.0).timesConst(2));
  }
}

Complex DoubleToComplexPow(double n, Complex toPow){
  //12^(3 + 2 I) = 1728 cos(2 log(12)) + 1728 i sin(2 log(12))
  return new Complex(cos(toPow.i * log(n)), sin(toPow.i * log(n))).timesConst(pow(n, toPow.r));
}

Complex Pow(Complex n, Complex toPow){
  //(2+3i)**(4+5i)
  //(mod(n)**2)*e**(-5*arg(n))*cos((5*log(mod(n))/2+4*arg(n)))
  //pow(n.Modulus, (toPow.r/2))*pow(e, -toPow.i*n.Argument)*cos((toPow.i*log(n.Modulus))/2+toPow.r*n.Argument)
  //print("pow: ${pow(n.ModulusSquared, toPow.r/2)}*e**(${-toPow.i}*${n.Argument})*cos((${toPow.i}*log(${n.ModulusSquared}))/2+${toPow.r}*${n.Argument})");
  double x = pow(n.ModulusSquared, (toPow.r/2))*pow(e, -toPow.i*n.Argument);
  Complex val = new Complex(x*cos((toPow.i*log(n.ModulusSquared))/2+toPow.r*n.Argument), x*sin((toPow.i*log(n.ModulusSquared))/2+toPow.r*n.Argument));
  //Complex val = DoubleToComplexPow(e, new Complex(toPow.r*log(n.Modulus)-toPow.i*n.Argument, toPow.r*n.Argument+toPow.i*log(n.Modulus)));
  if (toPow.i == 0.0 && toPow.r % 1 != 0 && (toPow.r*2) % 1 == 0 && n.r < 0.0){
    val = new Complex(0.0, val.r);
  }
  return val;
}

Complex Sqrt(Complex n){
  return Pow(n, new Complex.from(0.5));
}

Complex Log(Complex n){
  return new Complex(log(n.Modulus), n.Argument);
}
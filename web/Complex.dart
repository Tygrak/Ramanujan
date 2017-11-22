import 'dart:math';

class Complex{
  final double _r,_i;
 
  Complex(this._r,this._i);
  double get r => _r;
  double get i => _i;
  int get hashCode => ((17 * r) * 31 + i).floor();
  String toString() => "($r,$i)";
 
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
    return (Pow(E, new Complex(0.0, 1.0)*this)-Pow(E, new Complex(0.0, -1.0)*this))/(new Complex(0.0, 1.0).timesConst(2));
  }
  Complex cos (){
    return (Pow(E, new Complex(0.0, 1.0)*this)+Pow(E, new Complex(0.0, -1.0)*this))/(new Complex(1.0, 0.0).timesConst(2));
  }
  double abs() => r*r+i*i;
}

Complex Pow(double n, Complex toPow){
  //12^(3 + 2 I) = 1728 cos(2 log(12)) + 1728 i sin(2 log(12))
  return new Complex(cos(toPow.i * log(n)), sin(toPow.i * log(n))).timesConst(pow(n, toPow.r));
}
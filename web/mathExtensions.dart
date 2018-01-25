import 'dart:math';

List<int> NumDivisors(int number){
  List<int> divisors = new List<int>();
  for (var a = 1; a <= sqrt(number); a++){
    if (number % a == 0){
      int b = number~/a;
      divisors.add(a);
      if (a != b){
        divisors.add(b);
      }
    }
  }
  return divisors;
}

List<int> PrimesTo(int max){
  List<int> primes = new List<int>();
  primes.add(2);
  for (var i = 3; i <= max; i=i+2){
    primes.add(i);
  }
  for (var i = 1; i < primes.length; i++){
    for (var j = primes.length-1; j >= i+1; j--){
      if (primes[j] % primes[i] == 0){
        primes.removeAt(j);
      }
    }
  }
  return primes;
}

int Sigma(int number, int toPow){
  List<int> divisors = NumDivisors(number);
  if (toPow == 0){
    return divisors.length;
  } else{
    int sum = 0;
    for (var i = 0; i < divisors.length; i++){
      sum += (pow(divisors[i], toPow));
    }
    return sum;
  }
}

double MapToRange(double value, double min1, double max1, double min2, double max2){
  return (value-min1)/(max1-min1) * (max2-min2) + min2;
}

int mod(double a, double n){
  return (a - (n * (a/n).floor())).toInt();
}

int remainder(double a, double n){
  return (a - (n * (a/n).truncateToDouble())).toInt();
}

double fact(double val){
  double res = 1.0;
  if (val % 1 == 0){
    for (var i = 2; i <= val.round().abs(); i++) {
      res *= i;
    }
  } else{
    res = gamma(val+1);
  }
  return res;
}

double gamma(double val){
  List<double> p = [676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7
  ];
  double res;
  if (val < 0.5){
    res = pi / (sin(pi*val) * gamma(1-val));
  } else{
    val -= 1;
    double x = 0.99999999999980993;
    for (var i = 0; i < p.length; i++) {
      x += p[i]/(val+i+1);
    }
    double t = val + p.length - 0.5;
    res = sqrt(2*pi) * pow(t, (val+0.5)) * exp(-t) * x;
  }
  return res;
}

double cotan(double x){
  return 1/tan(x);
}

double sec(double x){
  return 1/cos(x);
}

double cosec(double x){
  return 1/sin(x);
}

double sinh(double x){
  return (pow(E, x)-pow(E, -x))/2;
}

double cosh(double x){
  return (pow(E, x)+pow(E, -x))/2;
}

double tanh(double x){
  return ((pow(E, x)-pow(E, -x))/2)/((pow(E, x)+pow(E, -x))/2);
}

double cotanh(double x){
  return ((pow(E, x)+pow(E, -x))/2)/((pow(E, x)-pow(E, -x))/2);
}

double sech(double x){
  return 2/(pow(E, x)+pow(E, -x));
}

double cosech(double x){
  return 2/(pow(E, x)-pow(E, -x));
}

double arcsin(double x){
  double a = pi/2;
  double b = -pi/2;
  for (var i = 0; i < 100; i++) {
    if ((sin(a)-x).abs() < (sin(b)-x).abs()){
      b = (a+b*2)/3;
    } else{
      a = (a*2+b)/3;
    }
  }
  return a;
}

double arccos(double x){
  double a = 0.0;
  double b = pi;
  for (var i = 0; i < 100; i++) {
    if ((cos(a)-x).abs() < (cos(b)-x).abs()){
      b = (a+b*2)/3;
    } else{
      a = (a*2+b)/3;
    }
  }
  return a;
}

double arctan(double x){
  if (x == double.infinity) return pi/2;
  if (x == double.negativeInfinity) return -pi/2;
  double a = pi/2-0.0000001;
  double b = -pi/2+0.0000001;
  for (var i = 0; i < 100; i++) {
    if ((tan(a)-x).abs() < (tan(b)-x).abs()){
      b = (a+b*6)/7;
    } else{
      a = (a*6+b)/7;
    }
  }
  return a;
}

double arccotan(double x){
  double a = 0.0000001;
  double b = pi-0.0000001;
  for (var i = 0; i < 100; i++) {
    if ((cotan(a)-x).abs() < (cotan(b)-x).abs()){
      b = (a+b*6)/7;
    } else{
      a = (a*6+b)/7;
    }
  }
  return a;
}

double arcsec(double x){
  double a = 0.0;
  double b = pi/2-0.0000001;
  x = 1/x;
  for (var i = 0; i < 100; i++) {
    if ((cos(a)-x).abs() < (cos(b)-x).abs()){
      b = (a+b*2)/3;
    } else{
      a = (a*2+b)/3;
    }
  }
  return a;
}

double arccosec(double x){
  double a = 0.0000001;
  double b = pi/2;
  x = 1/x;
  for (var i = 0; i < 100; i++) {
    if ((sin(a)-x).abs() < (sin(b)-x).abs()){
      b = (a+b*2)/3;
    } else{
      a = (a*2+b)/3;
    }
  }
  return a;
}

double binomialCoefficient(double x, double y){
  return fact(x)/(fact(y)*fact(x-y));
}
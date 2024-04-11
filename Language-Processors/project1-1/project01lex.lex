%option c++ noyywrap
%option yyclass="MyLexer"
%option yylineno
%{
#include <iostream>
#include <fstream>
#include <vector>
#include <cmath>
#include <limits>
#include <string>
#include <algorithm>

#if !defined(yyFlexLexerOnce)
#include <FlexLexer.h>
#endif

using namespace std;

class Sequence {
  public:
    
    double minNumber = numeric_limits<double>::max();
    double maxNumber = numeric_limits<double>::lowest();
    vector<double> numbers = {};
    int monotonicity = 0; //0: constant, 1: increasing, 2: decreasing, -1 not monotonic
    double average;

    double calculateStandardDeviation(const std::vector<double>* vecPtr) {
    if (!vecPtr || vecPtr->empty()) {
        // Handle the case where the pointer is null or points to an empty vector
        throw std::invalid_argument("Vector pointer is null or points to an empty vector");
    }

    const std::vector<double>& vec = *vecPtr;
    double sum = 0.0;
    double mean = 0.0;
    double standardDeviation = 0.0;

    // Step 1: Calculate the mean
    for(double num : vec) {
        sum += num;
    }
    mean = sum / vec.size();

    // Step 2 & 3: Calculate squared differences from mean and mean of those differences
    sum = 0.0; // Reset sum to use it for the calculation of squared differences
    for(double num : vec) {
        sum += std::pow(num - mean, 2);
    }
    mean = sum / vec.size();

    // Step 4: Take the square root of the mean of squared differences
    standardDeviation = std::sqrt(mean);

    return standardDeviation;
  }

  void processNum(double num){

        numbers.push_back(num);
        if (num > maxNumber) maxNumber = num;
        if (num < minNumber) minNumber = num;

        if (numbers.size() > 1) {
        if (num > numbers[numbers.size() - 2]) {
            if (monotonicity == 0) monotonicity = 1;
            else if (monotonicity == 2) monotonicity = -1;
        } else if (num < numbers[numbers.size() - 2]) {
            if (monotonicity == 0) monotonicity = 2;
            else if (monotonicity == 1) monotonicity = -1;
        }

        }


  }

};

class MyLexer : public yyFlexLexer {
    // Variables to hold the statistics

public:
    MyLexer(istream* in = nullptr, ostream* out = nullptr) : yyFlexLexer(in, out) {}
    vector<Sequence> sequences;
    int identifiers = 0;
    vector<int> illegalIdentifiers = {}; // vector hold line numbers
    vector<int> illegalLines = {}; // vector hold line numbers
    int i = 1;
    
    unsigned int currentMask = 0;
    unsigned int currentGateway = 0;
    bool maskSet = false;
    bool gatewaySet = false;
    string mask = "";
    string gateway = "";
    string address = "";
    bool atLeastOneIpError = false;


    ostream* out;
    ostream* id_out;
    ostream* net_out;
    ostream* exc_out;

    int lineNo = 1;

    void outputStats(){
        for(Sequence seq : sequences){
        *out << "Sequnce " << i++ << ":"<< endl;
        int totalNumbers = seq.numbers.size();
        if (totalNumbers ==0 && sequences.size() == 1) {
            break;
        }
        if (totalNumbers == 0) {
            *out << "Empty!" << endl;
            continue;
        }

        double sum = 0, sumSquares = 0, average, stdDev;
        bool isMonotonicIncreasing = true, isMonotonicDecreasing = true;

        for (double num : seq.numbers) {
            sum += num;
            sumSquares += num * num;
            // Check if the sequence is monotonic
        }

        average = sum / totalNumbers;
        double variance = (sumSquares - sum * sum / totalNumbers) / totalNumbers;
        stdDev = sqrt(variance);

        *out << "Minimum: " << seq.minNumber << endl;
        *out << "Maximum: " << seq.maxNumber << endl;
        *out << "Number of entries: " << totalNumbers << endl;
        *out << "Average: " << average << endl;
        *out << "Standard Deviation: " << stdDev << endl;
        *out << "Is monotonic: ";
        switch (seq.monotonicity) {
          case 0:
            *out << "Yes" << endl;
            break;
          case 1:
            *out << "Yes, increasing" << endl;
            break;
          case 2:
            *out << "Yes, decreasing" << endl;
            break;
          case -1:
            *out << "No" << endl;
            break;

        }
        *out << endl;




        }

        *id_out << "The number of the identifiers detected is: " << identifiers << endl;
    };

    unsigned int ipToUint(const string& ip) {
      unsigned int output = 0;
      int shift = 24;
      size_t start = 0, end = 0;
      while ((end = ip.find('.', start)) != string::npos) {
        output |= (stoi(ip.substr(start, end - start)) << shift);
        shift -= 8;
        start = end + 1;
      }
      output |= (stoi(ip.substr(start)) << shift); // Last octet
      return output;
    }

    
    bool isValidMask(const string& mask) {
      unsigned int bmask = ipToUint(mask);
      // Invert mask: valid if only leading bits are 0 (after inversion, it should be 1s followed by 0s)
      unsigned int invertedMask = ~bmask;
      // Check if the inverted mask + 1 is a power of 2 (or zero), which means the original mask is valid
      bool isValid = (invertedMask & (invertedMask + 1)) == 0;
      return isValid;
    }



    virtual int yylex();
};

static inline void ltrim(std::string &s) {
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](unsigned char ch) {
        return !std::isspace(ch);
    }));
}

static inline void rtrim(std::string &s) {
    s.erase(std::find_if(s.rbegin(), s.rend(), [](unsigned char ch) {
        return !std::isspace(ch);
    }).base(), s.end());
}

static inline void trim(std::string &s) {
    ltrim(s);
    rtrim(s);
}

%}

Punctuation [!"#$%&'()*+,-./:;<=>?@[\\\]^_`{|}~]

White  [ \t\n\r\f\v<<EOF>>]
WhiteWithoutNewLine  [ \t\r\f\v]

Letter  [A-Za-z\xC4\xB1\xC3\xBC\xC3\x9C\xC4\x9F\xC4\x9E\xC5\x9F\xC5\x9E\xC3\xB6\xC3\x96\xC3\xA7\xC3\x87\xCE\x91-\xCE\xBF\xCF\x80-\xCF\x8E\xCE\x80-\xCE\xAB\xCE\xAC\xCE\xAD\xCE\xAE\xCE\xAF\xCF\x8C\xCF\x8D\xCF\x8E\xCE\xB1-\xCE\xBF\xCF\x80-\xCF\x89]

IPv4    ([0-9]|([1-9][0-9])|(1[0-9]{2})|(2[0-4][0-9])|(25[0-5]))(\.([0-9]|([1-9][0-9])|(1[0-9]{2})|(2[0-4][0-9])|(25[0-5]))){3}

%%

\n {lineNo++;}

gateway[ \t]+{IPv4}\n {
    gateway = yytext + 8;
    trim(gateway);
    currentGateway = ipToUint(gateway);
    gatewaySet = true;
    //cout << "Gateway set: " << gateway << endl;
}

mask[ \t]+{IPv4}\n {
    mask = yytext + 5;
    trim(mask);
    if (isValidMask(mask)) {
        currentMask = ipToUint(mask);
        maskSet = true;
        //cout << "Valid mask set: " << mask << endl;
    } else {
        atLeastOneIpError = true;
        *exc_out << std::to_string(yylineno-1) << ": " << "Invalid mask." << endl;
    }

}

address[ \t]+{IPv4}\n {
    if (!maskSet || !gatewaySet) {
      *exc_out << std::to_string(yylineno-1) << ": " << "IPv4 configuration is failed due to incomplete configuration" << endl;
      atLeastOneIpError = true;    
    }
    else {
    address = yytext + 8;
    trim(address);
    unsigned int addressInt = ipToUint(address);
    if ((currentMask & currentGateway) == (currentMask & addressInt)) {
        *net_out << "M: " << mask <<" G: "<< gateway<< " A: "<< address  <<" => in" << endl;
    } else {
        *net_out << "M: " << mask <<" G: "<< gateway<< " A: "<< address  <<" => in" << endl;
    }

    currentMask = 0;
    currentGateway = 0;
    maskSet = false;
    gatewaySet = false;
    }
}

[0-9]+(\.[0-9]+)?\n {

  string numstr = YYText();
  trim(numstr);
  double num = stod(numstr);
  sequences.back().processNum(num);
  
}

"reset"\n  {

    Sequence seq;
    seq.numbers = {};
    seq.minNumber = numeric_limits<double>::max();
    seq.maxNumber = numeric_limits<double>::lowest();
    seq.monotonicity = 0;
    sequences.push_back(seq);
    
}

(mask|gateway|address)[ \t]+([0-9]{1,3}\.){3}[0-9]{1,3}\n {
    *exc_out << yylineno << ": " << "Invalid IPv4" << endl;
}

({Letter}|(_))({Letter}|[0-9]|_)*\n  { 
  identifiers++;
  //cout << "Identifier: " << YYText() << endl; 
  
}

~({Letter}|{Punctuation}|{WhiteWithoutNewLine}) {

   *exc_out << std::to_string(yylineno) << ": "<< "Unrecognized token." << endl; 
}

(.)*\n { *exc_out << std::to_string(yylineno-1) << ": "<< "Invalid Line Syntax" << endl; 
}



%%

int main(int argc, char* argv[]) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <input file>" << endl;
        return 1;
    }
    
    ifstream in_file(argv[1]);
    if (!in_file) {
        cerr << "Error opening " << argv[1] << endl;
        return 1;
    }

    ofstream seq_out_file("sequences.txt");
    if (!seq_out_file) {
        cerr << "Error opening sequences.txt" << endl;
        return 1;
    }

    ofstream id_out_file("identifiers.txt");
    if (!id_out_file) {
        cerr << "Error opening identifiers.txt" << endl;
        return 1;
    }

    ofstream net_out_file("nettests.txt");
    if (!net_out_file) {
        cerr << "Error opening nettests.txt" << endl;
        return 1;
    }

    ofstream exc_out_file("exceptions.txt");
    if (!exc_out_file) {
        cerr << "Error opening exceptions.txt" << endl;
        return 1;
    }

    MyLexer lexer(&in_file, nullptr);
    lexer.out = &seq_out_file;
    lexer.id_out = &id_out_file;
    lexer.net_out = &net_out_file;
    lexer.exc_out = &exc_out_file;

    Sequence seq;
    seq.numbers = {};
    seq.minNumber = numeric_limits<double>::max();
    seq.maxNumber = numeric_limits<double>::lowest();
    seq.monotonicity = 0;

    lexer.sequences.push_back(seq);
    // Parse through the input file
    while (lexer.yylex() != 0) { }

    // After parsing, calculate and output the statistics
    lexer.outputStats();

    return 0;
}

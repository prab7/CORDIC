#include <iostream>
#include <cmath>
#include <iomanip>
#include <fstream>

// Constants
const int WIDTH = 32;               // Number of bits for fixed-point format
const int ITERATIONS = 31;          // Number of CORDIC iterations
const double PI = 3.141592653589793;



int toFixedPoint(const double& value, const int& frac_bits) {
    return static_cast<int64_t>(value * (1LL << frac_bits));
}

std::string toBinary(const int64_t& number,const int& bits = 32) {
    std::string binary_rep = "";
    for (int i = bits - 1; i >= 0; i--) {
        binary_rep += ((number >> i) & 1) ? '1' : '0';
    }
    return binary_rep;
}


int main() {

    const int FRAC_BITS = WIDTH - 2; // Number of fractional bits in fixed-point format

    std::ofstream outputFile("arctan_table.txt");
    if (!outputFile.is_open()) {
        std::cerr << "Error opening file!" << std::endl;
        return 1;
    }

    for(int i = 0; i < ITERATIONS; i++){

        double _atan = atan(pow(2, -i));
        int64_t fixed_point_value = toFixedPoint(_atan, FRAC_BITS); // decimal conversion

        // Output fixed-point hex values 
        outputFile << toBinary(fixed_point_value & 0xFFFFFFFF) << '\n';
        std::cout << "    32'h" << toBinary(fixed_point_value & 0xFFFFFFFF);

        if (i < ITERATIONS - 1) {   
            std::cout << ",";
        }

        std::cout << "  // atan(2^-" << std::dec << i << ") = " << _atan << '\n';
    }
    return 0;
}

// also i have no idea why, but the error in each case is 2^-30 (or close)
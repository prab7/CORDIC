#include <iostream>
#include <cmath>
#include <fstream>
#include <bitset>

int main() {
    const double PI = 3.14159265358979323846;

    std::ofstream outputFile("arctan_table.txt");
    if (!outputFile.is_open()) {
        std::cerr << "Error opening file!" << std::endl;
        return 1;
    }
    
    for (int i = 0; i < 31; i++){

        double angle = atan(pow(2, -i));        
        uint64_t binaryValue = static_cast<uint64_t>((angle / (2 * PI)) * 0xFFFFFFFF);
        
        outputFile  << (angle*(180/PI) == 45 ?
                        std::bitset<32>(binaryValue+1) :
                        std::bitset<32>(binaryValue))
                    << '\n';
        std::cout   << std::bitset<32>(binaryValue)
                    << " // arctan(2^-" << i << ") = " << angle * 180/(PI) << std::endl;
    }

    return 0;
}
// tb/tb_top.cpp – DPI memory loader for Verilator + riscv-arch-test
// This makes $readmemh work with the official .hex files (which are in Intel HEX format)

#include <verilated.h>
#include "Vtb_top.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cstdint>
#include <cstring>

extern Vtb_top* topp;

// Simple Intel HEX parser + memory filler
void load_hex_file(const char* filename, vluint32_t* mem, size_t mem_words) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        printf("ERROR: Cannot open HEX file: %s\n", filename);
        return;
    }

    std::string line;
    while (std::getline(file, line)) {
        if (line.empty() || line[0] != ':') continue;

        // Parse Intel HEX record
        size_t len = std::stoul(line.substr(1, 2), nullptr, 16);
        uint32_t addr = std::stoul(line.substr(3, 4), nullptr, 16);
        uint8_t type = std::stoul(line.substr(7, 2), nullptr, 16);

        if (type == 0x00) {  // Data record
            for (size_t i = 0; i < len; i += 4) {
                uint32_t data = 0;
                for (int j = 0; j < 4 && (i + j) < len; ++j) {
                    std::string byte_str = line.substr(9 + (i + j) * 2, 2);
                    data |= std::stoul(byte_str, nullptr, 16) << (j * 8);
                }
                uint32_t word_addr = (addr + i) >> 2;
                if (word_addr < mem_words) {
                    mem[word_addr] = data;
                }
            }
        }
    }
    printf("Loaded HEX file: %s\n", filename);
}

// Called from Verilog $readmemh via DPI
extern "C" void readmemh(const char* filename, vluint32_t* mem, unsigned int words) {
    load_hex_file(filename, mem, words);
}

// Optional: waveform dump
VerilatedVcdC* tfp = nullptr;

void init_trace() {
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    topp->trace(tfp, 99);
    tfp->open("waveform.vcd");
}

void finish_trace() {
    if (tfp) {
        tfp->close();
        delete tfp;
    }
}

// Main entry point
int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    topp = new Vtb_top;

    // Optional: enable waveform
    // init_trace();

    topp->rst_n = 0;
    topp->eval();
    for (int i = 0; i < 10; ++i) {
        topp->clk = !topp->clk;
        topp->eval();
    }
    topp->rst_n = 1;

    while (!Verilated::gotFinish()) {
        topp->clk = !topp->clk;
        topp->eval();

        if (tfp) tfp->dump(Verilated::time());

        Verilated::timeInc(5);
    }

    // finish_trace();
    delete topp;
    return 0;
}

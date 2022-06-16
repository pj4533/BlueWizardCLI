//
//  main.swift
//  BlueWizardCLI
//
//  Created by PJ Gray on 6/16/22.
//

import Foundation
import ArgumentParser

struct Quote {
    var string: String
    var bytestream: String
}

struct BanksFileParser: ParsableCommand {
    @Argument(help: "File with text separated in banks") var filename: String
  
    func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }

    func run() throws {
        if FileManager.default.fileExists(atPath: self.filename) {
            do {
                // First parse banks file to load all quotes into banks
                let data = try String(contentsOfFile: self.filename, encoding: .utf8)
                let allQuotes = data.components(separatedBy: .newlines)
                var banks: [[Quote]] = [[]]
                var currentBank = 0
                for quote in allQuotes {
                    if quote == "" {
                        currentBank += 1
                        banks.append([])
                    } else {
                        banks[currentBank].append(Quote(string: quote, bytestream: ""))
                    }
                }
                
                // Second generate all the bytestreams
                currentBank = 0
                var currentQuote = 0
                for bank in banks {
                    for quote in bank {
                        _ = self.shell("say -v\"alex\" \"\(quote.string)\" -r 100 -o bank\(currentBank)_quote\(currentQuote).wave")
                        _ = self.shell("sox bank\(currentBank)_quote\(currentQuote).wave -r 8k -b16 bank\(currentBank)_quote\(currentQuote).wav")
                        _ = self.shell("rm bank\(currentBank)_quote\(currentQuote).wave")
                        let blueWizard = BlueWizard()
                        blueWizard.load(filename: "bank\(currentBank)_quote\(currentQuote).wav") { byteStreamString in
                            banks[currentBank][currentQuote].bytestream = byteStreamString
                        } failure: { error in
                            print("ERROR: \(error?.localizedDescription ?? "Unknown error")")
                        }
                        _ = self.shell("rm bank\(currentBank)_quote\(currentQuote).wav")
                        currentQuote += 1
                    }
                    currentBank += 1
                    currentQuote = 0
                }
                
                var numBytesByBank: [Int] = []
                
                // Third generate the header file
                var headerFile = dothHeader
                headerFile.append("\n\n#define LPC_SPEECH_SYNTH_NUM_WORD_BANKS \(banks.count)\n\n")
                currentBank = 0
                currentQuote = 0
                for bank in banks {
                    var numBytesInBank = 0
                    for quote in bank {
                        numBytesInBank += quote.bytestream.components(separatedBy: ",").count
                        currentQuote += 1
                    }
                    headerFile.append("extern const uint8_t bank_\(currentBank)[\(numBytesInBank)];\n")
                    numBytesByBank.append(numBytesInBank)
                    currentBank += 1
                    currentQuote = 0
                }
                headerFile.append("\n")
                headerFile.append(dothFooter)
                
                // Fourth generate the cc file
                var ccFile = dotccHeader
                currentBank = 0
                currentQuote = 0
                for bank in banks {
                    ccFile.append("\n/* extern */\n")
                    ccFile.append("const uint8_t bank_\(currentBank)[] = {\n")
                    for quote in bank {
                        ccFile.append("   // \(quote.string)\n")
                        ccFile.append("   \(quote.bytestream)")
                        if (currentQuote + 1) < bank.count {
                            ccFile.append(",")
                        }
                        ccFile.append("\n")
                        currentQuote += 1
                    }
                    ccFile.append("};\n")
                    currentBank += 1
                    currentQuote = 0
                }

                currentBank = 0
                ccFile.append("\n/* extern */\n")
                ccFile.append("LPCSpeechSynthWordBankData word_banks_[] = {\n")
                for _ in banks {
                    ccFile.append("  { bank_\(currentBank), \(numBytesByBank[currentBank]) },\n")
                    currentBank += 1
                }
                ccFile.append("};\n")
                ccFile.append(dotccFooter)
                
                try headerFile.write(to: URL(fileURLWithPath: "lpc_speech_synth_words.h"), atomically: true, encoding: String.Encoding.utf8)
                try ccFile.write(to: URL(fileURLWithPath: "lpc_speech_synth_words.cc"), atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print(error)
            }
        } else {
            print("ERROR: banks file doesn't exist")
        }
    }
}

let dothHeader = """
// Copyright 2016 Emilie Gillet.
//
// Author: Emilie Gillet (emilie.o.gillet@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// See http://creativecommons.org/licenses/MIT/ for more information.
//
// -----------------------------------------------------------------------------
//
// LPC10 encoded words extracted from various TI ROMs.

#ifndef PLAITS_DSP_SPEECH_LPC_SPEECH_SYNTH_WORDS_H_
#define PLAITS_DSP_SPEECH_LPC_SPEECH_SYNTH_WORDS_H_

#include "plaits/dsp/speech/lpc_speech_synth_controller.h"

namespace plaits {
"""

let dothFooter = """
extern LPCSpeechSynthWordBankData word_banks_[LPC_SPEECH_SYNTH_NUM_WORD_BANKS];

}  // namespace plaits

#endif  // PLAITS_DSP_SPEECH_LPC_SPEECH_SYNTH_WORDS_H_
"""

let dotccHeader = """
// Copyright 2016 Emilie Gillet.
//
// Author: Emilie Gillet (emilie.o.gillet@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// See http://creativecommons.org/licenses/MIT/ for more information.
//
// -----------------------------------------------------------------------------
//
// LPC10 encoded words extracted from various TI ROMs.

#include "plaits/dsp/speech/lpc_speech_synth_words.h"

namespace plaits {
"""

let dotccFooter = """
}  // namespace plaits
"""
BanksFileParser.main()

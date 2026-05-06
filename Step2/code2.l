import system;
import system'io;
import system'routines;
import extensions;

class VMTranslator
{
    string _currentFileName;
    int    _logicalCounter;
    int    _callCounter;
    object _outputFile;

    constructor new(string outputFileName)
    {
        _outputFile := File.assign(outputFileName).textwriter();
        _logicalCounter := 1;
        _callCounter := 1;
        _currentFileName := "StaticVar"
    }

    handleArithmetic(string command)
    {
        if (command == "add") {
            _outputFile.writeLine("// add");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("AM=M-1");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("A=A-1");
            _outputFile.writeLine("M=D+M")
        }
        else if (command == "sub") {
            _outputFile.writeLine("// sub");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("AM=M-1");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("A=A-1");
            _outputFile.writeLine("M=M-D")
        }
        else if (command == "neg") {
            _outputFile.writeLine("// neg");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("A=M-1");
            _outputFile.writeLine("M=-M")
        }
        else if (command == "and") {
            _outputFile.writeLine("// and");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("AM=M-1");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("A=A-1");
            _outputFile.writeLine("M=D&M")
        }
        else if (command == "or") {
            _outputFile.writeLine("// or");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("AM=M-1");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("A=A-1");
            _outputFile.writeLine("M=D|M")
        }
        else if (command == "not") {
            _outputFile.writeLine("// not");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("A=M-1");
            _outputFile.writeLine("M=!M")
        }
        else if (command == "avg2") {
            _outputFile.writeLine("// avg2");

            _outputFile.writeLine("@SP");
            _outputFile.writeLine("AM=M-1");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@R13");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@SP");
            _outputFile.writeLine("AM=M-1");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@R14");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@R13");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@R14");
            _outputFile.writeLine("D=D+M");

            _outputFile.writeLine("@R15");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@R16");
            _outputFile.writeLine("M=0");

            _outputFile.writeLine("(AVG_LOOP)");

            _outputFile.writeLine("@R15");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@2");
            _outputFile.writeLine("D=D-A");
            _outputFile.writeLine("@AVG_END");
            _outputFile.writeLine("D;JLT");

            _outputFile.writeLine("@R15");
            _outputFile.writeLine("M=M-1");
            _outputFile.writeLine("M=M-1");

            _outputFile.writeLine("@R16");
            _outputFile.writeLine("M=M+1");

            _outputFile.writeLine("@AVG_LOOP");
            _outputFile.writeLine("0;JMP");

            _outputFile.writeLine("(AVG_END)");

            _outputFile.writeLine("@R16");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("A=M");
            _outputFile.writeLine("M=D");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("M=M+1")
        }
    }

    handleComparison(string command)
    {
        string labelTrue := "LABEL_TRUE_" + _logicalCounter.toString();
        string labelEnd  := "LABEL_END_" + _logicalCounter.toString();
        _logicalCounter := _logicalCounter + 1;

        string jmp := "";
        if (command == "eq") { jmp := "JEQ" }
        else if (command == "gt") { jmp := "JGT" }
        else if (command == "lt") { jmp := "JLT" };

        _outputFile.writeLine("// " + command);
        _outputFile.writeLine("@SP");
        _outputFile.writeLine("AM=M-1");
        _outputFile.writeLine("D=M");
        _outputFile.writeLine("A=A-1");
        _outputFile.writeLine("D=M-D");
        _outputFile.writeLine("@" + labelTrue);
        _outputFile.writeLine("D;" + jmp);
        _outputFile.writeLine("@SP");
        _outputFile.writeLine("A=M-1");
        _outputFile.writeLine("M=0");
        _outputFile.writeLine("@" + labelEnd);
        _outputFile.writeLine("0;JMP");
        _outputFile.writeLine("(" + labelTrue + ")");
        _outputFile.writeLine("@SP");
        _outputFile.writeLine("A=M-1");
        _outputFile.writeLine("M=-1");
        _outputFile.writeLine("(" + labelEnd + ")")
    }

    handlePushPop(string command, string segment, string indexStr)
    {
        _outputFile.writeLine("// " + command + " " + segment + " " + indexStr);
       
        if (command == "push")
        {
            if (segment == "constant") {
                _outputFile.writeLine("@" + indexStr); _outputFile.writeLine("D=A");
                _outputFile.writeLine("@SP"); _outputFile.writeLine("A=M"); _outputFile.writeLine("M=D");
                _outputFile.writeLine("@SP"); _outputFile.writeLine("M=M+1")
            }
            else if (segment == "local" || segment == "argument" || segment == "this" || segment == "that") {
                string segPtr := "";
                if (segment == "local") { segPtr := "LCL" }
                else if (segment == "argument") { segPtr := "ARG" }
                else if (segment == "this") { segPtr := "THIS" }
                else { segPtr := "THAT" };
               
                _outputFile.writeLine("@" + indexStr); _outputFile.writeLine("D=A");
                _outputFile.writeLine("@" + segPtr); _outputFile.writeLine("A=M+D"); _outputFile.writeLine("D=M");
                _outputFile.writeLine("@SP"); _outputFile.writeLine("A=M"); _outputFile.writeLine("M=D");
                _outputFile.writeLine("@SP"); _outputFile.writeLine("M=M+1")
            }
            else if (segment == "temp") {
                int val := indexStr.toInt();
                int addr := 5 + val;
                _outputFile.writeLine("@" + addr.toString()); _outputFile.writeLine("D=M");
                _outputFile.writeLine("@SP"); _outputFile.writeLine("A=M"); _outputFile.writeLine("M=D");
                _outputFile.writeLine("@SP"); _outputFile.writeLine("M=M+1")
            }
            else if (segment == "pointer") {
                string ptr := (indexStr == "0") ? "THIS" : "THAT";
                _outputFile.writeLine("@" + ptr); _outputFile.writeLine("D=M");
                _outputFile.writeLine("@SP"); _outputFile.writeLine("A=M"); _outputFile.writeLine("M=D");
                _outputFile.writeLine("@SP"); _outputFile.writeLine("M=M+1")
            }
            else if (segment == "static") {
                _outputFile.writeLine("@" + _currentFileName + "." + indexStr); _outputFile.writeLine("D=M");
                _outputFile.writeLine("@SP"); _outputFile.writeLine("A=M"); _outputFile.writeLine("M=D");
                _outputFile.writeLine("@SP"); _outputFile.writeLine("M=M+1")
            }
        }
        else if (command == "pop")
        {
            if (segment == "local" || segment == "argument" || segment == "this" || segment == "that") {
                string segPtr := "";
                if (segment == "local") { segPtr := "LCL" }
                else if (segment == "argument") { segPtr := "ARG" }
                else if (segment == "this") { segPtr := "THIS" }
                else { segPtr := "THAT" };
               
                _outputFile.writeLine("@" + indexStr); _outputFile.writeLine("D=A");
                _outputFile.writeLine("@" + segPtr); _outputFile.writeLine("D=M+D");
                _outputFile.writeLine("@R13"); _outputFile.writeLine("M=D");
                _outputFile.writeLine("@SP"); _outputFile.writeLine("AM=M-1"); _outputFile.writeLine("D=M");
                _outputFile.writeLine("@R13"); _outputFile.writeLine("A=M"); _outputFile.writeLine("M=D")
            }
            else if (segment == "temp") {
                int val := indexStr.toInt();
                int addr := 5 + val;
                _outputFile.writeLine("@SP"); _outputFile.writeLine("AM=M-1"); _outputFile.writeLine("D=M");
                _outputFile.writeLine("@" + addr.toString()); _outputFile.writeLine("M=D")
            }
            else if (segment == "pointer") {
                string ptr := (indexStr == "0") ? "THIS" : "THAT";
                _outputFile.writeLine("@SP"); _outputFile.writeLine("AM=M-1"); _outputFile.writeLine("D=M");
                _outputFile.writeLine("@" + ptr); _outputFile.writeLine("M=D")
            }
            else if (segment == "static") {
                _outputFile.writeLine("@SP"); _outputFile.writeLine("AM=M-1"); _outputFile.writeLine("D=M");
                _outputFile.writeLine("@" + _currentFileName + "." + indexStr); _outputFile.writeLine("M=D")
            }
        }
    }

    handleProgramFlow(string command, string labelName)
    {
        _outputFile.writeLine("// " + command + " " + labelName);

        if (command == "label") {
            _outputFile.writeLine("(" + labelName + ")")
        }
        else if (command == "goto") {
            _outputFile.writeLine("@" + labelName);
            _outputFile.writeLine("0;JMP")
        }
        else if (command == "if-goto") {
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("AM=M-1");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@" + labelName);
            _outputFile.writeLine("D;JNE")
        }
    }

    handleFunctionCallReturn(string command, string arg1, string arg2)
    {
        if (command == "function") {
            _outputFile.writeLine("// function " + arg1 + " " + arg2);
            _outputFile.writeLine("(" + arg1 + ")");
            int numLocals := arg2.toInt();
            int i := 0;
            while (i < numLocals) {
                _outputFile.writeLine("@SP");
                _outputFile.writeLine("A=M");
                _outputFile.writeLine("M=0");
                _outputFile.writeLine("@SP");
                _outputFile.writeLine("M=M+1");
                i := i + 1
            }
        }
        else if (command == "call") {
            string returnLabel := arg1 + "$ret." + _callCounter.toString();
            _callCounter := _callCounter + 1;

            _outputFile.writeLine("// call " + arg1 + " " + arg2);

            _outputFile.writeLine("@" + returnLabel);
            _outputFile.writeLine("D=A");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("A=M");
            _outputFile.writeLine("M=D");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("M=M+1");

            _outputFile.writeLine("@LCL");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("A=M");
            _outputFile.writeLine("M=D");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("M=M+1");

            _outputFile.writeLine("@ARG");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("A=M");
            _outputFile.writeLine("M=D");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("M=M+1");

            _outputFile.writeLine("@THIS");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("A=M");
            _outputFile.writeLine("M=D");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("M=M+1");

            _outputFile.writeLine("@THAT");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("A=M");
            _outputFile.writeLine("M=D");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("M=M+1");

            _outputFile.writeLine("@SP");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@" + arg2);
            _outputFile.writeLine("D=D-A");
            _outputFile.writeLine("@5");
            _outputFile.writeLine("D=D-A");
            _outputFile.writeLine("@ARG");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@SP");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@LCL");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@" + arg1);
            _outputFile.writeLine("0;JMP");

            _outputFile.writeLine("(" + returnLabel + ")")
        }
        else if (command == "return") {
            _outputFile.writeLine("// return");

            _outputFile.writeLine("@LCL");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@R14");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@5");
            _outputFile.writeLine("A=D-A");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@R15");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@SP");
            _outputFile.writeLine("AM=M-1");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@ARG");
            _outputFile.writeLine("A=M");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@ARG");
            _outputFile.writeLine("D=M+1");
            _outputFile.writeLine("@SP");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@R14");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@1");
            _outputFile.writeLine("A=D-A");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@THAT");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@R14");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@2");
            _outputFile.writeLine("A=D-A");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@THIS");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@R14");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@3");
            _outputFile.writeLine("A=D-A");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@ARG");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@R14");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@4");
            _outputFile.writeLine("A=D-A");
            _outputFile.writeLine("D=M");
            _outputFile.writeLine("@LCL");
            _outputFile.writeLine("M=D");

            _outputFile.writeLine("@R15");
            _outputFile.writeLine("A=M");
            _outputFile.writeLine("0;JMP")
        }
    }

    writeBootstrap()
    {
        _outputFile.writeLine("// Bootstrap");
        _outputFile.writeLine("@256");
        _outputFile.writeLine("D=A");
        _outputFile.writeLine("@SP");
        _outputFile.writeLine("M=D");
        handleFunctionCallReturn("call", "Sys.init", "0")
    }

    processSingleLine(string textLine)
    {
        string cleanLine := "";
        int ci := 0;
        while (ci < textLine.Length) {
            int ch := textLine[ci];
            if (ch == 9 || ch == 160) { cleanLine := cleanLine + " " }
            else { cleanLine := cleanLine + textLine.Substring(ci, 1) };
            ci := ci + 1
        };
        string line := cleanLine.trim();

        if (line.Length > 0)
        {
            int commentIdx := line.indexOf(0, "//");
            if (commentIdx == 0) { line := "" }
            else if (commentIdx > 0) { line := line.Substring(0, commentIdx).trim() };

            if (line.Length > 0)
            {
                string cmd  := "";
                string arg1 := "";
                string arg2 := "";
                int wordCount := 0;
                int wi := 0;
                string currentWord := "";

                while (wi < line.Length) {
                    int wch := line[wi];
                    if (wch == 32) {
                        if (currentWord.Length > 0) {
                            if (wordCount == 0) { cmd := currentWord }
                            else if (wordCount == 1) { arg1 := currentWord }
                            else if (wordCount == 2) { arg2 := currentWord };
                            wordCount := wordCount + 1;
                            currentWord := ""
                        }
                    }
                    else {
                        currentWord := currentWord + line.Substring(wi, 1)
                    };
                    wi := wi + 1
                };
                if (currentWord.Length > 0) {
                    if (wordCount == 0) { cmd := currentWord }
                    else if (wordCount == 1) { arg1 := currentWord }
                    else if (wordCount == 2) { arg2 := currentWord };
                    wordCount := wordCount + 1
                };

                console.writeLine("DEBUG: Parsed -> cmd=[" + cmd + "] arg1=[" + arg1 + "] arg2=[" + arg2 + "]");

                if (cmd == "add" || cmd == "sub" || cmd == "neg" || cmd == "and" || cmd == "or" || cmd == "not" || cmd == "avg2")
                { handleArithmetic(cmd) }
                else if (cmd == "eq" || cmd == "gt" || cmd == "lt")
                { handleComparison(cmd) }
                else if (cmd == "push" || cmd == "pop")
                { if (wordCount > 2) { handlePushPop(cmd, arg1, arg2) } }
                else if (cmd == "label" || cmd == "goto" || cmd == "if-goto")
                { if (wordCount > 1) { handleProgramFlow(cmd, arg1) } }
                else if (cmd == "function")
                { if (wordCount > 2) { handleFunctionCallReturn(cmd, arg1, arg2) } }
                else if (cmd == "call")
                { if (wordCount > 2) { handleFunctionCallReturn(cmd, arg1, arg2) } }
                else if (cmd == "return")
                { handleFunctionCallReturn(cmd, "", "") }
            }
        }
    }

    translateFile(string fullPath)
    {
        int pos := 0;
        int lastSlash := 0;
        while (pos < fullPath.Length) {
            int code := fullPath[pos];
            if (code == 92 || code == 47) { lastSlash := pos + 1 };
            pos := pos + 1
        };
        string nameWithExt := fullPath.Substring(lastSlash, fullPath.Length - lastSlash);
       
        int dotPos := nameWithExt.Length;
        pos := 0;
        while (pos < nameWithExt.Length) {
            if (nameWithExt[pos] == 46) { dotPos := pos };
            pos := pos + 1
        };
        _currentFileName := nameWithExt.Substring(0, dotPos);

        console.writeLine("======================================");
        console.writeLine("DEBUG: Start processing file -> " + fullPath);
       
        var reader := File.assign(fullPath).textreader();
       
        while (reader.Available)
        {
            var rawLine := reader.readLine();
            if (nil != rawLine) {
                string fullText := rawLine.toString();
                string singleLine := "";
                int charIndex := 0;
               
                while (charIndex < fullText.Length) {
                    int ch := fullText[charIndex];
                   
                    if (ch == 10 || ch == 13) {
                        if (singleLine.Length > 0) {
                            processSingleLine(singleLine.trim());
                            singleLine := ""
                        }
                    } else {
                        singleLine := singleLine + fullText.Substring(charIndex, 1)
                    };
                    charIndex := charIndex + 1
                };
               
                if (singleLine.Length > 0) {
                    processSingleLine(singleLine.trim())
                }
            }
        };
       
        console.writeLine("DEBUG: Finished processing.");
        console.writeLine("======================================");
        reader.close()
    }

    close() {
        _outputFile.close()
    }
}

public program()
{
    console.write("Enter path (file or directory): ");
    string path := console.readLine();
   
    string cleanPath := "";
    int pi := 0;
    while (pi < path.Length) {
        int pc := path[pi];
        if (pc != 34 && pc != 13 && pc != 10) {
            cleanPath := cleanPath + path.Substring(pi, 1)
        };
        pi := pi + 1
    };
   
    int clen := cleanPath.Length;
    if (clen > 0) {
        int lastChar := cleanPath[clen - 1];
        if (lastChar == 92 || lastChar == 47) {
            cleanPath := cleanPath.Substring(0, clen - 1)
        }
    };
   
    path := cleanPath;
    console.writeLine("DEBUG PATH: [" + path + "]");

    bool isSingleFile := false;
    if (path.Length > 3) {
        string ext := path.Substring(path.Length - 3, 3);
        if (ext == ".vm") { isSingleFile := true }
    };

    if (isSingleFile) {
        string outPath := path.Substring(0, path.Length - 3) + ".asm";
        var translator := VMTranslator.new(outPath);
       
        try {
            translator.translateFile(path)
        }
        catch(Exception e) {
            console.writeLine("CRASH CAUGHT: " + e.Message)
        };
       
        translator.close();
       
        console.writeLine("Processed single file: " + path);
        console.writeLine("Done! Created: " + outPath);
        console.readChar()
    }
    else {
        int pLen := path.Length;
        int dirPos := 0;
        int lastDirSlash := 0;
        while (dirPos < pLen) {
            int dc := path[dirPos];
            if (dc == 92 || dc == 47) { lastDirSlash := dirPos + 1 };
            dirPos := dirPos + 1
        };
        string dirName := path.Substring(lastDirSlash, pLen - lastDirSlash);

        if (dirName.Length == 0) { dirName := "Output" };

        string outPath := path + "\\";
        outPath := outPath + dirName;
        outPath := outPath + ".asm";
       
        var translator := VMTranslator.new(outPath);
        var files := Directory.assign(path).getFiles();
        int count := files.Length;

        bool hasSys := false;
        for (int i := 0; i < count; i := i + 1)
        {
            string f := files[i].toString();
            int flen := f.Length;
            if (flen >= 6) {
                string tail := f.Substring(flen - 6, 6);
                if (tail == "Sys.vm") { hasSys := true }
            }
        };
       
        if (hasSys) { translator.writeBootstrap() };

        for (int i := 0; i < count; i := i + 1)
        {
            string currentFile := files[i].toString();
            if (currentFile.Length > 3)
            {
                string ext := currentFile.Substring(currentFile.Length - 3, 3);
                if (ext == ".vm")
                {
                    try {
                        translator.translateFile(currentFile);
                        console.writeLine("Processed file: " + currentFile)
                    }
                    catch(Exception e) {
                        console.writeLine("CRASH CAUGHT on file " + currentFile + ": " + e.Message)
                    }
                }
            }
        };

        translator.close();
        console.write("Done! Created: ");
        console.writeLine(dirName + ".asm");
        console.readChar()
    }
}

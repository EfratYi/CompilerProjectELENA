import system;
import system'io;
import system'routines;
import extensions;

class VMTranslator
{
    string _currentFileName;
    int    _logicalCounter;
    object _outputFile;

    constructor new(string outputFileName)
    {
        _outputFile := File.assign(outputFileName).textwriter();
        _logicalCounter := 1;
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

        var reader := File.assign(fullPath).textreader();
        
        while (reader.Available)
        {
            string line := reader.readLine().trim();

            // החלפת tabs ברווחים
            string cleanLine := "";
            int ci := 0;
            while (ci < line.Length) {
                int ch := line[ci];
                if (ch == 9) { cleanLine := cleanLine + " " }
                else { cleanLine := cleanLine + line.Substring(ci, 1) };
                ci := ci + 1
            };
            line := cleanLine.trim();

            if (line.Length > 0)
            {
                int commentIdx := line.indexOf(0, "//");
                if (commentIdx == 0) { line := "" }
                else if (commentIdx > 0) { line := line.Substring(0, commentIdx).trim() };

                if (line.Length > 0)
                {
                    // פיצול מילים תוך דילוג על רווחים כפולים
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
                    // המילה האחרונה
                    if (currentWord.Length > 0) {
                        if (wordCount == 0) { cmd := currentWord }
                        else if (wordCount == 1) { arg1 := currentWord }
                        else if (wordCount == 2) { arg2 := currentWord };
                        wordCount := wordCount + 1
                    };

                    if (cmd == "add" || cmd == "sub" || cmd == "neg" || cmd == "and" || cmd == "or" || cmd == "not" || cmd == "avg2") 
                    { 
                        handleArithmetic(cmd) 
                    }
                    else if (cmd == "eq" || cmd == "gt" || cmd == "lt") 
                    { 
                        handleComparison(cmd) 
                    }
                    else if (cmd == "push" || cmd == "pop") 
                    { 
                        if (wordCount > 2)
                        {
                            handlePushPop(cmd, arg1, arg2)
                        }
                    }
                    else if (cmd == "label" || cmd == "goto" || cmd == "if-goto")
                    {
                        if (wordCount > 1)
                        {
                            handleProgramFlow(cmd, arg1)
                        }
                    }
                }
            }
        };
        reader.close()
    }

    close() { _outputFile.close() }
}

public program()
{
    console.write("Enter directory path: ");
    string path := console.readLine();
    
    string cleanPath := "";
    int pi := 0;
    while (pi < path.Length) {
        int pc := path[pi];
        if (pc != 34) { cleanPath := cleanPath + path.Substring(pi, 1) };
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
    
    for (int i := 0; i < count; i := i + 1)
    {
        string currentFile := files[i].toString();
        if (currentFile.Length > 3)
        {
            string ext := currentFile.Substring(currentFile.Length - 3, 3);
            if (ext == ".vm")
            {
                translator.translateFile(currentFile);
                console.writeLine("Processed file: " + currentFile)
            }
        }
    };

    translator.close();
    console.write("Done! Created: ");
    console.writeLine(dirName + ".asm");
    console.readChar()
}

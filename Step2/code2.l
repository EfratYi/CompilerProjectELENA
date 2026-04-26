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

    // pop y
    _outputFile.writeLine("@SP");
    _outputFile.writeLine("AM=M-1");
    _outputFile.writeLine("D=M");
    _outputFile.writeLine("@R13");
    _outputFile.writeLine("M=D");

    // pop x
    _outputFile.writeLine("@SP");
    _outputFile.writeLine("AM=M-1");
    _outputFile.writeLine("D=M");
    _outputFile.writeLine("@R14");
    _outputFile.writeLine("M=D");

    // sum = x + y
    _outputFile.writeLine("@R13");
    _outputFile.writeLine("D=M");
    _outputFile.writeLine("@R14");
    _outputFile.writeLine("D=D+M");

    _outputFile.writeLine("@R15");
    _outputFile.writeLine("M=D");   // R15 = sum

    // result = 0
    _outputFile.writeLine("@R16");
    _outputFile.writeLine("M=0");

    // divisor = 2 counter simulation
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

    // push result
    _outputFile.writeLine("@R16");
    _outputFile.writeLine("D=M");
    _outputFile.writeLine("@SP");
    _outputFile.writeLine("A=M");
    _outputFile.writeLine("M=D");
    _outputFile.writeLine("@SP");
    _outputFile.writeLine("M=M+1");
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
    //step2
handleProgramFlow(string command, string labelName)
{
    string fullLabel := _currentFileName + "." + labelName;

    _outputFile.writeLine("// " + command + " " + labelName);

    if (command == "label") {
        _outputFile.writeLine("(" + fullLabel + ")");
    }
    else if (command == "goto") {
        _outputFile.writeLine("@" + fullLabel);
        _outputFile.writeLine("0;JMP");
    }
    else if (command == "if-goto") {
        _outputFile.writeLine("@SP");
        _outputFile.writeLine("AM=M-1");
        _outputFile.writeLine("D=M");
        _outputFile.writeLine("@" + fullLabel);
        _outputFile.writeLine("D;JNE");
    }
}
handleFunction(string functionName, string nVarsStr)
{
    int nVars := nVarsStr.toInt();

    _outputFile.writeLine("// function " + functionName);
    _outputFile.writeLine("(" + functionName + ")");

    int i := 0;
    while (i < nVars)
    {
        _outputFile.writeLine("@0");
        _outputFile.writeLine("D=A");
        _outputFile.writeLine("@SP");
        _outputFile.writeLine("A=M");
        _outputFile.writeLine("M=D");
        _outputFile.writeLine("@SP");
        _outputFile.writeLine("M=M+1");

        i := i + 1;
    }
}
handleCall(string functionName, string nArgsStr)
{
    string returnLabel := "RETURN_" + _logicalCounter.toString();
    _logicalCounter := _logicalCounter + 1;

    _outputFile.writeLine("// call " + functionName);

    // push return address
    _outputFile.writeLine("@" + returnLabel);
    _outputFile.writeLine("D=A");
    _outputFile.writeLine("@SP");
    _outputFile.writeLine("A=M");
    _outputFile.writeLine("M=D");
    _outputFile.writeLine("@SP");
    _outputFile.writeLine("M=M+1");

    // push LCL ARG THIS THAT
    var segs := "LCL ARG THIS THAT".splitBy(" ");
    int i := 0;
    while (i < 4)
    {
        _outputFile.writeLine("@" + segs[i]);
        _outputFile.writeLine("D=M");
        _outputFile.writeLine("@SP");
        _outputFile.writeLine("A=M");
        _outputFile.writeLine("M=D");
        _outputFile.writeLine("@SP");
        _outputFile.writeLine("M=M+1");

        i := i + 1;
    }

    // ARG = SP - 5 - nArgs
    _outputFile.writeLine("@SP");
    _outputFile.writeLine("D=M");
    _outputFile.writeLine("@5");
    _outputFile.writeLine("D=D-A");
    _outputFile.writeLine("@" + nArgsStr);
    _outputFile.writeLine("D=D-A");
    _outputFile.writeLine("@ARG");
    _outputFile.writeLine("M=D");

    // LCL = SP
    _outputFile.writeLine("@SP");
    _outputFile.writeLine("D=M");
    _outputFile.writeLine("@LCL");
    _outputFile.writeLine("M=D");

    // goto function
    _outputFile.writeLine("@" + functionName);
    _outputFile.writeLine("0;JMP");

    _outputFile.writeLine("(" + returnLabel + ")");
}
handleReturn()
{
    _outputFile.writeLine("// return");

    // FRAME = LCL
    _outputFile.writeLine("@LCL");
    _outputFile.writeLine("D=M");
    _outputFile.writeLine("@R13");
    _outputFile.writeLine("M=D");

    // RET = *(FRAME-5)
    _outputFile.writeLine("@5");
    _outputFile.writeLine("A=D-A");
    _outputFile.writeLine("D=M");
    _outputFile.writeLine("@R14");
    _outputFile.writeLine("M=D");

    // *ARG = pop()
    _outputFile.writeLine("@SP");
    _outputFile.writeLine("AM=M-1");
    _outputFile.writeLine("D=M");
    _outputFile.writeLine("@ARG");
    _outputFile.writeLine("A=M");
    _outputFile.writeLine("M=D");

    // SP = ARG + 1
    _outputFile.writeLine("@ARG");
    _outputFile.writeLine("D=M+1");
    _outputFile.writeLine("@SP");
    _outputFile.writeLine("M=D");

    // restore THAT THIS ARG LCL
    var segs := "THAT THIS ARG LCL".splitBy(" ");
    int i := 0;

    while (i < 4)
    {
        _outputFile.writeLine("@R13");
        _outputFile.writeLine("AM=M-1");
        _outputFile.writeLine("D=M");
        _outputFile.writeLine("@" + segs[i]);
        _outputFile.writeLine("M=D");

        i := i + 1;
    }

    // goto RET
    _outputFile.writeLine("@R14");
    _outputFile.writeLine("A=M");
    _outputFile.writeLine("0;JMP");
}
    translateFile(string fullPath)
    {
        // חילוץ שם הקובץ ללא סיומת עבור משתנים סטטיים
        int pos := 0;
        int lastSlash := 0;
        while (pos < fullPath.Length) {
            int code := fullPath[pos];
            if (code == 92 || code == 47) { lastSlash := pos + 1 }; // חיפוש לוכסן
            pos := pos + 1
        };
        string nameWithExt := fullPath.Substring(lastSlash, fullPath.Length - lastSlash);
        
        int dotPos := nameWithExt.Length;
        pos := 0;
        while (pos < nameWithExt.Length) {
            if (nameWithExt[pos] == 46) { dotPos := pos }; // חיפוש נקודה
            pos := pos + 1
        };
        _currentFileName := nameWithExt.Substring(0, dotPos);

        // קריאת הקובץ ותרגום
        var reader := File.assign(fullPath).textreader();
        
        while (reader.Available)
        {
            string line := reader.readLine().trim();
            
            if (line.isEmpty() == false)
            {
                int commentIdx := line.indexOf(0, "//");
                if (commentIdx == 0) { line := "" }
                else if (commentIdx > 0) { line := line.Substring(0, commentIdx).trim() };

                if (line.Length > 0)
                {
                    var words := line.splitBy(" ");
                    string cmd := words[0];

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
                        if (words.Length > 2)
                        {
                            handlePushPop(cmd, words[1], words[2])
                        }
                    }
                    else if (cmd == "label" || cmd == "goto" || cmd == "if-goto")
                    {
                        if (words.Length > 1)
                        {
                           handleProgramFlow(cmd, words[1])
                        }
                    }
                    else if (cmd == "function")
{
    handleFunction(words[1], words[2])
}
else if (cmd == "call")
{
    handleCall(words[1], words[2])
}
else if (cmd == "return")
{
    handleReturn()
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
    
    // ניקוי המרכאות מהנתיב במקרה של העתקה מווינדוס
    string cleanPath := "";
    int pi := 0;
    while (pi < path.Length) {
        int pc := path[pi];
        if (pc != 34) { cleanPath := cleanPath + path.Substring(pi, 1) };
        pi := pi + 1
    };
    
    // מחיקת לוכסן סופי במקרה שהמשתמש העתיק נתיב עם \ בסוף
    int clen := cleanPath.Length;
    if (clen > 0) {
        int lastChar := cleanPath[clen - 1];
        if (lastChar == 92 || lastChar == 47) {
            cleanPath := cleanPath.Substring(0, clen - 1)
        }
    };
    
    path := cleanPath;

    // מציאת שם התיקייה מתוך הנתיב המנוקה
    int pLen := path.Length;
    int dirPos := 0;
    int lastDirSlash := 0;
    while (dirPos < pLen) {
        int dc := path[dirPos];
        if (dc == 92 || dc == 47) { lastDirSlash := dirPos + 1 };
        dirPos := dirPos + 1
    };
    string dirName := path.Substring(lastDirSlash, pLen - lastDirSlash);

    // הגנה למקרה חריג
    if (dirName.Length == 0) { dirName := "Output" };

    // בניה בטוחה של נתיב הפלט בשלבים - למניעת שגיאת קומפילציה!
    string outPath := path + "\\";
    outPath := outPath + dirName;
    outPath := outPath + ".asm";
    
    var translator := VMTranslator.new(outPath);
    // bootstrap
    translator._outputFile.writeLine("// bootstrap");
    translator._outputFile.writeLine("@256");
    translator._outputFile.writeLine("D=A");
    translator._outputFile.writeLine("@SP");
    translator._outputFile.writeLine("M=D");

// call Sys.init 0
translator._outputFile.writeLine("@RETURN_BOOTSTRAP");
translator._outputFile.writeLine("D=A");
translator._outputFile.writeLine("@SP");
translator._outputFile.writeLine("A=M");
translator._outputFile.writeLine("M=D");
translator._outputFile.writeLine("@SP");
translator._outputFile.writeLine("M=M+1");

// push LCL ARG THIS THAT
var segs := "LCL ARG THIS THAT".splitBy(" ");
int i := 0;
while (i < 4)
{
    translator._outputFile.writeLine("@" + segs[i]);
    translator._outputFile.writeLine("D=M");
    translator._outputFile.writeLine("@SP");
    translator._outputFile.writeLine("A=M");
    translator._outputFile.writeLine("M=D");
    translator._outputFile.writeLine("@SP");
    translator._outputFile.writeLine("M=M+1");

    i := i + 1;
}

// ARG = SP - 5
translator._outputFile.writeLine("@SP");
translator._outputFile.writeLine("D=M");
translator._outputFile.writeLine("@5");
translator._outputFile.writeLine("D=D-A");
translator._outputFile.writeLine("@ARG");
translator._outputFile.writeLine("M=D");

// LCL = SP
translator._outputFile.writeLine("@SP");
translator._outputFile.writeLine("D=M");
translator._outputFile.writeLine("@LCL");
translator._outputFile.writeLine("M=D");

// goto Sys.init
translator._outputFile.writeLine("@Sys.init");
translator._outputFile.writeLine("0;JMP");

// return label
translator._outputFile.writeLine("(RETURN_BOOTSTRAP)");
    var files := Directory.assign(path).getFiles();
    int count := files.Length;
    
    for (int i := 0; i < count; i := i + 1)
    {
        string currentFile := files[i].toString();
        
        if (currentFile.indexOf(0, ".vm") != -1) 
        {
            translator.translateFile(currentFile);
            console.writeLine("Processed file: " + currentFile)
        }
    };

    translator.close();
    console.write("Done! Created: ");
    console.writeLine(dirName + ".asm");
    console.readChar()
}
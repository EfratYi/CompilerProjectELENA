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
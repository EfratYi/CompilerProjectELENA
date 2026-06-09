import system'io;
import system'collections;
import extensions;

class JackTokenizer
{
    object _inputFile;
    ArrayList _keywords;
    string _symbols;
    bool _inBlockComment;

    constructor new(string inputFileName)
    {
        _inputFile := File.assign(inputFileName).textreader();

        _keywords := new ArrayList();

        _keywords.append("class");
        _keywords.append("constructor");
        _keywords.append("function");
        _keywords.append("method");
        _keywords.append("field");
        _keywords.append("static");
        _keywords.append("var");
        _keywords.append("int");
        _keywords.append("char");
        _keywords.append("boolean");
        _keywords.append("void");
        _keywords.append("true");
        _keywords.append("false");
        _keywords.append("null");
        _keywords.append("this");
        _keywords.append("let");
        _keywords.append("do");
        _keywords.append("if");
        _keywords.append("else");
        _keywords.append("while");
        _keywords.append("return");

        _symbols := "{}()[].,;+-*/&|<>=~";
        _inBlockComment := false;
    }

    bool isKeyword(string token)
    {
        int len := _keywords.Length;

        for (int i := 0; i < len; i := i + 1)
        {
            if (_keywords[i].toString() == token)
            {
                ^ true
            }
        };

        ^ false
    }

    bool isSymbol(string ch)
    {
        int idx := _symbols.indexOf(0, ch);

        if (idx >= 0)
        {
            ^ true
        };

        ^ false
    }

    string escapeXmlSymbol(string symbol)
    {
        string res := symbol;

        if (symbol == "<")
        {
            res := "&lt;"
        };

        if (symbol == ">")
        {
            res := "&gt;"
        };

        if (symbol == "&")
        {
            res := "&amp;"
        };

        ^ res
    }

    string cleanComments(string line)
    {
        string result := line.trim();

        bool done := false;

        while (done == false)
        {
            if (_inBlockComment)
            {
                int endBlock := result.indexOf(0, "*/");

                if (endBlock >= 0)
                {
                    result := result.Substring(endBlock + 2, result.Length - (endBlock + 2)).trim();
                    _inBlockComment := false
                }
                else
                {
                    result := "";
                    done := true
                }
            }
            else
            {
                int lineComment := result.indexOf(0, "//");
                int startBlock := result.indexOf(0, "/*");

                if (lineComment >= 0)
                {
                    if (startBlock >= 0)
                    {
                        if (lineComment < startBlock)
                        {
                            result := result.Substring(0, lineComment).trim();
                            done := true
                        }
                        else
                        {
                            int endBlock2 := result.indexOf(0, "*/");

                            if (endBlock2 >= 0)
                            {
                                string part1 := result.Substring(0, startBlock);
                                string part2 := result.Substring(endBlock2 + 2, result.Length - (endBlock2 + 2));
                                result := (part1 + part2).trim()
                            }
                            else
                            {
                                result := result.Substring(0, startBlock).trim();
                                _inBlockComment := true;
                                done := true
                            }
                        }
                    }
                    else
                    {
                        result := result.Substring(0, lineComment).trim();
                        done := true
                    }
                }
                else
                {
                    if (startBlock >= 0)
                    {
                        int endBlock3 := result.indexOf(0, "*/");

                        if (endBlock3 >= 0)
                        {
                            string part3 := result.Substring(0, startBlock);
                            string part4 := result.Substring(endBlock3 + 2, result.Length - (endBlock3 + 2));
                            result := (part3 + part4).trim()
                        }
                        else
                        {
                            result := result.Substring(0, startBlock).trim();
                            _inBlockComment := true;
                            done := true
                        }
                    }
                    else
                    {
                        done := true
                    }
                }
            }
        };

        ^ result
    }

    processSingleLine(string sourceLine, ArrayList tokensList)
    {
        string line := cleanComments(sourceLine);

        if (line.Length > 0)
        {
            int i := 0;

            while (i < line.Length)
            {
                string ch := line.Substring(i, 1);
                int ascii := line[i];

                if (ascii == 32)
                {
                    i := i + 1
                }
                else
                {
                    if (ascii == 9)
                    {
                        i := i + 1
                    }
                    else
                    {
                        if (isSymbol(ch))
                        {
                            string escaped := escapeXmlSymbol(ch);

                            tokensList.append(
                                "<symbol> " +
                                escaped +
                                " </symbol>"
                            );

                            i := i + 1
                        }
                        else
                        {
                            if (ascii == 34)
                            {
                                i := i + 1;

                                string strConst := "";
                                bool foundEndQuote := false;

                                while (foundEndQuote == false)
                                {
                                    if (i < line.Length)
                                    {
                                        if (line[i] == 34)
                                        {
                                            foundEndQuote := true
                                        }
                                        else
                                        {
                                            strConst := strConst + line.Substring(i, 1)
                                        };

                                        i := i + 1
                                    }
                                    else
                                    {
                                        foundEndQuote := true
                                    }
                                };

                                tokensList.append(
                                    "<stringConstant> " +
                                    strConst +
                                    " </stringConstant>"
                                )
                            }
                            else
                            {
                                if (ascii >= 48)
                                {
                                    if (ascii <= 57)
                                    {
                                        string intConst := "";
                                        bool continueDigits := true;

                                        while (continueDigits)
                                        {
                                            if (i < line.Length)
                                            {
                                                if (line[i] >= 48)
                                                {
                                                    if (line[i] <= 57)
                                                    {
                                                        intConst := intConst + line.Substring(i, 1);
                                                        i := i + 1
                                                    }
                                                    else
                                                    {
                                                        continueDigits := false
                                                    }
                                                }
                                                else
                                                {
                                                    continueDigits := false
                                                }
                                            }
                                            else
                                            {
                                                continueDigits := false
                                            }
                                        };

                                        tokensList.append(
                                            "<integerConstant> " +
                                            intConst +
                                            " </integerConstant>"
                                        )
                                    }
                                    else
                                    {
                                        string idOrKey := "";
                                        bool stopWord := false;

                                        while (stopWord == false)
                                        {
                                            if (i < line.Length)
                                            {
                                                string nextCh := line.Substring(i, 1);
                                                int nextAscii := line[i];

                                                if (nextAscii == 32)
                                                {
                                                    stopWord := true
                                                }
                                                else
                                                {
                                                    if (nextAscii == 9)
                                                    {
                                                        stopWord := true
                                                    }
                                                    else
                                                    {
                                                        if (isSymbol(nextCh))
                                                        {
                                                            stopWord := true
                                                        }
                                                        else
                                                        {
                                                            idOrKey := idOrKey + nextCh;
                                                            i := i + 1
                                                        }
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                stopWord := true
                                            }
                                        };

                                        if (idOrKey.Length > 0)
                                        {
                                            if (isKeyword(idOrKey))
                                            {
                                                tokensList.append(
                                                    "<keyword> " +
                                                    idOrKey +
                                                    " </keyword>"
                                                )
                                            }
                                            else
                                            {
                                                tokensList.append(
                                                    "<identifier> " +
                                                    idOrKey +
                                                    " </identifier>"
                                                )
                                            }
                                        }
                                    }
                                }
                                else
                                {
                                    string idOrKey2 := "";
                                    bool stopWord2 := false;

                                    while (stopWord2 == false)
                                    {
                                        if (i < line.Length)
                                        {
                                            string nextCh2 := line.Substring(i, 1);
                                            int nextAscii2 := line[i];

                                            if (nextAscii2 == 32)
                                            {
                                                stopWord2 := true
                                            }
                                            else
                                            {
                                                if (nextAscii2 == 9)
                                                {
                                                    stopWord2 := true
                                                }
                                                else
                                                {
                                                    if (isSymbol(nextCh2))
                                                    {
                                                        stopWord2 := true
                                                    }
                                                    else
                                                    {
                                                        idOrKey2 := idOrKey2 + nextCh2;
                                                        i := i + 1
                                                    }
                                                }
                                            }
                                        }
                                        else
                                        {
                                            stopWord2 := true
                                        }
                                    };

                                    if (idOrKey2.Length > 0)
                                    {
                                        if (isKeyword(idOrKey2))
                                        {
                                            tokensList.append(
                                                "<keyword> " +
                                                idOrKey2 +
                                                " </keyword>"
                                            )
                                        }
                                        else
                                        {
                                            tokensList.append(
                                                "<identifier> " +
                                                idOrKey2 +
                                                " </identifier>"
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ArrayList tokenizeToArray()
    {
        var tokensList := new ArrayList();

        while (_inputFile.Available)
        {
            var rawLine := _inputFile.readLine();

            if (nil != rawLine)
            {
                string rawText := rawLine.toString();
                string oneLine := "";

                int ri := 0;

                while (ri < rawText.Length)
                {
                    int c := rawText[ri];

                    if (c == 13)
                    {
                        processSingleLine(oneLine, tokensList);
                        oneLine := ""
                    }
                    else
                    {
                        if (c == 10)
                        {
                            processSingleLine(oneLine, tokensList);
                            oneLine := ""
                        }
                        else
                        {
                            oneLine := oneLine + rawText.Substring(ri, 1)
                        }
                    };

                    ri := ri + 1
                };

                if (oneLine.Length > 0)
                {
                    processSingleLine(oneLine, tokensList)
                }
            }
        };

        _inputFile.close();

        ^ tokensList
    }
}
class SymbolInfo
{
    string _name;
    string _type;
    string _kind;
    int _index;

    constructor new(string name, string typeName, string kindName, int indexValue)
    {
        _name := name;
        _type := typeName;
        _kind := kindName;
        _index := indexValue
    }

    string getName()
    {
        ^ _name
    }

    string getType()
    {
        ^ _type
    }

    string getKind()
    {
        ^ _kind
    }

    int getIndex()
    {
        ^ _index
    }
}

class SymbolTable
{
    ArrayList _classTable;
    ArrayList _subTable;

    int _staticCount;
    int _fieldCount;
    int _argCount;
    int _varCount;

    constructor new()
    {
        _classTable := new ArrayList();
        _subTable := new ArrayList();

        _staticCount := 0;
        _fieldCount := 0;
        _argCount := 0;
        _varCount := 0
    }

    startSubroutine()
    {
        _subTable := new ArrayList();
        _argCount := 0;
        _varCount := 0
    }

    define(string name, string typeName, string kindName)
    {
        int indexValue := 0;

        if (kindName == "static")
        {
            indexValue := _staticCount;
            _staticCount := _staticCount + 1;
            _classTable.append(SymbolInfo.new(name, typeName, kindName, indexValue))
        }
        else
        {
            if (kindName == "field")
            {
                indexValue := _fieldCount;
                _fieldCount := _fieldCount + 1;
                _classTable.append(SymbolInfo.new(name, typeName, kindName, indexValue))
            }
            else
            {
                if (kindName == "argument")
                {
                    indexValue := _argCount;
                    _argCount := _argCount + 1;
                    _subTable.append(SymbolInfo.new(name, typeName, kindName, indexValue))
                }
                else
                {
                    if (kindName == "var")
                    {
                        indexValue := _varCount;
                        _varCount := _varCount + 1;
                        _subTable.append(SymbolInfo.new(name, typeName, kindName, indexValue))
                    }
                }
            }
        }
    }

    int varCount(string kindName)
    {
        if (kindName == "static")
        {
            ^ _staticCount
        };

        if (kindName == "field")
        {
            ^ _fieldCount
        };

        if (kindName == "argument")
        {
            ^ _argCount
        };

        if (kindName == "var")
        {
            ^ _varCount
        };

        ^ 0
    }

    SymbolInfo findInList(ArrayList table, string name)
    {
        int len := table.Length;

        for (int i := 0; i < len; i := i + 1)
        {
            var item := table[i];

            if (item.getName() == name)
            {
                ^ item
            }
        };

        ^ nil
    }

    SymbolInfo find(string name)
    {
        var subItem := findInList(_subTable, name);

        if (nil != subItem)
        {
            ^ subItem
        };

        var classItem := findInList(_classTable, name);

        if (nil != classItem)
        {
            ^ classItem
        };

        ^ nil
    }

    string kindOf(string name)
    {
        var item := find(name);

        if (nil != item)
        {
            ^ item.getKind()
        };

        ^ "none"
    }

    string typeOf(string name)
    {
        var item := find(name);

        if (nil != item)
        {
            ^ item.getType()
        };

        ^ ""
    }

    int indexOf(string name)
    {
        var item := find(name);

        if (nil != item)
        {
            ^ item.getIndex()
        };

        ^ 0
    }

    string segmentOf(string name)
    {
        string kindName := kindOf(name);

        if (kindName == "static")
        {
            ^ "static"
        };

        if (kindName == "field")
        {
            ^ "this"
        };

        if (kindName == "argument")
        {
            ^ "argument"
        };

        if (kindName == "var")
        {
            ^ "local"
        };

        ^ ""
    }
}

class VMWriter
{
    object _out;

    constructor new(object outputFile)
    {
        _out := outputFile
    }

    writePush(string segment, int indexValue)
    {
        _out.writeLine("push " + segment + " " + indexValue.toString())
    }

    writePop(string segment, int indexValue)
    {
        _out.writeLine("pop " + segment + " " + indexValue.toString())
    }

    writeArithmetic(string command)
    {
        _out.writeLine(command)
    }

    writeLabel(string labelName)
    {
        _out.writeLine("label " + labelName)
    }

    writeGoto(string labelName)
    {
        _out.writeLine("goto " + labelName)
    }

    writeIf(string labelName)
    {
        _out.writeLine("if-goto " + labelName)
    }

    writeCall(string name, int nArgs)
    {
        _out.writeLine("call " + name + " " + nArgs.toString())
    }

    writeFunction(string name, int nLocals)
    {
        _out.writeLine("function " + name + " " + nLocals.toString())
    }

    writeReturn()
    {
        _out.writeLine("return")
    }
}


class CompilationEngine
{
    ArrayList _tokens;
    int _p;
    string _className;
    SymbolTable _symbols;
    VMWriter _vm;
    int _labelCounter;

    constructor new(ArrayList tokens, VMWriter vmWriter)
    {
        _tokens := tokens;
        _p := 0;
        _className := "";
        _symbols := SymbolTable.new();
        _vm := vmWriter;
        _labelCounter := 0
    }

    string currentToken()
    {
        if (_p < _tokens.Length) { ^ _tokens[_p].toString() };
        ^ ""
    }

    string getTokenValue(string tokenLine)
    {
        int start := tokenLine.indexOf(0, ">");
        int end := tokenLine.indexOf(0, "</");

        if (start >= 0)
        {
            if (end > start)
            {
                ^ tokenLine.Substring(start + 2, end - start - 3)
            }
        };

        ^ ""
    }

    string getTagName(string tokenLine)
    {
        int start := tokenLine.indexOf(0, "<");
        int end := tokenLine.indexOf(0, ">");

        if (start >= 0)
        {
            if (end > start)
            {
                ^ tokenLine.Substring(start + 1, end - start - 1)
            }
        };

        ^ ""
    }

    string advance()
    {
        string val := getTokenValue(currentToken());
        _p := _p + 1;
        ^ val
    }

    string newLabel(string base)
    {
        string label := base + _labelCounter.toString();
        _labelCounter := _labelCounter + 1;
        ^ label
    }

    bool isOp(string val)
    {
        if (val == "+") { ^ true };
        if (val == "-") { ^ true };
        if (val == "*") { ^ true };
        if (val == "/") { ^ true };
        if (val == "&amp;") { ^ true };
        if (val == "|") { ^ true };
        if (val == "&lt;") { ^ true };
        if (val == "&gt;") { ^ true };
        if (val == "=") { ^ true };
        ^ false
    }

    writeOp(string op)
    {
        if (op == "+") { _vm.writeArithmetic("add") };
        if (op == "-") { _vm.writeArithmetic("sub") };
        if (op == "*") { _vm.writeCall("Math.multiply", 2) };
        if (op == "/") { _vm.writeCall("Math.divide", 2) };
        if (op == "&amp;") { _vm.writeArithmetic("and") };
        if (op == "|") { _vm.writeArithmetic("or") };
        if (op == "&lt;") { _vm.writeArithmetic("lt") };
        if (op == "&gt;") { _vm.writeArithmetic("gt") };
        if (op == "=") { _vm.writeArithmetic("eq") }
    }

    compileClass()
    {
        advance();
        _className := advance();
        advance();

        while (getTokenValue(currentToken()) == "static")
        {
            compileClassVarDec()
        };

        while (getTokenValue(currentToken()) == "field")
        {
            compileClassVarDec()
        };

        bool go := true;

        while (go)
        {
            string val := getTokenValue(currentToken());

            if (val == "constructor")
            {
                compileSubroutine()
            }
            else
            {
                if (val == "function")
                {
                    compileSubroutine()
                }
                else
                {
                    if (val == "method")
                    {
                        compileSubroutine()
                    }
                    else
                    {
                        go := false
                    }
                }
            }
        }
    }

    compileClassVarDec()
    {
        string kindName := advance();
        string typeName := advance();
        string name := advance();

        _symbols.define(name, typeName, kindName);

        while (getTokenValue(currentToken()) == ",")
        {
            advance();
            name := advance();
            _symbols.define(name, typeName, kindName)
        };

        advance()
    }

    compileSubroutine()
    {
        string subType := advance();
        advance();
        string subName := advance();

        _symbols.startSubroutine();

        if (subType == "method")
        {
            _symbols.define("this", _className, "argument")
        };

        advance();
        compileParameterList();
        advance();

        advance();

        while (getTokenValue(currentToken()) == "var")
        {
            compileVarDec()
        };

        int nLocals := _symbols.varCount("var");

        _vm.writeFunction(_className + "." + subName, nLocals);

        if (subType == "constructor")
        {
            int fields := _symbols.varCount("field");
            _vm.writePush("constant", fields);
            _vm.writeCall("Memory.alloc", 1);
            _vm.writePop("pointer", 0)
        };

        if (subType == "method")
        {
            _vm.writePush("argument", 0);
            _vm.writePop("pointer", 0)
        };

        compileStatements();

        advance()
    }

    compileParameterList()
    {
        if (getTokenValue(currentToken()) != ")")
        {
            string typeName := advance();
            string name := advance();

            _symbols.define(name, typeName, "argument");

            while (getTokenValue(currentToken()) == ",")
            {
                advance();
                typeName := advance();
                name := advance();
                _symbols.define(name, typeName, "argument")
            }
        }
    }

    compileVarDec()
    {
        advance();
        string typeName := advance();
        string name := advance();

        _symbols.define(name, typeName, "var");

        while (getTokenValue(currentToken()) == ",")
        {
            advance();
            name := advance();
            _symbols.define(name, typeName, "var")
        };

        advance()
    }

    compileStatements()
    {
        bool go := true;

        while (go)
        {
            string val := getTokenValue(currentToken());

            if (val == "let")
            {
                compileLet()
            }
            else
            {
                if (val == "if")
                {
                    compileIf()
                }
                else
                {
                    if (val == "while")
                    {
                        compileWhile()
                    }
                    else
                    {
                        if (val == "do")
                        {
                            compileDo()
                        }
                        else
                        {
                            if (val == "return")
                            {
                                compileReturn()
                            }
                            else
                            {
                                go := false
                            }
                        }
                    }
                }
            }
        }
    }

    compileLet()
    {
        advance();

        string name := advance();
        bool isArray := false;

        if (getTokenValue(currentToken()) == "[")
        {
            isArray := true;
            advance();

            compileExpression();
            advance();

            _vm.writePush(_symbols.segmentOf(name), _symbols.indexOf(name));
            _vm.writeArithmetic("add")
        };

        advance();
        compileExpression();
        advance();

        if (isArray)
        {
            _vm.writePop("temp", 0);
            _vm.writePop("pointer", 1);
            _vm.writePush("temp", 0);
            _vm.writePop("that", 0)
        }
        else
        {
            _vm.writePop(_symbols.segmentOf(name), _symbols.indexOf(name))
        }
    }

    compileIf()
    {
        string labelTrue := newLabel("IF_TRUE");
        string labelFalse := newLabel("IF_FALSE");
        string labelEnd := newLabel("IF_END");

        advance();
        advance();
        compileExpression();
        advance();

        _vm.writeIf(labelTrue);
        _vm.writeGoto(labelFalse);
        _vm.writeLabel(labelTrue);

        advance();
        compileStatements();
        advance();

        if (getTokenValue(currentToken()) == "else")
        {
            _vm.writeGoto(labelEnd);
            _vm.writeLabel(labelFalse);

            advance();
            advance();
            compileStatements();
            advance();

            _vm.writeLabel(labelEnd)
        }
        else
        {
            _vm.writeLabel(labelFalse)
        }
    }

    compileWhile()
    {
        string labelExp := newLabel("WHILE_EXP");
        string labelEnd := newLabel("WHILE_END");

        _vm.writeLabel(labelExp);

        advance();
        advance();
        compileExpression();
        advance();

        _vm.writeArithmetic("not");
        _vm.writeIf(labelEnd);

        advance();
        compileStatements();
        advance();

        _vm.writeGoto(labelExp);
        _vm.writeLabel(labelEnd)
    }

    compileDo()
    {
        advance();
        compileSubroutineCall();
        advance();

        _vm.writePop("temp", 0)
    }

    compileReturn()
    {
        advance();

        if (getTokenValue(currentToken()) != ";")
        {
            compileExpression()
        }
        else
        {
            _vm.writePush("constant", 0)
        };

        advance();

        _vm.writeReturn()
    }

    compileExpression()
    {
        compileTerm();

        while (isOp(getTokenValue(currentToken())))
        {
            string op := advance();
            compileTerm();
            writeOp(op)
        }
    }

    compileStringConstant(string val)
    {
        _vm.writePush("constant", val.Length);
        _vm.writeCall("String.new", 1);

        int i := 0;

        while (i < val.Length)
        {
            int ch := val[i];
            _vm.writePush("constant", ch);
            _vm.writeCall("String.appendChar", 2);
            i := i + 1
        }
    }

    compileTerm()
    {
        string tag := getTagName(currentToken());
        string val := getTokenValue(currentToken());

        if (tag == "integerConstant")
        {
            advance();
            _vm.writePush("constant", val.toInt())
        }
        else
        {
            if (tag == "stringConstant")
            {
                advance();
                compileStringConstant(val)
            }
            else
            {
                if (tag == "identifier")
                {
                    string name := advance();

                    if (getTokenValue(currentToken()) == "[")
                    {
                        advance();
                        compileExpression();
                        advance();

                        _vm.writePush(_symbols.segmentOf(name), _symbols.indexOf(name));
                        _vm.writeArithmetic("add");
                        _vm.writePop("pointer", 1);
                        _vm.writePush("that", 0)
                    }
                    else
                    {
                        if (getTokenValue(currentToken()) == "(")
                        {
                            advance();

                            _vm.writePush("pointer", 0);
                            int nArgs := compileExpressionList();

                            advance();

                            _vm.writeCall(_className + "." + name, nArgs + 1)
                        }
                        else
                        {
                            if (getTokenValue(currentToken()) == ".")
                            {
                                compileSubroutineCallAfterName(name)
                            }
                            else
                            {
                                _vm.writePush(_symbols.segmentOf(name), _symbols.indexOf(name))
                            }
                        }
                    }
                }
                else
                {
                    if (val == "(")
                    {
                        advance();
                        compileExpression();
                        advance()
                    }
                    else
                    {
                        if (val == "-")
                        {
                            advance();
                            compileTerm();
                            _vm.writeArithmetic("neg")
                        }
                        else
                        {
                            if (val == "~")
                            {
                                advance();
                                compileTerm();
                                _vm.writeArithmetic("not")
                            }
                            else
                            {
                                if (val == "true")
                                {
                                    advance();
                                    _vm.writePush("constant", 0);
                                    _vm.writeArithmetic("not")
                                }
                                else
                                {
                                    if (val == "false")
                                    {
                                        advance();
                                        _vm.writePush("constant", 0)
                                    }
                                    else
                                    {
                                        if (val == "null")
                                        {
                                            advance();
                                            _vm.writePush("constant", 0)
                                        }
                                        else
                                        {
                                            if (val == "this")
                                            {
                                                advance();
                                                _vm.writePush("pointer", 0)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    int compileExpressionList()
    {
        int count := 0;

        if (getTokenValue(currentToken()) != ")")
        {
            compileExpression();
            count := count + 1;

            while (getTokenValue(currentToken()) == ",")
            {
                advance();
                compileExpression();
                count := count + 1
            }
        };

        ^ count
    }

    compileSubroutineCallAfterName(string firstName)
    {
        advance();

        string funcName := advance();

        advance();

        int nArgs := 0;
        string callName := "";

        if (_symbols.kindOf(firstName) != "none")
        {
            _vm.writePush(_symbols.segmentOf(firstName), _symbols.indexOf(firstName));
            callName := _symbols.typeOf(firstName) + "." + funcName;
            nArgs := compileExpressionList() + 1
        }
        else
        {
            callName := firstName + "." + funcName;
            nArgs := compileExpressionList()
        };

        advance();

        _vm.writeCall(callName, nArgs)
    }

    compileSubroutineCall()
    {
        string name := advance();

        if (getTokenValue(currentToken()) == ".")
        {
            compileSubroutineCallAfterName(name)
        }
        else
        {
            advance();

            _vm.writePush("pointer", 0);
            int nArgs := compileExpressionList();

            advance();

            _vm.writeCall(_className + "." + name, nArgs + 1)
        }
    }
}

public program()
{
    console.write("Enter Jack file path: ");

    string path := console.readLine();

    var tokenizer := JackTokenizer.new(path);
    var tokens := tokenizer.tokenizeToArray();

    console.writeLine("Tokens count:");
    console.writeLine(tokens.Length);

    string outPathVM := path.Substring(0, path.Length - 5) + ".vm";

    var outputFileVM := File.assign(outPathVM).textwriter();

    var vmWriter := VMWriter.new(outputFileVM);

    var engine := CompilationEngine.new(tokens, vmWriter);

    engine.compileClass();

    outputFileVM.close();

    console.writeLine("Done! Created .vm file");

    console.readChar()
}
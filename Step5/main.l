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
    object _out;
    ArrayList _opList;
    int _indent;
    VMWriter _vm;
    SymbolTable _symbols;
    string _className;
    string _subroutineName;
    int _whileCounter;
    int _ifCounter;

    constructor new(ArrayList tokens,VMWriter vmWriter,SymbolTable symbols)
   {
      _tokens := tokens;

      _vm := vmWriter;
      _symbols := symbols;

      _p := 0;

      _className := "";

      _whileCounter := 0;
      _ifCounter := 0;
    }
    string spaces()
    {
        string s := "";
        int i := 0;

        while (i < _indent)
        {
            s := s + "  ";
            i := i + 1
        };

        ^ s
    }

    writeIndented(string text)
    {
        _out.writeLine(spaces() + text)
    }

    openTag(string tag)
    {
        writeIndented("<" + tag + ">");
        _indent := _indent + 1
    }

    closeTag(string tag)
    {
        _indent := _indent - 1;
        writeIndented("</" + tag + ">")
    }

    string currentToken()
    {
        if (_p < _tokens.Length)
        {
            ^ _tokens[_p].toString()
        };

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

    bool isOp(string val)
    {
        int len := _opList.Length;

        for (int i := 0; i < len; i := i + 1)
        {
            if (_opList[i].toString() == val)
            {
                ^ true
            }
        };

        ^ false
    }

    process()
{
    _p := _p + 1
}

compileClass()
{
    process(); // class

    _className :=
        getTokenValue(currentToken());

    process(); // className

    process(); // {

    bool classVarGo := true;

    while (classVarGo)
    {
        string val :=
            getTokenValue(currentToken());

        if (val == "static")
        {
            compileClassVarDec()
        }
        else
        {
            if (val == "field")
            {
                compileClassVarDec()
            }
            else
            {
                classVarGo := false
            }
        }
    };

    bool subGo := true;

    while (subGo)
    {
        string val2 :=getTokenValue(currentToken());

        if (val2 == "constructor")
        {
            compileSubroutine()
        }
        else
        {
            if (val2 == "function")
            {
                compileSubroutine()
            }
            else
            {
                if (val2 == "method")
                {
                    compileSubroutine()
                }
                else
                {
                    subGo := false
                }
            }
        }
    };

    process(); // }
}

    compileClassVarDec()
    {
        openTag("classVarDec");

        process();
        process();
        process();

        while (getTokenValue(currentToken()) == ",")
        {
            process();
            process()
        };

        process();

        closeTag("classVarDec")
    }

    compileSubroutine()
{
    _symbols.startSubroutine();

    string subroutineType :=
        getTokenValue(currentToken());

    process(); // constructor/function/method

    process(); // return type

    _subroutineName :=
        getTokenValue(currentToken());

    process(); // name

    process(); // (

    compileParameterList();

    process(); // )

    process(); // {

    int localCount := 0;

    while (getTokenValue(currentToken()) == "var")
    {
        compileVarDec();

        localCount :=
            _symbols.varCount("var")
    };

    _vm.writeFunction(
        _className + "." + _subroutineName,
        localCount
    );

    compileStatements();

    process(); // }

}

    compileParameterList()
{
    if (getTokenValue(currentToken()) != ")")
    {
        string typeName :=
            getTokenValue(currentToken());

        process(); // type

        string varName :=
            getTokenValue(currentToken());

        _symbols.define(
            varName,
            typeName,
            "argument"
        );

        process(); // varName

        while (getTokenValue(currentToken()) == ",")
        {
            process(); // ,

            typeName :=
                getTokenValue(currentToken());

            process(); // type

            varName :=
                getTokenValue(currentToken());

            _symbols.define(
                varName,
                typeName,
                "argument"
            );

            process(); // varName
        }
    }
}

   compileVarDec()
{
    process(); // var

    string typeName :=
        getTokenValue(currentToken());

    process(); // type

    string varName :=
        getTokenValue(currentToken());

    _symbols.define(
        varName,
        typeName,
        "var"
    );

    process(); // varName

    while (getTokenValue(currentToken()) == ",")
    {
        process(); // ,

        varName :=
            getTokenValue(currentToken());

        _symbols.define(
            varName,
            typeName,
            "var"
        );

        process(); // varName
    };

    process(); // ;
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
    process(); // let

    string varName :=
        getTokenValue(currentToken());

    process(); // varName

    process(); // =

    compileExpression();

    process(); // ;

    _vm.writePop(
        _symbols.segmentOf(varName),
        _symbols.indexOf(varName)
    )
}

    compileIf()
{
    int id := _ifCounter;
    _ifCounter := _ifCounter + 1;

    string trueLabel :=
        "IF_TRUE" + id.toString();

    string falseLabel :=
        "IF_FALSE" + id.toString();

    string endLabel :=
        "IF_END" + id.toString();

    process(); // if
    process(); // (

    compileExpression();

    process(); // )

    _vm.writeIf(trueLabel);
    _vm.writeGoto(falseLabel);

    _vm.writeLabel(trueLabel);

    process(); // {

    compileStatements();

    process(); // }

    if (getTokenValue(currentToken()) == "else")
    {
        _vm.writeGoto(endLabel);

        _vm.writeLabel(falseLabel);

        process(); // else
        process(); // {

        compileStatements();

        process(); // }

        _vm.writeLabel(endLabel)
    }
    else
    {
        _vm.writeLabel(falseLabel)
    }
}

compileWhile()
{
    int id := _whileCounter;
    _whileCounter := _whileCounter + 1;

    string expLabel :=
        "WHILE_EXP" + id.toString();

    string endLabel :=
        "WHILE_END" + id.toString();

    _vm.writeLabel(expLabel);

    process(); // while
    process(); // (

    compileExpression();

    process(); // )

    _vm.writeArithmetic("not");
    _vm.writeIf(endLabel);

    process(); // {

    compileStatements();

    process(); // }

    _vm.writeGoto(expLabel);

    _vm.writeLabel(endLabel)
}
compileDo()
{
    process(); // do

    compileSubroutineCall();

    process(); // ;

    _vm.writePop("temp", 0)
}

    compileReturn()
{
    process(); // return

    if (getTokenValue(currentToken()) != ";")
    {
        compileExpression()
    }
    else
    {
        _vm.writePush("constant", 0)
    };

    process(); // ;

    _vm.writeReturn()
}

   compileExpression()
{
    compileTerm()
}

   compileTerm()
{
    string val :=
        getTokenValue(currentToken());

    if (tokenType(currentToken()) == "integerConstant")
    {
        _vm.writePush(
            "constant",
            Integer.parse(val)
        );

        process()
    }
    else
    {
        process()
    }
}

    compileExpressionList()
    {
        openTag("expressionList");

        if (getTokenValue(currentToken()) != ")")
        {
            compileExpression();

            while (getTokenValue(currentToken()) == ",")
            {
                process();
                compileExpression()
            }
        };

        closeTag("expressionList")
    }

   compileSubroutineCall()
{
    process(); // name

    if (getTokenValue(currentToken()) == ".")
    {
        process();
        process()
    };

    process(); // (

    int argCount := 0;

    if (getTokenValue(currentToken()) != ")")
    {
        compileExpression();
        argCount := 1
    };

    process(); // )

    _vm.writeCall(
        "Output.printInt",
        argCount
    )
}
}

public program()
{
    console.write("Enter Jack file path: ");

    string path := console.readLine();

    var tokenizer := JackTokenizer.new(path);

    var tokens := tokenizer.tokenizeToArray();

    string vmPath :=
        path.Substring(0, path.Length - 5)
        + ".vm";

    var vmFile :=
        File.assign(vmPath).textwriter();

    var vmWriter :=
        VMWriter.new(vmFile);

    var symbols :=
        SymbolTable.new();

    var engine :=
        CompilationEngine.new(
            tokens,
            vmWriter,
            symbols
        );

    engine.compileClass();
    vmFile.close();

    console.writeLine("Done!");

    console.readChar()
}
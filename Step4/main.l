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

class CompilationEngine
{
    ArrayList _tokens;
    int _p;
    object _out;
    ArrayList _opList;
    int _indent;

    constructor new(ArrayList tokens, object outputFile)
    {
        _tokens := tokens;
        _out := outputFile;
        _p := 0;
        _indent := 0;

        _opList := new ArrayList();
        _opList.append("+");
        _opList.append("-");
        _opList.append("*");
        _opList.append("/");
        _opList.append("&amp;");
        _opList.append("|");
        _opList.append("&lt;");
        _opList.append("&gt;");
        _opList.append("=");
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
        writeIndented(currentToken());
        _p := _p + 1
    }

    compileClass()
    {
        openTag("class");

        process(); // class
        process(); // className
        process(); // {

        bool classVarGo := true;

        while (classVarGo)
        {
            string val := getTokenValue(currentToken());

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
            string val2 := getTokenValue(currentToken());

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

        closeTag("class")
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
        openTag("subroutineDec");

        process();
        process();
        process();
        process();

        compileParameterList();

        process();

        openTag("subroutineBody");

        process();

        while (getTokenValue(currentToken()) == "var")
        {
            compileVarDec()
        };

        compileStatements();

        process();

        closeTag("subroutineBody");

        closeTag("subroutineDec")
    }

    compileParameterList()
    {
        openTag("parameterList");

        if (getTokenValue(currentToken()) != ")")
        {
            process();
            process();

            while (getTokenValue(currentToken()) == ",")
            {
                process();
                process();
                process()
            }
        };

        closeTag("parameterList")
    }

    compileVarDec()
    {
        openTag("varDec");

        process();
        process();
        process();

        while (getTokenValue(currentToken()) == ",")
        {
            process();
            process()
        };

        process();

        closeTag("varDec")
    }

    compileStatements()
    {
        openTag("statements");

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
        };

        closeTag("statements")
    }

    compileLet()
    {
        openTag("letStatement");

        process();
        process();

        if (getTokenValue(currentToken()) == "[")
        {
            process();
            compileExpression();
            process()
        };

        process();
        compileExpression();
        process();

        closeTag("letStatement")
    }

    compileIf()
    {
        openTag("ifStatement");

        process();
        process();
        compileExpression();
        process();
        process();
        compileStatements();
        process();

        if (getTokenValue(currentToken()) == "else")
        {
            process();
            process();
            compileStatements();
            process()
        };

        closeTag("ifStatement")
    }

    compileWhile()
    {
        openTag("whileStatement");

        process();
        process();
        compileExpression();
        process();
        process();
        compileStatements();
        process();

        closeTag("whileStatement")
    }

    compileDo()
    {
        openTag("doStatement");

        process();
        compileSubroutineCall();
        process();

        closeTag("doStatement")
    }

    compileReturn()
    {
        openTag("returnStatement");

        process();

        if (getTokenValue(currentToken()) != ";")
        {
            compileExpression()
        };

        process();

        closeTag("returnStatement")
    }

    compileExpression()
    {
        openTag("expression");

        compileTerm();

        while (isOp(getTokenValue(currentToken())))
        {
            process();
            compileTerm()
        };

        closeTag("expression")
    }

    compileTerm()
    {
        openTag("term");

        string tag := getTagName(currentToken());
        string val := getTokenValue(currentToken());

        if (tag == "integerConstant")
        {
            process()
        }
        else
        {
            if (tag == "stringConstant")
            {
                process()
            }
            else
            {
                if (tag == "keyword")
                {
                    process()
                }
                else
                {
                    if (tag == "identifier")
                    {
                        process();

                        string nextVal := getTokenValue(currentToken());

                        if (nextVal == "[")
                        {
                            process();
                            compileExpression();
                            process()
                        }
                        else
                        {
                            if (nextVal == "(")
                            {
                                process();
                                compileExpressionList();
                                process()
                            }
                            else
                            {
                                if (nextVal == ".")
                                {
                                    process();
                                    process();
                                    process();
                                    compileExpressionList();
                                    process()
                                }
                            }
                        }
                    }
                    else
                    {
                        if (val == "(")
                        {
                            process();
                            compileExpression();
                            process()
                        }
                        else
                        {
                            if (val == "-")
                            {
                                process();
                                compileTerm()
                            }
                            else
                            {
                                if (val == "~")
                                {
                                    process();
                                    compileTerm()
                                }
                            }
                        }
                    }
                }
            }
        };

        closeTag("term")
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
        process();

        if (getTokenValue(currentToken()) == ".")
        {
            process();
            process()
        };

        process();
        compileExpressionList();
        process()
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

    // =========================
    // Part A - T.xml
    // =========================

    string outPathT := path.Substring(0, path.Length - 5) + "T.xml";

    var outputFileT := File.assign(outPathT).textwriter();

    outputFileT.writeLine("<tokens>");

    int len := tokens.Length;

    for (int i := 0; i < len; i := i + 1)
    {
        outputFileT.writeLine(tokens[i].toString())
    };

    outputFileT.writeLine("</tokens>");

    outputFileT.close();

    // =========================
    // Part B - .xml
    // =========================

    string outPathParse := path.Substring(0, path.Length - 5) + ".xml";

    var outputFileParse := File.assign(outPathParse).textwriter();

    var engine := CompilationEngine.new(tokens, outputFileParse);

    engine.compileClass();

    outputFileParse.close();

    console.writeLine("Done! Created T.xml and .xml");

    console.readChar()
}
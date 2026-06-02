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

public program()
{
    console.write("Enter Jack file path: ");

    string path := console.readLine();

    var tokenizer := JackTokenizer.new(path);

    var tokens := tokenizer.tokenizeToArray();

    console.writeLine("Tokens count:");
    console.writeLine(tokens.Length);

    string outPath := path.Substring(0, path.Length - 5) + "T.xml";

    var outputFile := File.assign(outPath).textwriter();

    outputFile.writeLine("<tokens>");

    int len := tokens.Length;

    for (int i := 0; i < len; i := i + 1)
    {
        outputFile.writeLine(tokens[i].toString())
    };

    outputFile.writeLine("</tokens>");

    outputFile.close();

    console.writeLine("Done!");

    console.readChar()
}



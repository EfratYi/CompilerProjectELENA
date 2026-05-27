import system'io;
import system'collections;
import extensions;

// ==========================================
// Tokenizer
// ==========================================

class JackTokenizer
{
    object _inputFile;

    ArrayList _keywords;

    string _symbols;

    constructor new(string inputFileName)
    {
        _inputFile := File.assign(inputFileName).textreader();

        // =========================
        // keywords
        // =========================

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

        // =========================
        // symbols
        // =========================

        _symbols := "{}()[].,;+-*/&|<>=~";
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

    ArrayList tokenizeToArray()
    {
        var tokensList := new ArrayList();

        while (_inputFile.Available)
        {
            var rawLine := _inputFile.readLine();

            if (nil != rawLine)
            {
                string line := rawLine.toString().trim();

                // =========================
                // remove //
                // =========================

                int commentIdx := line.indexOf(0, "//");

                if (commentIdx == 0)
                {
                    line := ""
                }
                else
                {
                    if (commentIdx > 0)
                    {
                        line := line.Substring(0, commentIdx).trim()
                    }
                };

                // =========================
                // remove /* */
                // =========================

                int blockCommentStart := line.indexOf(0, "/*");
                int blockCommentEnd := line.indexOf(0, "*/");

                if (blockCommentStart >= 0)
                {
                    if (blockCommentEnd >= 0)
                    {
                        string part1 :=
                            line.Substring(0, blockCommentStart);

                        string part2 :=
                            line.Substring(
                                blockCommentEnd + 2,
                                line.Length - (blockCommentEnd + 2)
                            );

                        line := (part1 + part2).trim()
                    }
                };

                if (line.Length > 0)
                {
                    int i := 0;

                    while (i < line.Length)
                    {
                        string ch := line.Substring(i, 1);

                        int ascii := line[i];

                        // =========================
                        // spaces
                        // =========================

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
                                // =========================
                                // symbol
                                // =========================

                                if (isSymbol(ch))
                                {
                                    string escaped :=
                                        escapeXmlSymbol(ch);

                                    tokensList.append(
                                        "<symbol> " +
                                        escaped +
                                        " </symbol>"
                                    );

                                    i := i + 1
                                }
                                else
                                {
                                    // =========================
                                    // string constant
                                    // =========================

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
                                                    strConst :=
                                                        strConst +
                                                        line.Substring(i, 1)
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
                                        // =========================
                                        // integer constant
                                        // =========================

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
                                                                intConst :=
                                                                    intConst +
                                                                    line.Substring(i, 1);

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
                                                // =========================
                                                // identifier / keyword
                                                // =========================

                                                string idOrKey := "";

                                                bool stopWord := false;

                                                while (stopWord == false)
                                                {
                                                    if (i < line.Length)
                                                    {
                                                        string nextCh :=
                                                            line.Substring(i, 1);

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
                                                                    idOrKey :=
                                                                        idOrKey + nextCh;

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
                                            // =========================
                                            // identifier / keyword
                                            // =========================

                                            string idOrKey := "";

                                            bool stopWord := false;

                                            while (stopWord == false)
                                            {
                                                if (i < line.Length)
                                                {
                                                    string nextCh :=
                                                        line.Substring(i, 1);

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
                                                                idOrKey :=
                                                                    idOrKey + nextCh;

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
                                }
                            }
                        }
                    }
                }
            }
        };

        _inputFile.close();

        ^ tokensList
    }
}

// ==========================================
// MAIN
// ==========================================

public program()
{
    console.write("Enter Jack file path: ");

    string path := console.readLine();

    var tokenizer := JackTokenizer.new(path);

    var tokens := tokenizer.tokenizeToArray();

    string outPath :=
        path.Substring(0, path.Length - 5) + "T.xml";

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
// =============================================================================
// MyLang 词法分析器（Lexer）
// 功能：从源文件读取字符流，识别并生成 Token 序列
// 作者：李隆生（23009200365）
// 日期：2025-12-05
// 语言：仓颉（Cangjie）
// 依赖：std.fs, std.math, std.random, std.convert.Parsable, std.unicode
// -----------------------------------------------------------------------------
// 核心接口：
//   - initscanner(filePath: Path): Int64    // 初始化扫描器，打开文件
//   - getNextToken(): Token                 // 获取下一个 Token
//   - closescanner()                        // 关闭文件句柄
// -----------------------------------------------------------------------------
// 支持特性：
//   - 关键字、运算符、分隔符识别
//   - 整数/浮点数字面量解析
//   - 颜色常量（BLACK/WHITE/RED/GREEN/BLUE）、数学常量（PI/E）
//   - 内置函数（SIN/COS/...）→ 绑定标准库函数指针
//   - 注释跳过（// 与 --）
//   - 错误记号（ERRTOKEN）报告非法字符
// =============================================================================
package Mylang
import std.fs.*
import std.math.*
import std.random.*
import std.convert.Parsable
import std.unicode.UnicodeStringExtension


//全局变量file 
public var file:?File = None;
//词法分析器辅助变量
private let bytesBuf:Array<Byte> = Array<Byte>(4096,repeat:0);
private var index:Int64 = 0;

//TokeType枚举类型
public enum TokenType{
    // 关键字
    |ORIGIN|SCALE|ROT|COLOR|IS
    |FOR|FROM|TO|STEP|DRAW
    // 参数
    |T
    // 分隔符
    |SEMICO|L_BRACKET|R_BRACKET|COMMA
    // 运算符
    |PLUS|MINUS|MUL|DIV|POWER
    // 函数
    |FUNC
    // 常数
    |CONST_ID
    // 空记号
    |NONTOKEN
    // 错误记号
    |ERRTOKEN
    public operator func == (right:TokenType):Bool{//😀
        return getTokenTypeName(this) == getTokenTypeName(right);
    }
    public operator func != (right:TokenType):Bool{//😀
        return getTokenTypeName(this) != getTokenTypeName(right);
    }
}
//对外接口获取Type类型名
public func getTokenTypeName(tokentype: TokenType): String {
    return match(tokentype) {
        case ORIGIN => "ORIGIN"
        case SCALE => "SCALE"
        case ROT => "ROT"
        case COLOR => "COLOR"
        case IS => "IS"
        case FOR => "FOR"
        case FROM => "FROM"
        case TO => "TO"
        case STEP => "STEP"
        case DRAW => "DRAW"
        case T => "T"
        case SEMICO => "SEMICO"
        case L_BRACKET => "L_BRACKET"
        case R_BRACKET => "R_BRACKET"
        case COMMA => "COMMA"
        case PLUS => "PLUS"
        case MINUS => "MINUS"
        case MUL => "MUL"
        case DIV => "DIV"
        case POWER => "POWER"
        case FUNC => "FUNC"
        case CONST_ID => "CONST_ID"
        case NONTOKEN => "NONTOKEN"
        case ERRTOKEN => "ERRTOKEN"
    }
}
//Token结构体
public struct Token{
    
    public var tokentype:TokenType;//标记的类型信息
    public var lexeme:String;//原始文本内容
    public var value:Float64;//数值（如果是常数）
    public var Func:?(Float64)->Float64;//函数指针（如果是函数名）
    public init(){
        this.tokentype = TokenType.NONTOKEN;
        this.value = 0.0;
        this.lexeme = "";
        this.Func = None;
    }
}
//获得一个token
public func getNextToken():Token{
    var token:Token =Token();
    var ch:Rune = r'0';
    //1 跳过空格 制表符 换行
    while(true){//EOF
        ch=readrune();
        if(ch == r' '|| ch == r'\t' || ch == r'\n' || ch == r'\r'){
            continue;
        }else{
            break;
        }
    }
    //2 如果当前字符（index-1）是EOF
    if(ch_is_EOF()){
        token.tokentype=NONTOKEN;
        return token;
    }
    //3 注释 // 或者 --
    if(ch == r'/'){
        ch = readrune();
        if (ch == r'/'){
            //处理 //注释
            while(true){
                ch = readrune();
                if(ch_is_EOF()){
                    token.tokentype = NONTOKEN;
                    return token;
                }else if(ch == r'\n'){
                    break;
                }
            }
            return getNextToken();
        }else{
            //回退一字符
            backrune();
            token.tokentype = DIV;
            token.lexeme = "/";
            return token;
        }
    }else if(ch == r'-'){
        ch = readrune();
            if (ch == r'-'){
            //处理 //注释
            while(true){
                ch = readrune();
                if(ch_is_EOF()){
                    token.tokentype = NONTOKEN;
                    return token;
                }else if(ch == r'\n'){
                    break;
                }
            }
            return getNextToken();
        }else{
            //回退一字符
            backrune();
            token.tokentype = MINUS;
            token.lexeme = "-";
            return token;
        }
    }

    //3数字 如3.14 , 89
    if (ch.isAsciiNumber()){
        var numstr:String = "";
        numstr += String(ch);
        while(true){
            ch = readrune();
            if(ch.isAsciiNumber()){
                numstr += String(ch);
            }else if (ch == r'.'){
                numstr += String(ch);
                while(true){
                    ch = readrune();
                    if(ch.isAsciiNumber()){
                        numstr += String(ch);
                    }else{
                        backrune();
                        break;
                    }
                }
            }else{
                backrune();
                break;
            }
        }
        token.tokentype = CONST_ID;
        token.lexeme = numstr;
        token.value = Float64.tryParse(numstr).getOrThrow();
        return token;
    }

    //4字母
    if (ch.isAsciiLetter()){
        var str:String = "";
        str += String(ch);
        while(true){
            ch = readrune();
            if (ch.isAsciiLetter()){
                str += String(ch);
            }else{
                backrune();
                break;
            }
        }
        var idstr:String = str.toUpper();

        //查表判断tokentype
        match (idstr) {
            case "ORIGIN" =>
                token.tokentype = ORIGIN
            case "SCALE" =>
                token.tokentype = SCALE
            case "ROT" =>
                token.tokentype = ROT
            case "COLOR" =>
                token.tokentype = COLOR
            case "IS" =>
                token.tokentype = IS
            case "TO" =>
                token.tokentype = TO
            case "STEP" =>
                token.tokentype = STEP
            case "DRAW" =>
                token.tokentype = DRAW
            case "FOR" =>
                token.tokentype = FOR
            case "FROM" =>
                token.tokentype = FROM
            case "BLACK" =>
                token.tokentype = CONST_ID
                token.value = Float64(0x000000)
            case "WHITE" =>
                token.tokentype = CONST_ID
                token.value = Float64(0xFFFFFF)
            case "RED" =>
                token.tokentype = CONST_ID
                token.value = Float64(0xFF0000)
            case "GREEN" =>
                token.tokentype = CONST_ID
                token.value = Float64(0x00FF00)
            case "BLUE" =>
                token.tokentype = CONST_ID
                token.value = Float64(0x0000FF)
            case "LLS" =>
                token.tokentype = CONST_ID
                token.value = Float64(Random().nextUInt32())
            case "PI" =>
                token.tokentype = CONST_ID
                token.value = 3.1415926535
            case "E" =>
                token.tokentype = CONST_ID
                token.value = 2.7182818284
            case "T" =>
                token.tokentype = T
            case "SIN" =>
                token.tokentype = FUNC;
                token.Func = sin;
            case "COS" =>
                token.tokentype = FUNC;
                token.Func = cos;
            case "TAN" =>
                token.tokentype = FUNC;
                token.Func = tan;
            case "LN" =>
                token.tokentype = FUNC;
                token.Func = log;
            case "EXP" =>
                token.tokentype = FUNC;
                token.Func = exp;
            case "SQRT" =>
                token.tokentype = FUNC;
                token.Func = sqrt;
            case "ABS" =>
                token.tokentype = FUNC;
                token.Func = abs;
            case _ =>
                token.tokentype = ERRTOKEN;
        }
        token.lexeme = str;
        return token;
    }
    
    //5 运算符号和分隔符
    match (ch){
        case r'+' =>
            token.tokentype = PLUS;
            token.lexeme ="+";
        case r'*' =>
            ch = readrune();
            if (ch == r'*'){
                token.tokentype = POWER;
                token.lexeme = "**";
            }else{
                backrune();
                token.tokentype = MUL;
                token.lexeme = "*";
            }
        case r'(' =>
            token.tokentype = L_BRACKET;
            token.lexeme = "("
        case r')' =>
            token.tokentype = R_BRACKET;
            token.lexeme = ")"
        case r',' =>
            token.tokentype = COMMA;
            token.lexeme = ",";
        case r';' =>
            token.tokentype = SEMICO;
            token.lexeme = ";";
        case _ =>
            //走到这里就是错误符号
            token.tokentype = ERRTOKEN;
            token.lexeme = String(ch);
    }
    return token;
}
//初始化词法分析器
public func initscanner(filePath:Path):Int64{
    try{
        file = File(filePath, Read);
    }catch(e:Exception){
        println("filePath ${filePath} not found");
        return 0;
    }
    file?.read(bytesBuf);
    return 1;
}
//关闭词法分析器
public func closescanner(){
    file?.close();
}

//-----------------------------------------辅助函数---------------------------------
//读取一个字符
private func readrune():Rune{
    let r:Rune = Rune(bytesBuf[index]);
    index++;
    return r;
}
//回退一个字符
private func backrune(){
    index--;
}
//判断是否是EOF
private func ch_is_EOF():Bool{
    return bytesBuf[index-1]==0;
}

/*
 * 函数绘图语言解释器（仓颉语言实现）
 * 作者：李隆生（学号：23009200365｜2023级）
 * 功能：读取 input.txt 中的绘图脚本，解析并生成图形输出output.bmp
 * 流程：词法分析 → 语法分析 → 语义处理 → 渲染输出（BMP）
 * 入口文件：main.cj
 * 编译运行：cjpm run
 */
package Mylang
import std.fs.*
main() {
    //scannertest();
    //parserTest();
    println("-----------------函数绘图语言仓颉实现-李隆生-lls----------");

    let filePath: Path = Path("./input.txt");
    let outputName: String = "output";
    println("-----------------program start----------------------------");
    Parse(filePath,outputName);
    println("-----------------program end sucess-----------------------");
    
    return 0;
}
// func scannertest(){
//     var token:Token=Token();
//     let filePath: Path = Path("./src/input.txt");
//     initscanner(filePath);
//     println("-----------------scanner test start-------------------");
    
//     print("记号类别".padEnd(16,padding:" "));
//     print("原始输入".padEnd(16,padding:" "));
//     print("常数值".padEnd(15,padding:" "));
//     println("函数FUNC(5)的值".padEnd(12,padding:" "));
//     while(true){
//         token = getNextToken();
//         if(token.tokentype == NONTOKEN){
//             println("file end");
//             break;
//         }else {
//             print(getTokenTypeName(token.tokentype).padEnd(12,padding:" "));
//             print(token.lexeme.padEnd(12,padding:" "));
//             print(token.value.toString().padEnd(12,padding:" "));

//             // if(token.Func.isNone()){
//             //     println("null".toString().padEnd(12,padding:" "));
//             // }else{
//             //     var function:(Float64)->Float64=token.Func.getOrThrow();//解析函数
//             //     println(function(5.0).toString().padEnd(12,padding:" "));
//             // }
            
//             match (token.Func){//我靠神了，我不该贬低仓颉的
//                 case Some(function) => 
//                     println(function(5.0).toString().padEnd(12,padding:" "));
//                 case None => 
//                     println("null".toString().padEnd(12,padding:" "));
//             }
//         }
        
//     }

//     println("-----------------scanner test end---------------------")
//     closescanner();
// }
// func parserTest(){
//     let filePath: Path = Path("./src/input.txt");
    
//     println("-----------------parser test start---------------------");
//     Parse(filePath);
//     println("-----------------parser test end---------------------");
// }


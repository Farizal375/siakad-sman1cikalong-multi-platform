import 'package:html/parser.dart' as html_parser;

void main() {
  String input = "&lt;p style=&quot;text-align:justify&quot;&gt;Lorem ipsum dolor sit amet...&lt;/p&gt;";
  
  String unescaped = html_parser.parse(input).documentElement?.text ?? input;
  print('Unescaped: $unescaped');
  
  String finalStr = html_parser.parse(unescaped).documentElement?.text ?? unescaped;
  print('Final: $finalStr');
}

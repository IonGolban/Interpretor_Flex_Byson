%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <stdarg.h>
    #include "symbol.h"

    extern int nr_lines;
    extern int nr_word;
    extern FILE* yyin;
    extern char* yytext;

    int ast_types[100];
    int indx_types = 0;
    int indx = 0;
    int indx_current_param = 1;
    char current_func[100];


void var_dec(int tip, char* id);
struct AstNode *id_leaf(char* i);
struct AstNode* constant_leaf(int type, void* value);
void free_expre(struct AstNode *var);
int get_var_value(char* id);

int indx_f = 0;
int nr_functii = 0;
char nume_call[100];
void for_fun_dec(int tip, char id[]);
void fun_args(int tip, char id[]);
int function_is_defined(char id[]);
struct AstNode* build_Ast(struct AstNode* left,struct AstNode* right, int op , char* op_name);
int eval_Ast(struct AstNode* node);
void get_Ast_types(struct AstNode* node);
int check_Ast_type();
void assign_var(char* id ,int val);
int var_was_declared(char* id);
int param_has_same_type(struct AstNode* node, char* id);
int func_was_decl(char* id);
struct AstNode* func_leaf();
struct AstNode* array_leaf();
%}

%union {
    short boolVal;
    int intVal;
    float floatVal;
    char charVal;
    char* strVal;
    char* varId;
    int Types;
    struct AstNode* var;
}

%define parse.lac full
%define parse.error verbose

%token INT FLOAT CHAR STRING BOOL EVAL TYPEOF VOID MAIN STRUCTURA CONST VAR ARR FUNCTION CALL FOR WHILE IF ELSE
%token <varId> ID
%token <intVal> INT_CONST 
%token <floatVal> FLOAT_CONST
%token <charVal> CHAR_CONST
%token <strVal> STR_CONST
%token <boolVal> TRUE FALSE

%type <Types> types return_type
%type <var> expression 

%left AND
%left OR
%left EQUALITY INEQUALITY
%left LT GT LTE GTE
%right '='
%left '+' '-'
%left '*' '/' '%'
%right NEG '!'
%left '(' ')' ACCES
%nonassoc THEN
%nonassoc ELSE

%start start
%%

start : statements {}
      ;

statements: statements statement {}
          | statement {}
          ;

statement: main_function{}
         | var_declaration ';' {}
         | array_declaration ';' {}
         | const_declaration ';' {}
         | function_declaration {}
         | structura_declaration {}
         ;


main_function : VOID MAIN '(' ')' '{' main_body '}' {}
             ;

main_body : main_body code_block {}
          | code_block {}
          ;
code_block : var_declaration ';' {}
           | var_assignment ';' {}
           | array_declaration ';' {}
           | array_assignment ';' {}
           | const_declaration ';' {}
           | call_function ';' {}
           | container_assignment ';' {}
           | container_function ';' {}
           | if_statement {}
           | while_statement {}
           | for_statement {}
           ;

code_block_list : code_block {}
                | code_block_list code_block {}
                ;

types : INT {$$ = INT;}
      | FLOAT {$$ = FLOAT;}
      | CHAR {$$ = CHAR;}
      | STRING {$$ = STRING;}
      | BOOL {$$ = BOOL;}
      ;

var_declaration : VAR types ID {
                if(var_was_declared($3)){
                    printf("Line : %d -> Variabila cu id: %s a fost deja declarata\n",nr_lines,$3); 
                    yyerror("Variabila a fost deja declarata");
                }else{
                    all_variables[indx].type = $2;
                    strcpy(all_variables[indx].id,$3)  ;
                    all_variables[indx].line = nr_lines;
                    indx++;
                }
                }
                | VAR types ID '=' expression 
                {
                if(var_was_declared($3)){
                   printf("Line : %d -> Variabila cu id: %s a fost deja declarata\n",nr_lines,$3); 
                   yyerror("Variabila a fost deja declarata");
                }else{
                    
                    indx_types = 0;
                    get_Ast_types($5);
                    int exp_type = check_Ast_type();

                    if(exp_type != $2) {
                        printf("Assign has another type on line %d \n",nr_lines);
                        yyerror("Incompatible types");
                    }
                    else{
                        int type = $2;
                        all_variables[indx].type = type;
                        strcpy(all_variables[indx].id, $3);
                        all_variables[indx].line = nr_lines;
                        if(type == BOOL) all_variables[indx].val.bool_val = $5->bool_val;
                        if(type == CHAR) all_variables[indx].val.char_val = $5->char_val;
                        if(type == FLOAT) all_variables[indx].val.float_val = $5->float_val;
                        if(type == STRING) {
                            printf("val of string : %s\n",$5->string_val);
                            strcpy(all_variables[indx].val.string_val,$5->string_val);
                        }
                        all_variables[indx].val.int_val = eval_Ast($5);
                        indx++;
                    }
                }
            };

var_assignment : ID '=' expression {
                if(!var_was_declared($1)){
                    printf("Line : %d -> Variabila cu id: %s nu a fost delcarata\n",nr_lines,$1);
                    yyerror("Variabila nu a fost declarata");
                }else{
                    indx_types = 0;
                    get_Ast_types($3);
                    int exp_type = check_Ast_type();
                    int var_type = get_var_type($1);
                    if(exp_type !=var_type) {
                        printf("Expr on line = %d has another types \n",nr_lines);
                        yyerror("Incompatible types");
                    }else{
                        assign_var($1 ,eval_Ast($3));
                    }

                }
                            };

array_declaration : ARR types ID '[' INT_CONST ']' 
                  | ARR types ID '[' INT_CONST ']' '=' '{' array_list '}'
                  ;

array_list : array_list_int {}
           | array_list_float {}
           | array_list_char {}
           | array_list_string {}
           | array_list_bool {}
           ;

array_list_int : array_list_int ',' INT_CONST {}
               | INT_CONST {}
               ;
array_list_float : array_list_float ',' FLOAT_CONST {}
               | FLOAT_CONST {}
               ;
array_list_char : array_list_char ',' CHAR_CONST {}
                | CHAR_CONST{}
                ;
array_list_string : array_list_string ',' STR_CONST{}
                | STR_CONST{}
                ;
array_list_bool : array_list_bool ',' TRUE {}
                | array_list_bool ',' FALSE {}
                | TRUE {}
                | FALSE {}
                ;
array_assignment : array_val '=' expression {}
                 ;
array_val : ID '[' INT_CONST ']' {}
          ;


const_declaration : CONST types ID '=' expression {}
                  ;


function_declaration : FUNCTION return_type ID '(' {if(function_is_defined($3))yyerror("Functia a fost deja declarata!");
                                                else for_fun_dec($2, $3);
                                                strcpy(nume_call, $3);} fun_params ')' '{' main_body '}'
                     | FUNCTION return_type ID '(' ')' '{' main_body '}' {}
                     ;

return_type : types { $$ = $1;}
            | VOID { $$ = VOID;}
            ;
fun_params : parameter {}
           | fun_params ',' parameter {}
           ;
parameter : types ID {fun_args($1, $2);}
          ;

call_function : CALL ID '('  {
                if(!function_is_defined($2))yyerror("Functia nu a fost declarata! Trebuie sa o declarati dupa sa o folositi! Problema este");
                strcpy(nume_call, $2);
                indx_current_param=1;
                 }call_parameters ')'
              | CALL ID '('{function_is_defined($2);strcpy(nume_call, $2);} ')' 
              | CALL eval_function {}
              | CALL type_of 
              ;
call_parameters : call_param {}
                | call_parameters ',' call_param {}
                ;
call_param : call_function {}
           | expression {
            
            param_has_same_type($1, nume_call);
            indx_current_param++;
            }
           ;

eval_function : EVAL '(' expression ')' {
                indx_types = 0;
                get_Ast_types($3);
                int exp_type = check_Ast_type();

                if(exp_type == -1) printf("Expr on line = %d has multiple types \n",nr_lines);
                else{
                    int expr_result = eval_Ast($3);
                    printf("The result of expr : %d, from line :%d \n",expr_result,nr_lines);    
                }
            };
   
type_of : TYPEOF '(' expression ')'{
                indx_types = 0;
                get_Ast_types($3);
                int exp_type = check_Ast_type();
                if(exp_type != -1) {
                    printf("The result of type_of_expr on line = %d is ",nr_lines);
                    if(exp_type == INT){
                        printf("integer\n");
                    }
                    if(exp_type == FLOAT){
                        printf("float\n");
                    }
                    if(exp_type == CHAR){
                        printf("char\n");
                    }
                    if(exp_type == STRING){
                        printf("string\n");
                    }
                    if(exp_type == BOOL){
                        printf("bool\n");
                    }
                }else
                {
                    printf("Expr on line = %d has multiple types \n",nr_lines);
                } 

};


structura_declaration: STRUCTURA '{' structura_body '}' ID ';'{}
                     ;
structura_body: structura_elements{}
              | structura_body structura_elements{}
              ;
structura_elements : var_declaration ';' {}
                   | function_declaration {}
                   ;

container_assignment : get_structura_elem '=' expression{}
                     ;
container_function : get_structura_elem '(' call_parameters ')' {}
    ;
get_structura_elem : ID ACCES ID {}
                   ;


if_statement : IF '(' expression ')' '{' code_block_list '}' %prec THEN {}
             | IF '(' expression ')' '{' code_block_list '}' ELSE '{' code_block_list '}' {}
             ;

while_statement : WHILE '(' expression ')' '{' code_block_list '}' {}
                ;

for_statement : FOR '(' var_assignment ';' expression ';' var_assignment ')' '{' code_block_list '}' {}
              ;

expression: ID {$$ = id_leaf($1);}
          | INT_CONST {$$ = constant_leaf(INT_CONST,&$1);}
          | FLOAT_CONST{$$ = constant_leaf(FLOAT_CONST,&$1);}
          | CHAR_CONST {$$ = constant_leaf(CHAR_CONST ,&$1);}
          | STR_CONST {$$ = constant_leaf(STR_CONST,&$1);}
          | TRUE {$$ = constant_leaf(TRUE,&$1);}
          | FALSE {$$ = constant_leaf(FALSE,&$1);}
          | array_val {$$ = array_leaf();}   

          | call_function {$$ = func_leaf();}
          | '(' expression ')' {$$ = $2;}
          | expression '+' expression {
                $$= build_Ast($1,$3,0,"+");
          }
          | expression '-' expression {
                $$ = build_Ast( $1, $3, 0, "-");
          }
          | expression '*' expression {
                $$ = build_Ast( $1, $3, 0, "*");
          }
          | expression '/' expression {
                $$ = build_Ast( $1, $3, 0, "/");
          }
          | expression '%' expression {
                $$ = build_Ast( $1, $3, 0, "%");
          }
          | '-' expression %prec NEG {
          } 
          | expression LT expression {
                $$ = build_Ast( $1, $3, 0, "<");
          }
          | expression GT expression {
                $$ = build_Ast( $1, $3, 0, ">");
          }
          | expression LTE expression {
                $$ = build_Ast( $1, $3, 0, "<=");
          }
          | expression GTE expression {
                $$ = build_Ast( $1, $3, 0, ">=");
          }
          | expression EQUALITY expression {
                $$ = build_Ast( $1, $3, 0, "==");
          }
          | expression INEQUALITY expression{
                $$ = build_Ast( $1, $3, 0, "!=");
          }
          | expression AND expression {
                $$ = build_Ast( $1, $3, 0, "&&");
          }
          | expression OR expression {
                $$ = build_Ast( $1, $3, 0, "||");
          }
          | '!' expression {}
          ;
%%
int check = 1;
struct AstNode* array_leaf(){
    struct AstNode *var;
    if ((var = (struct AstNode*)malloc(sizeof(struct AstNode))) == NULL)
        yyerror("out of memory");

    var->node_type = 3 ;
    var->left= NULL;
    var->right= NULL;
    var->int_val = 0 ;
    return var;
}
struct AstNode* func_leaf(){
    struct AstNode *var;
    if ((var = (struct AstNode*)malloc(sizeof(struct AstNode))) == NULL)
        yyerror("out of memory");

    var->node_type = 3 ;
    var->left= NULL;
    var->right= NULL;
    var->int_val = 0 ;
    return var;
}
int var_was_declared(char* id){
       for(int i = 0; i<indx ; i++){
        if(!strcmp(all_variables[i].id,id)){
            return 1;
        }
    }
    return 0;
}
void assign_var(char* id ,int val){
    for(int i = 0; i<indx ; i++){
        if(!strcmp(all_variables[i].id,id)){
            all_variables[i].val.int_val = val;
            break;
        }
    }
}

void printAll(){
     for(int i = 0 ; i< indx ; i++){
          printf("%d,%s,%d\n",all_variables[i].type,all_variables[i].id,all_variables[i].val.int_val);         
     }
}
/* 
void var_dec(int tip, char* id)
{
     all_variables[indx].t.mainType = tip;
     strcpy(all_variables[indx].id,id)  ;
     all_variables[indx].t.isConst = 0;
     all_variables[indx].t.isArray = 0;
     all_variables[indx]. line = nr_lines;
     indx++;
     
 
} */
struct AstNode *id_leaf(char* i)
{
     struct AstNode* var;
    
    if ((var = (struct AstNode*)malloc(sizeof(struct Variabila))) == NULL)
        yyerror("out of memory");
    /* copiere valoare indice */
    
    strcpy(var->id , i);
    var->node_type = 1;
    var->left= NULL;
    var->right= NULL;
    return var;
}



struct AstNode* constant_leaf(int type, void* value)
{
    struct AstNode *var;
    if ((var = (struct AstNode*)malloc(sizeof(struct AstNode))) == NULL)
        yyerror("out of memory");

    //2-constant
    var->node_type = 2 ;
    var->left= NULL;
    var->right= NULL;

    if (type == INT_CONST){
        var->type = INT;
        var->int_val = *((int*)value);
    }
    if (type == TRUE||type == FALSE){
        var->type = BOOL;
        var->bool_val = *((short*)value);
    }
    if (type == CHAR_CONST){
        var->type = CHAR;
        var->char_val = *((char*)value);
    }
    if (type == FLOAT_CONST){
        var->type = FLOAT;
        var->float_val = *((float*)value);
    }
    if (type == STR_CONST){
        var->type = STRING;
        strcpy(var->string_val ,*((char**)value));
    }

    return var;
}

void free_expre(struct AstNode *var){
     free(var);
}

void insert_table_symbol(){
    char line[10000];
    fclose(fopen("symbol_var_table.txt", "w"));// clean
    FILE* f = fopen("symbol_var_table.txt", "a");
    fprintf(f, "Programul tau contine urnmatoarele varibile:\n");

    for(int i = 0; i < indx; i++)
    {
        int type = all_variables[i].type;
    if (type == INT_CONST||type ==INT){
        fprintf(f, "%d) Nume : %s    Tip : %d  Value: %d  Linie: %d\n" , i, all_variables[i].id, all_variables[i].type,all_variables[i].val.int_val, all_variables[i].line);    }
    if (type == TRUE||type == FALSE||type == BOOL){
        fprintf(f, "%d) Nume : %s    Tip : %d  Value: %d  Linie: %d\n" , i, all_variables[i].id, all_variables[i].type,all_variables[i].val.bool_val, all_variables[i].line);
    }
    if (type == CHAR_CONST||type == CHAR){
        fprintf(f, "%d) Nume : %s    Tip : %d  Value: %c  Linie: %d\n" , i, all_variables[i].id, all_variables[i].type,all_variables[i].val.char_val, all_variables[i].line);
    }
    if (type == FLOAT_CONST||type ==FLOAT){
        fprintf(f, "%d) Nume : %s    Tip : %d  Value: %f  Linie: %d\n" , i, all_variables[i].id, all_variables[i].type,all_variables[i].val.float_val, all_variables[i].line);
    }
    if (type == STR_CONST||type ==STRING){
        fprintf(f, "%d) Nume : %s    Tip : %d  Value: %s Linie: %d\n" , i, all_variables[i].id, all_variables[i].type,all_variables[i].val.string_val, all_variables[i].line);
    }
        
    }       
    fclose(f);
}

void insert_table_func(){

    fclose(fopen("symbol_function_table.txt", "w"));// clean
    FILE* f = fopen("symbol_function_table.txt", "a");
    for(int i = 1; i <= indx_f; i++)
    {
        if(all_functions[i].ret_tip == 0)
            fprintf(f, "%d) Nume functie: %s    Tip Returnare: int   Linie: %d\n", i, all_functions[i].nume, all_functions[i].linie);
        else if(all_functions[i].ret_tip == 1)
            fprintf(f, "%d) Nume functie: %s    Tip Returnare: float   Linie: %d\n", i, all_functions[i].nume, all_functions[i].linie);
        else if(all_functions[i].ret_tip == 2)
            fprintf(f, "%d) Nume functie: %s    Tip Returnare: char   Linie: %d\n", i, all_functions[i].nume, all_functions[i].linie);
        else if(all_functions[i].ret_tip == 3)
            fprintf(f, "%d) Nume functie: %s    Tip Returnare: string   Linie: %d\n", i, all_functions[i].nume, all_functions[i].linie);
        else if(all_functions[i].ret_tip == 4)
            fprintf(f, "%d) Nume functie: %s    Tip Returnare: bool   Linie: %d\n", i, all_functions[i].nume, all_functions[i].linie);

        
        fprintf(f, "    Functia are urmatorii parametri:\n");
        for(int j = 1; j <= all_functions[i].nr_param; j++)
            if(all_functions[i].p[j].mainType == INT)
                fprintf(f, "        Parametrul: %d    Tip: int    Nume:  %s\n", j, all_functions[i].p[j].nume_par);
            else if(all_functions[i].p[j].mainType == FLOAT)
                fprintf(f, "        Parametrul: %d    Tip: float    Nume:  %s\n", j, all_functions[i].p[j].nume_par);
            else if(all_functions[i].p[j].mainType == CHAR)
                fprintf(f, "        Parametrul: %d    Tip: char    Nume:  %s\n", j, all_functions[i].p[j].nume_par);
            else if(all_functions[i].p[j].mainType == STRING)
                fprintf(f, "        Parametrul: %d    Tip: string    Nume:  %s\n", j, all_functions[i].p[j].nume_par);
            else if(all_functions[i].p[j].mainType == BOOL)
                fprintf(f, "        Parametrul: %d    Tip: bool    Nume:  %s\n", j, all_functions[i].p[j].nume_par);

        fprintf(f, "\n");
    }
    fclose(f);
}

void for_fun_dec(int tip, char id[])
{
        indx_f++;

        all_functions[indx_f].nr_param = 0;
        if(tip == INT)
            all_functions[indx_f].ret_tip = 0;
        else if (tip == FLOAT)
            all_functions[indx_f].ret_tip = 1;
        else if (tip == CHAR)
            all_functions[indx_f].ret_tip = 2;
        else if (tip == STRING)
            all_functions[indx_f].ret_tip = 3;
        else if (tip == BOOL)
            all_functions[indx_f].ret_tip = 4;

        strcpy(all_functions[indx_f].nume, id); 

        all_functions[indx_f].linie = nr_lines;
     
    }

    void fun_args(int tip, char id[])
    {
        all_functions[indx_f].nr_param++;
        if(tip == INT)
            all_functions[indx_f].p[all_functions[indx_f].nr_param].mainType = INT;
        else if (tip == FLOAT)
            all_functions[indx_f].p[all_functions[indx_f].nr_param].mainType = FLOAT;
        else if (tip == CHAR)
            all_functions[indx_f].p[all_functions[indx_f].nr_param].mainType = CHAR;
        else if (tip == STRING)
            all_functions[indx_f].p[all_functions[indx_f].nr_param].mainType = STRING;
        else if (tip == BOOL)
            all_functions[indx_f].p[all_functions[indx_f].nr_param].mainType = BOOL;

        strcpy(all_functions[indx_f].p[all_functions[indx_f].nr_param].nume_par, id);

        all_variables[indx].type = tip;
        strcpy(all_variables[indx].id,id)  ;
        all_variables[indx].line = nr_lines;
        indx++;
    }

    int function_is_defined(char* id)
    {
        int exista = 0;
        for(int i=1; i <= indx_f; i++)
            if(strcmp(id, all_functions[i].nume) == 0)
                exista = 1;
        return exista;
    }
struct AstNode* build_Ast(struct AstNode* left,struct AstNode* right, int op , char* op_name){
    struct AstNode *var;
    if ((var = (struct AstNode*)malloc(sizeof(struct AstNode))) == NULL)
        yyerror("out of memory");

    var->node_type = op ;
    strcpy(var->operation,op_name);
    var->left = left ;    
    var->right = right ;
    return var;
}
int eval_Ast(struct AstNode* node){

    if(node->node_type == 1){//id
        //TODO : sortare type only int , other = 0;
        return get_var_value(node->id);
    }

    if(node->node_type == 2){
        return node->int_val;
    }
    if(node->node_type == 3){
        return node->int_val;
    }

    if(!strcmp(node->operation ,"+")){
        return eval_Ast(node->left) + eval_Ast(node->right);
    }
    if(!strcmp(node->operation ,"-")){
        return eval_Ast(node->left) - eval_Ast(node->right);
    }
    if(!strcmp(node->operation, "*")){
        return eval_Ast(node->left) * eval_Ast(node->right);
    }
    if(!strcmp(node->operation, "/")){
        return eval_Ast(node->left) / eval_Ast(node->right);
    }
    if(!strcmp(node->operation, "%")){
        return  eval_Ast(node->left) % eval_Ast(node->right);
    }
    if(!strcmp(node->operation, ">")){
        return  eval_Ast(node->left) > eval_Ast(node->right);
    }
    if(!strcmp(node->operation, "<")){
        return  eval_Ast(node->left) < eval_Ast(node->right);
    }
    if(!strcmp(node->operation, ">=")){
        return  eval_Ast(node->left) >= eval_Ast(node->right);
    }
    if(!strcmp(node->operation, "<=")){
        return  eval_Ast(node->left) <= eval_Ast(node->right);
    }
    if(!strcmp(node->operation, "==")){
        return  eval_Ast(node->left) == eval_Ast(node->right);
    }
    if(!strcmp(node->operation, "&&")){
        return  eval_Ast(node->left) && eval_Ast(node->right);
    }
    if(!strcmp(node->operation, "||")){
        return  eval_Ast(node->left) || eval_Ast(node->right);
    }
}

int get_var_value(char* id){
    for(int i = 0 ; i<indx; i++){
        if(!strcmp(all_variables[i].id,id)){
            return all_variables[i].val.int_val;
        }
    }
}
int get_var_type(char* id){
    for(int i = 0 ; i<indx; i++){
        if(!strcmp(all_variables[i].id,id)){
            return all_variables[i].type;
        }
    }
}
void get_Ast_types(struct AstNode* node){
    if(node->node_type == 1){
        ast_types[indx_types++] = get_var_type(node->id); 
    }
    if(node->node_type == 2){
        ast_types[indx_types++] = node->type ;
    }
    if(node->node_type == 0){
        get_Ast_types(node->left);
        get_Ast_types(node->right);
    }

}
int check_Ast_type(){
    int first_type = ast_types[0];
    for(int i = 1; i<indx_types ; i++){
        if(ast_types[i]!=first_type){
            return -1 ;
        }
    }
    return first_type;
}

int param_has_same_type(struct AstNode* node, char* id)
{
    indx_types = 0;
    get_Ast_types(node);
    int exp_type = check_Ast_type();
    for(int i = 1; i <= indx_f; i++)
        if(!strcmp(all_functions[i].nume, id))
        { 
            if(all_functions[i].p[indx_current_param].mainType == exp_type){
                return 1 ;
            } else yyerror(" paramaters had another type ",nr_lines);    
        }
    return 0;
}

int yyerror(const char *s)
{
    printf("%s la linia %d \n", s, nr_lines);
    check = 0;
}

int main(int argc, char **argv)
{ 
     
    if (argc > 0)
        yyin = fopen(argv[1], "r");
    yyparse();

    if (check == 1)
    {
        printf("Programul este corect sintactic, felicitari!\n\n");
    }
    else printf("Programul nu este corect sintactic\n\n");
    insert_table_symbol();
    insert_table_func();
}
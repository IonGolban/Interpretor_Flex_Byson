typedef struct 
{
    int mainType;
    union
    {
        int isConst;
        int isArray;
    };
    
} Type;

typedef struct
{
    union
    {
        short bool_val : 1;
        int int_val;
        float float_val;
        char char_val;
        char string_val[100];
    }; 
} Constant_val;

typedef struct 
{
    union 
    {
        int* arrInt;
        char* arrChar;
        char** arrStr;
        short* arrBool;
        float* arrFloat;
    };
    
} Array_type;

typedef struct 
{
    int int_val;
    float float_val;
    char char_val;
    char string_val[100];
    short bool_val : 1;

} Val;

struct Variabila
{
    char id[100];
    char scope[100];
    int type;
    Val val;
    Array_type arr; 
    Constant_val con;
    int line;
} all_variables[100]; 

struct AstNode
{
    int node_type;
    struct AstNode *left, *right;
    // 0 - operatie, 1 - identificator, 2 - numar (constanta), 3 - altceva
    char id[100];
    int type;
    int int_val;
    float float_val;
    char char_val;
    char string_val[100];
    short bool_val : 1;
    //if operation :
    char operation[8] ;
};

typedef struct
{
    int mainType;
    char nume_par[100];

} Parametri;

struct Functie
{
    int ret_tip; 
    int linie, index_f;
    char nume[100];
    int nr_param;
    Parametri p[1000];

} all_functions[1000];
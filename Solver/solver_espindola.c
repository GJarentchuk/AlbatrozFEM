#include <stdio.h>
#include <stdlib.h>
#include <math.h>

double *solve_lin(double **a , int neq, FILE *debug){ //It was a[1400][1401]
    int    i, j, k, l;
    int    nmais, last, rev;
    double  big, term, temp, pivot, nextr, cnt, y;
    double x[2000];
    double eps = 1.0E-30;

    nmais = neq +1;
    last = neq - 1;

    for (i = 0; i < last; i++)
    {
        big = 0.f;
        for (k = i; k < neq; k++)
        {
            term = fabs(a[k][i]);
            if ((term - big) > 0.f)
            {
                big = term;
                l = k;
            }
        }
        if (fabs(big) <= eps)
        {
            printf("\nMatriz singular. Sistema sem solucao unica.\n");
            return 0;
        }
        if (i != l)
        {
            for (j = 0; j < nmais; j++)
            {
                temp = a[i][j];
                a[i][j] = a[l][j];
                a[l][j] = temp;
            }
        }
        pivot = a[i][i];
        nextr = i + 1;
        for (j = nextr; j < neq; j++)
        {
            cnt = a[j][i] / pivot;
            for (k = i; k < nmais; k++)
            {
                a[j][k] = a[j][k] - cnt*a[i][k];
            }
        }
    }
    for (i = 0; i< neq; i++)
    {
        if (fabs(a[i][i]) <= eps)
        {
            printf("\nMatriz singular. Sistema sem solucao unica.\n");
            exit(1);
        }
    }
    for (i = 0; i < neq; i++)
    {
        rev = neq -1 - i;
        y = a[rev][neq];
        if (rev != neq)
        {
            for (j = 0; j < i; j++)
            {
                k = neq -1- j;
                y = y - a[rev][k]*x[k];
            }
        }
        x[rev] = y / a[rev][rev];
    }
    for( i = 0; i < neq; i++ ){
        printf( "%e\n", x[i] );
        fprintf( debug, "%e %d\n", x[i], i );
        fflush( debug );
    }
    l=1; // reciclagem de variaveis, l é apenas um contador
    k=1; // reciclagem de variaveis, k é apenas um contador
//    printf("\nSolucao\n");
//    printf("no %d\n",k);
//    for (i = 0; i < neq; i++)
//    {
//        printf("   x( %d ) = %g\n", l, x[i]);
//        l= l+1;
//        if (i!=0 && (i+1)%6==0 && i!=(neq-1))
//        {
//            k = k+1;
//            printf("\n\nno %d\n",k);
//            l=1;
//        }
//    }
//    printf("\nPrograma terminado. Tecle algo para encerrar.\n\n");
    fclose( debug );
    return x;
//    system("pause");
}

int main(){
    //Debug file
    FILE *debug;
    //Read matrix from Parametric
    int neq, i, j;
    double **a;
    //double a[1400][1401];
    double *x;
    debug = fopen ("solver_debug.txt","w");
    a = ( double ** )malloc( 2000*sizeof(double*) );
    for( j = 0; j < 2000; j++ ) a[j]=(double*)malloc(2001*sizeof(double));
//    printf( "oi %d\n", neq );
    scanf( "%d", &neq );
    for( i = 0; i < neq; i++ ){
        for( j = 0; j <= neq; j++ ){
//            fprintf( debug, "%d\t%d\n", i, j );
//            fflush( debug );
            scanf( "%lf", &a[i][j] );
        }
    }
    x = solve_lin(a, neq, debug);
    //Not working due to unknown circunstances (printing garbage after some point). Printing part move to solve_lin function
//    if( x == 0 ){
//        printf( "\nMatriz singular. Sistema sem solucao unica.\n" );
//    }else{
//        for( i = 0; i < neq; i++ ){
//            printf( "%e\n", x[i] );
//            fprintf( debug, "%e\n", x[i] );
//        }
//    }
    //fclose( debug );
//    system( "pause" );
    return 0;
}
